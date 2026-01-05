import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/poker_models.dart';

class SettingsStore {
  static const _k = "pokerassistant_settings_v1";

  static Future<AppSettings> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_k);
    if (raw == null) return AppSettings.defaults();
    try {
      final m = json.decode(raw) as Map<String, dynamic>;
      return AppSettings(
        mode: GameMode.values[m["mode"] as int],
        playersAtTable: (m["playersAtTable"] as int),
        startPos: Pos9Max.values[m["startPos"] as int],
        iterations: (m["iterations"] as int),
        sb: (m["sb"] as num).toDouble(),
        bb: (m["bb"] as num).toDouble(),
        ante: (m["ante"] as num).toDouble(),
        preset: StylePreset.values[m["preset"] as int],
        openRaisePctByPos: (m["openRaisePctByPos"] as List).map((x) => (x as num).toDouble()).toList(),
      );
    } catch (_) {
      return AppSettings.defaults();
    }
  }

  static Future<void> save(AppSettings s) async {
    final sp = await SharedPreferences.getInstance();
    final m = {
      "mode": s.mode.index,
      "playersAtTable": s.playersAtTable,
      "startPos": s.startPos.index,
      "iterations": s.iterations,
      "sb": s.sb,
      "bb": s.bb,
      "ante": s.ante,
      "preset": s.preset.index,
      "openRaisePctByPos": s.openRaisePctByPos,
    };
    await sp.setString(_k, json.encode(m));
  }
}
