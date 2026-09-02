/// 会話の発話者。
enum ChatRole { user, assistant }

/// AI会話画面での1つの発話(ユーザーの発言またはAIの返答)。
class ChatMessage {
  const ChatMessage({required this.role, required this.text});

  final ChatRole role;
  final String text;
}
