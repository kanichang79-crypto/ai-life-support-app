import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_character.dart';

/// AIキャラクターのカスタマイズ設定を端末のローカルストレージ(SharedPreferences)に
/// JSON文字列として保存・読み込みするリポジトリ。
class AiCharacterRepository {
  static const _storageKey = 'ai_character';

  Future<AiCharacter> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const AiCharacter();

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AiCharacter.fromJson(decoded);
  }

  Future<void> save(AiCharacter character) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(character.toJson()));
  }
}
