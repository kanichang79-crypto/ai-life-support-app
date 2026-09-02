import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/chat_message.dart';
import '../services/ai_chat_service.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';

/// 現在の会話画面の状態。
enum _ConversationState { idle, recording, processing }

/// 音声入力→AIとの会話→音声出力ができる会話画面。
///
/// マイクボタンをタップして話しかけると、
/// 1. Speech-to-Text APIで発話をテキストに変換し
/// 2. そのテキストをAI(Gemini API)に送って返答を生成し
/// 3. 返答をText-to-Speech APIで音声にして再生する
/// という一連の流れを行い、やり取りをチャット形式で画面に表示する。
///
/// キャラクターは固定の1キャラクター([AiChatService] 側で設定)。
class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];

  StreamSubscription<Uint8List>? _recordingSub;
  BytesBuilder? _recordingBuffer;
  Completer<void>? _recordingDone;

  _ConversationState _state = _ConversationState.idle;
  String? _errorMessage;

  @override
  void dispose() {
    _recordingSub?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onMicButtonPressed() async {
    switch (_state) {
      case _ConversationState.idle:
        await _startRecording();
      case _ConversationState.recording:
        await _stopRecordingAndRespond();
      case _ConversationState.processing:
        break;
    }
  }

  Future<void> _startRecording() async {
    setState(() => _errorMessage = null);
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!mounted) return;
      if (!hasPermission) {
        setState(() => _errorMessage = 'マイクの使用が許可されていません。端末の設定を確認してください。');
        return;
      }

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: SttService.sampleRateHertz,
          numChannels: 1,
        ),
      );
      if (!mounted) return;

      final buffer = BytesBuilder();
      final doneCompleter = Completer<void>();
      _recordingBuffer = buffer;
      _recordingDone = doneCompleter;
      _recordingSub = stream.listen(
        buffer.add,
        onDone: () {
          if (!doneCompleter.isCompleted) doneCompleter.complete();
        },
        onError: (_) {
          if (!doneCompleter.isCompleted) doneCompleter.complete();
        },
      );

      setState(() => _state = _ConversationState.recording);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '録音を開始できませんでした: $e');
    }
  }

  Future<void> _stopRecordingAndRespond() async {
    setState(() => _state = _ConversationState.processing);

    try {
      await _recorder.stop();
      await _recordingDone?.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
      await _recordingSub?.cancel();
      final audioBytes = _recordingBuffer?.toBytes() ?? Uint8List(0);
      _recordingSub = null;
      _recordingBuffer = null;
      _recordingDone = null;

      final sttStopwatch = Stopwatch()..start();
      final transcript = await SttService.instance.transcribe(audioBytes);
      debugPrint('[VoiceChat] Speech-to-Text: ${sttStopwatch.elapsedMilliseconds}ms');
      if (!mounted) return;
      setState(() => _messages.add(ChatMessage(role: ChatRole.user, text: transcript)));
      _scrollToBottom();

      final aiStopwatch = Stopwatch()..start();
      final reply = await AiChatService.instance.reply(_messages);
      debugPrint('[VoiceChat] AI応答生成: ${aiStopwatch.elapsedMilliseconds}ms');
      if (!mounted) return;
      // テキストは先に画面へ表示し、体感速度を優先する。
      // 音声合成・再生はブロックせずバックグラウンドで行う([_speak]参照)。
      setState(() => _messages.add(ChatMessage(role: ChatRole.assistant, text: reply)));
      _scrollToBottom();
      unawaited(_speak(reply));
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _state = _ConversationState.idle);
    }
  }

  /// AIの返答[text]を音声合成して再生する。
  ///
  /// テキスト表示を待たせないよう、呼び出し元では await せずバックグラウンドで
  /// 実行する想定。ここで発生したエラーは会話フロー自体は止めず、
  /// エラーメッセージの表示のみ行う。
  Future<void> _speak(String text) async {
    try {
      final ttsStopwatch = Stopwatch()..start();
      final audio = await TtsService.instance.synthesize(text);
      debugPrint('[VoiceChat] Text-to-Speech: ${ttsStopwatch.elapsedMilliseconds}ms');
      if (!mounted) return;
      await _audioPlayer.play(BytesSource(audio));
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final missingKeys = [
      if (!TtsService.instance.isConfigured) 'GOOGLE_TTS_API_KEY(音声認識・音声合成用)',
      if (!AiChatService.instance.isConfigured) 'GOOGLE_GEMINI_API_KEY(AI応答生成用)',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('AI会話')),
      body: Column(
        children: [
          if (missingKeys.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '次のAPIキーが設定されていません。\n'
                '--dart-define=<キー名>=<値> を指定してビルド/実行してください。\n'
                '${missingKeys.join('\n')}',
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        '下のマイクボタンをタップして話しかけてみましょう。',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        _ChatBubble(message: _messages[index]),
                  ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _MicButton(
                  state: _state,
                  onPressed: _onMicButtonPressed,
                ),
                const SizedBox(height: 12),
                Text(_statusLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _statusLabel => switch (_state) {
        _ConversationState.idle => 'タップして話しかける',
        _ConversationState.recording => '聞いています... (タップで終了)',
        _ConversationState.processing => '考えています...',
      };
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.state, required this.onPressed});

  final _ConversationState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRecording = state == _ConversationState.recording;
    final isProcessing = state == _ConversationState.processing;

    return SizedBox(
      width: 80,
      height: 80,
      child: FloatingActionButton(
        backgroundColor: isRecording ? colorScheme.error : colorScheme.primary,
        onPressed: isProcessing ? null : onPressed,
        child: isProcessing
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(isRecording ? Icons.stop : Icons.mic, size: 32),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? colorScheme.primaryContainer : colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message.text),
      ),
    );
  }
}
