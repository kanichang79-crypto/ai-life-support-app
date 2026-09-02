import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Google Cloud Text-to-Speech API を使って日本語テキストを音声化するサービス。
///
/// APIキーはソースコードに埋め込まず、ビルド時に
/// `--dart-define=GOOGLE_TTS_API_KEY=...` として渡された値を
/// [String.fromEnvironment] で読み込む。
class TtsService {
  TtsService._internal();

  static final TtsService instance = TtsService._internal();

  static const String _apiKey = String.fromEnvironment('GOOGLE_TTS_API_KEY');

  static const String _endpoint =
      'https://texttospeech.googleapis.com/v1/text:synthesize';

  /// 既定の日本語 Neural2 ボイス。
  static const String defaultVoiceName = 'ja-JP-Neural2-B';

  /// APIキーがビルド時に設定されているかどうか。
  bool get isConfigured => _apiKey.isNotEmpty;

  /// [text] を音声合成し、MP3の音声データ(バイト列)を返す。
  ///
  /// APIキーが未設定の場合は [TtsConfigException]、
  /// APIからのエラー応答時は [TtsApiException] を投げる。
  Future<Uint8List> synthesize(
    String text, {
    String voiceName = defaultVoiceName,
    String languageCode = 'ja-JP',
  }) async {
    if (!isConfigured) {
      throw TtsConfigException(
        'GOOGLE_TTS_API_KEY が設定されていません。'
        '--dart-define=GOOGLE_TTS_API_KEY=<APIキー> を指定してビルド/実行してください。',
      );
    }

    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_endpoint?key=$_apiKey'),
        headers: const {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'input': {'text': text},
          'voice': {
            'languageCode': languageCode,
            'name': voiceName,
          },
          'audioConfig': {'audioEncoding': 'MP3'},
        }),
      );
    } catch (e) {
      throw TtsApiException('Text-to-Speech APIへの接続に失敗しました: $e');
    }

    if (response.statusCode != 200) {
      throw TtsApiException(
        'Text-to-Speech APIの呼び出しに失敗しました '
        '(status: ${response.statusCode}): ${response.body}',
      );
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final audioContent = decoded['audioContent'] as String?;
    if (audioContent == null) {
      throw TtsApiException('レスポンスに音声データ(audioContent)が含まれていません。');
    }

    return base64Decode(audioContent);
  }
}

/// APIキー未設定など、設定不備によるエラー。
class TtsConfigException implements Exception {
  TtsConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Google Cloud Text-to-Speech APIからのエラー応答、または通信エラー。
class TtsApiException implements Exception {
  TtsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
