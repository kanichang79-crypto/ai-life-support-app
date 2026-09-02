import 'package:flutter/material.dart';

import '../models/ai_character.dart';
import '../repositories/ai_character_repository.dart';

/// AIキャラクターの名前・口調・性格・見た目をカスタマイズする画面。
///
/// 保存すると [AiCharacterRepository] 経由で端末に保存され、
/// 保存済みの [AiCharacter] を [Navigator.pop] の結果として呼び出し元へ返す。
class AiCharacterSettingsScreen extends StatefulWidget {
  const AiCharacterSettingsScreen({super.key, required this.character});

  final AiCharacter character;

  @override
  State<AiCharacterSettingsScreen> createState() =>
      _AiCharacterSettingsScreenState();
}

class _AiCharacterSettingsScreenState
    extends State<AiCharacterSettingsScreen> {
  final _repository = AiCharacterRepository();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  late ToneStyle _tone;
  late double _kindness;
  late double _energy;
  late String _avatarEmoji;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.character.name);
    _tone = widget.character.tone;
    _kindness = widget.character.kindness;
    _energy = widget.character.energy;
    _avatarEmoji = widget.character.avatarEmoji;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final character = AiCharacter(
      name: _nameController.text.trim(),
      tone: _tone,
      kindness: _kindness,
      energy: _energy,
      avatarEmoji: _avatarEmoji,
    );
    await _repository.save(character);
    if (!mounted) return;
    Navigator.of(context).pop(character);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AIキャラクター設定')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Text(
                _avatarEmoji,
                style: const TextStyle(fontSize: 64),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('名前'),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: '例:ミライ',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '名前を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const _SectionLabel('口調'),
            SegmentedButton<ToneStyle>(
              segments: ToneStyle.values
                  .map(
                    (tone) => ButtonSegment(
                      value: tone,
                      label: Text(tone.label),
                    ),
                  )
                  .toList(),
              selected: {_tone},
              onSelectionChanged: (selected) =>
                  setState(() => _tone = selected.first),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('性格'),
            _PersonalitySlider(
              leftLabel: '厳しい',
              rightLabel: '優しい',
              value: _kindness,
              onChanged: (value) => setState(() => _kindness = value),
            ),
            const SizedBox(height: 16),
            _PersonalitySlider(
              leftLabel: '落ち着き',
              rightLabel: '元気',
              value: _energy,
              onChanged: (value) => setState(() => _energy = value),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('見た目'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AiCharacter.avatarOptions.map((emoji) {
                final isSelected = emoji == _avatarEmoji;
                return _AvatarChoice(
                  emoji: emoji,
                  isSelected: isSelected,
                  onTap: () => setState(() => _avatarEmoji = emoji),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('保存する'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

/// 「左のラベル ⇄ 右のラベル」形式のスライダー(性格調整用)。
class _PersonalitySlider extends StatelessWidget {
  const _PersonalitySlider({
    required this.leftLabel,
    required this.rightLabel,
    required this.value,
    required this.onChanged,
  });

  final String leftLabel;
  final String rightLabel;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftLabel),
            Text(rightLabel),
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : null,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }
}
