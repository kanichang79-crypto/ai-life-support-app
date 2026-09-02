import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';

/// Google Gemini API (Generative Language API) を使って、固定キャラクターとの
/// 会話の返答テキストを生成するサービス。
///
/// 同じGoogle CloudプロジェクトでGenerative Language APIを有効化していれば、
/// [TtsService]/[SttService] と同じAPIキーを使うこともできる。ビルド時に
/// `--dart-define=GOOGLE_GEMINI_API_KEY=...` として渡された値を
/// [String.fromEnvironment] で読み込む。
class AiChatService {
  AiChatService._internal();

  static final AiChatService instance = AiChatService._internal();

  static const String _apiKey =
      String.fromEnvironment('GOOGLE_GEMINI_API_KEY');

  static const String _model = 'gemini-3.6-flash';

  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  /// 固定キャラクターの人格設定。キャラクターのカスタマイズ機能が実装されるまでは
  /// この内容で固定する。
  static const String _systemInstruction =
      'あなたは「ミライ」という名前の、ユーザーの日常生活をサポートする明るく親しみやすいAIアシスタントです。'
      '丁寧すぎない、親しみやすい話し言葉の日本語で応答してください。'
      '回答は必ず2〜3文以内の簡潔な文章にまとめてください。前置きや繰り返しは避け、'
      '結論から端的に話し、難しい専門用語は避けてください。'
      'ユーザーの体調や気分を気遣いながら、雑談やちょっとした相談にも気さくに応じてください。';

  /// APIキーがビルド時に設定されているかどうか。
  bool get isConfigured => _apiKey.isNotEmpty;

  /// [conversation] (これまでの会話履歴。最後の要素が直近のユーザー発言)をもとに、
  /// AIキャラクターの返答テキストを生成して返す。
  ///
  /// APIキー未設定の場合は [AiChatConfigException]、
  /// APIからのエラー応答時や返答が得られない場合は [AiChatApiException] を投げる。
  Future<String> reply(List<ChatMessage> conversation) async {
    if (!isConfigured) {
      throw AiChatConfigException(
        'GOOGLE_GEMINI_API_KEY が設定されていません。'
        '--dart-define=GOOGLE_GEMINI_API_KEY=<APIキー> を指定してビルド/実行してください。',
      );
    }

    final contents = conversation
        .map((message) => {
              'role': message.role == ChatRole.user ? 'user' : 'model',
              'parts': [
                {'text': message.text},
              ],
            })
        .toList();

    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_endpoint?key=$_apiKey'),
        headers: const {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'systemInstruction': {
            'parts': [
              {'text': _systemInstruction},
            ],
          },
          'contents': contents,
          'generationConfig': {
            'temperature': 0.9,
            'maxOutputTokens': 300,
          },
        }),
      );
    } catch (e) {
      throw AiChatApiException('AI応答生成APIへの接続に失敗しました: $e');
    }

    if (response.statusCode != 200) {
      throw AiChatApiException(
        'AI応答生成APIの呼び出しに失敗しました '
        '(status: ${response.statusCode}): ${response.body}',
      );
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw AiChatApiException('AIから応答が得られませんでした。');
    }

    final content =
        (candidates.first as Map<String, dynamic>)['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts
            ?.map((part) => (part as Map<String, dynamic>)['text'] as String? ?? '')
            .join()
            .trim() ??
        '';

    if (text.isEmpty) {
      throw AiChatApiException('AIから空の応答が返されました。');
    }

    return text;
  }
}

/// APIキー未設定など、設定不備によるエラー。
class AiChatConfigException implements Exception {
  AiChatConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Gemini APIからのエラー応答、または通信エラー。
class AiChatApiException implements Exception {
  AiChatApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
