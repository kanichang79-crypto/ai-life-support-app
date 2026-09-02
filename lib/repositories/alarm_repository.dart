import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm.dart';

/// アラーム一覧を端末のローカルストレージ(SharedPreferences)に
/// JSON文字列として保存・読み込みするリポジトリ。
class AlarmRepository {
  static const _storageKey = 'alarms';

  Future<List<Alarm>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Alarm.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAlarms(List<Alarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(alarms.map((a) => a.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
