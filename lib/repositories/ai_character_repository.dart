import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_character.dart';

/// AIキャラクターのカスタマイズ設定を端末のローカルストレージ(SharedPreferences)に
/// JSON文字列として保存・読み込みするリポジトリ。
///
/// アバターに使うカスタム画像は、写真ライブラリの一時ファイルではアプリ終了後に
/// 参照できなくなるため、アプリのドキュメントディレクトリへコピーして永続化する。
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

  /// [sourceImagePath] (写真ライブラリから選んだ画像の一時パス)をアプリの
  /// ドキュメントディレクトリへコピーして永続化し、保存後のパスを返す。
  ///
  /// [previousImagePath] が指定されていれば、コピー完了後にその画像ファイルを
  /// 削除して端末のストレージを圧迫しないようにする。
  Future<String> saveAvatarImage(
    String sourceImagePath, {
    String? previousImagePath,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'ai_character_avatar_${DateTime.now().millisecondsSinceEpoch}.img';
    final savedPath = '${directory.path}/$fileName';

    await File(sourceImagePath).copy(savedPath);

    if (previousImagePath != null && previousImagePath != savedPath) {
      final previousFile = File(previousImagePath);
      if (await previousFile.exists()) {
        await previousFile.delete();
      }
    }

    return savedPath;
  }
}
