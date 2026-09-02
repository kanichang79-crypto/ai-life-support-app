import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/ai_character.dart';

/// [AiCharacter]の見た目を表示するウィジェット。
///
/// カスタム画像が設定されていればそれを表示する。保存元は環境によって異なり、
/// Web版は[AiCharacter.avatarImageBase64]から、ネイティブ版(Android/iOS/
/// デスクトップ)は[AiCharacter.avatarImagePath]の端末内ファイルから読み込む。
/// カスタム画像が未設定の場合は絵文字アイコンを表示する。
class CharacterAvatarImage extends StatelessWidget {
  const CharacterAvatarImage({
    super.key,
    required this.character,
    required this.size,
    this.emojiFontSize,
  });

  final AiCharacter character;
  final double size;
  final double? emojiFontSize;

  @override
  Widget build(BuildContext context) {
    if (character.avatarType == AvatarType.image) {
      final base64Image = character.avatarImageBase64;
      if (base64Image != null) {
        return Image.memory(
          base64Decode(base64Image),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.broken_image, size: size * 0.7),
        );
      }

      final imagePath = character.avatarImagePath;
      if (imagePath != null) {
        return Image.file(
          File(imagePath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.broken_image, size: size * 0.7),
        );
      }
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          character.avatarEmoji,
          style: TextStyle(fontSize: emojiFontSize ?? size * 0.65),
        ),
      ),
    );
  }
}
