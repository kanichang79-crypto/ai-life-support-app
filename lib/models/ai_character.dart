/// AIキャラクターの口調プリセット。
enum ToneStyle {
  /// フランクなタメ口。
  casual,

  /// 丁寧な敬語。
  polite;

  String get label => switch (this) {
        ToneStyle.casual => 'タメ口',
        ToneStyle.polite => '敬語',
      };

  static ToneStyle fromName(String? name) {
    return ToneStyle.values.firstWhere(
      (t) => t.name == name,
      orElse: () => ToneStyle.casual,
    );
  }
}

/// ユーザーがカスタマイズするAIキャラクターの設定。
///
/// 名前・口調・性格(優しさ/元気さのスライダー)・見た目(絵文字アイコン)を保持し、
/// [buildSystemInstruction] でAIへの人格指定プロンプトに変換する。
class AiCharacter {
  const AiCharacter({
    this.name = 'ミライ',
    this.tone = ToneStyle.casual,
    this.kindness = 0.7,
    this.energy = 0.6,
    this.avatarEmoji = '🤖',
  });

  /// キャラクターの名前(自由入力)。
  final String name;

  /// 口調プリセット。
  final ToneStyle tone;

  /// 性格:優しさ。0.0(厳しい)〜1.0(優しい)。
  final double kindness;

  /// 性格:元気さ。0.0(落ち着き)〜1.0(元気)。
  final double energy;

  /// 見た目として使う絵文字アイコン。
  final String avatarEmoji;

  /// 見た目の選択肢(シンプルな絵文字ベース)。
  static const List<String> avatarOptions = [
    '🤖',
    '😊',
    '🐱',
    '🐶',
    '🦊',
    '🐻',
    '🌟',
    '🧑‍🚀',
  ];

  AiCharacter copyWith({
    String? name,
    ToneStyle? tone,
    double? kindness,
    double? energy,
    String? avatarEmoji,
  }) {
    return AiCharacter(
      name: name ?? this.name,
      tone: tone ?? this.tone,
      kindness: kindness ?? this.kindness,
      energy: energy ?? this.energy,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tone': tone.name,
      'kindness': kindness,
      'energy': energy,
      'avatarEmoji': avatarEmoji,
    };
  }

  factory AiCharacter.fromJson(Map<String, dynamic> json) {
    return AiCharacter(
      name: json['name'] as String? ?? 'ミライ',
      tone: ToneStyle.fromName(json['tone'] as String?),
      kindness: (json['kindness'] as num?)?.toDouble() ?? 0.7,
      energy: (json['energy'] as num?)?.toDouble() ?? 0.6,
      avatarEmoji: json['avatarEmoji'] as String? ?? '🤖',
    );
  }

  /// この設定内容をもとに、AIへの人格指定(システムプロンプト)を組み立てる。
  String buildSystemInstruction() {
    final buffer = StringBuffer()
      ..write(
        'あなたは「$name」という名前の、ユーザーの日常生活をサポートするAIアシスタントです。',
      );

    buffer.write(
      tone == ToneStyle.casual
          ? '敬語は使わず、親しい友人のようなタメ口で話してください。'
          : '常に丁寧な敬語を使って話してください。',
    );

    if (kindness >= 0.7) {
      buffer.write('とても優しく、包み込むように共感しながら接してください。');
    } else if (kindness >= 0.35) {
      buffer.write('優しさと的確さのバランスを取りながら接してください。');
    } else {
      buffer.write('甘やかさず、必要なときははっきりと厳しめに指摘してください。');
    }

    if (energy >= 0.7) {
      buffer.write('明るく元気なテンションで、テンポよく話してください。');
    } else if (energy >= 0.35) {
      buffer.write('落ち着きつつも親しみのある調子で話してください。');
    } else {
      buffer.write('落ち着いた、ゆったりとした穏やかな口調で話してください。');
    }

    buffer.write(
      '回答は必ず2〜3文以内の簡潔な文章にまとめてください。前置きや繰り返しは避け、'
      '結論から端的に話し、難しい専門用語は避けてください。'
      'ユーザーの体調や気分を気遣いながら、雑談やちょっとした相談にも気さくに応じてください。',
    );

    return buffer.toString();
  }
}
