import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Google Cloud Speech-to-Text API を使って録音した音声を日本語テキストに
/// 変換するサービス。
///
/// [TtsService] と同じAPIキーを使う(同一プロジェクトでSpeech-to-Text API を
/// 有効化していることが前提)。ビルド時に
/// `--dart-define=GOOGLE_TTS_API_KEY=...` として渡された値を
/// [String.fromEnvironment] で読み込む。
class SttService {
  SttService._internal();

  static final SttService instance = SttService._internal();

  static const String _apiKey = String.fromEnvironment('GOOGLE_TTS_API_KEY');

  static const String _endpoint =
      'https://speech.googleapis.com/v1/speech:recognize';

  /// 録音時に使用するサンプリングレート(Hz)。[synthesize] を呼ぶ側の
  /// 録音設定(RecordConfig)もこの値に合わせる必要がある。
  static const int sampleRateHertz = 16000;

  /// APIキーがビルド時に設定されているかどうか。
  bool get isConfigured => _apiKey.isNotEmpty;

  /// ヘッダなしの16bit PCM(リトルエンディアン、モノラル、
  /// [sampleRateHertz] Hz)である [pcm16Bytes] を音声認識し、
  /// 認識結果のテキストを返す。
  ///
  /// APIキー未設定の場合は [SttConfigException]、
  /// 音声が認識できなかった場合は [SttNoSpeechException]、
  /// APIからのエラー応答時は [SttApiException] を投げる。
  Future<String> transcribe(
    Uint8List pcm16Bytes, {
    String languageCode = 'ja-JP',
  }) async {
    if (!isConfigured) {
      throw SttConfigException(
        'GOOGLE_TTS_API_KEY が設定されていません。'
        '--dart-define=GOOGLE_TTS_API_KEY=<APIキー> を指定してビルド/実行してください。',
      );
    }
    if (pcm16Bytes.isEmpty) {
      throw SttNoSpeechException('録音データがありません。もう一度お試しください。');
    }

    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_endpoint?key=$_apiKey'),
        headers: const {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'config': {
            'encoding': 'LINEAR16',
            'sampleRateHertz': sampleRateHertz,
            'languageCode': languageCode,
            'audioChannelCount': 1,
            'enableAutomaticPunctuation': true,
          },
          'audio': {'content': base64Encode(pcm16Bytes)},
        }),
      );
    } catch (e) {
      throw SttApiException('Speech-to-Text APIへの接続に失敗しました: $e');
    }

    if (response.statusCode != 200) {
      throw SttApiException(
        'Speech-to-Text APIの呼び出しに失敗しました '
        '(status: ${response.statusCode}): ${response.body}',
      );
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final results = decoded['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      throw SttNoSpeechException('音声を認識できませんでした。もう一度お試しください。');
    }

    final transcript = results
        .map((result) {
          final alternatives =
              (result as Map<String, dynamic>)['alternatives'] as List<dynamic>?;
          if (alternatives == null || alternatives.isEmpty) return '';
          return (alternatives.first as Map<String, dynamic>)['transcript']
                  as String? ??
              '';
        })
        .join()
        .trim();

    if (transcript.isEmpty) {
      throw SttNoSpeechException('音声を認識できませんでした。もう一度お試しください。');
    }

    return transcript;
  }
}

/// APIキー未設定など、設定不備によるエラー。
class SttConfigException implements Exception {
  SttConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 音声が認識できなかった(無音・不明瞭など)場合のエラー。
class SttNoSpeechException implements Exception {
  SttNoSpeechException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Google Cloud Speech-to-Text APIからのエラー応答、または通信エラー。
class SttApiException implements Exception {
  SttApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
