import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../services/tts_service.dart';

/// 生活サポートAI機能の動作確認用画面。
///
/// テキストを入力して「読み上げる」ボタンを押すと、Google Cloud Text-to-Speech
/// (Neural2ボイス)で日本語音声に変換して再生する。
class AiSupportScreen extends StatefulWidget {
  const AiSupportScreen({super.key});

  @override
  State<AiSupportScreen> createState() => _AiSupportScreenState();
}

class _AiSupportScreenState extends State<AiSupportScreen> {
  final _textController =
      TextEditingController(text: 'こんにちは。今日も一日頑張りましょう。');
  final _audioPlayer = AudioPlayer();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _textController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _speak() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final audioBytes = await TtsService.instance.synthesize(text);
      await _audioPlayer.play(BytesSource(audioBytes));
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = TtsService.instance.isConfigured;

    return Scaffold(
      appBar: AppBar(title: const Text('生活サポートAI(音声読み上げ確認)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isConfigured)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'GOOGLE_TTS_API_KEY が設定されていません。\n'
                  'ビルド/実行時に --dart-define=GOOGLE_TTS_API_KEY=<APIキー> を'
                  '指定してください。',
                ),
              ),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '読み上げるテキスト',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isLoading ? null : _speak,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.volume_up),
              label: Text(_isLoading ? '生成中...' : '読み上げる'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
