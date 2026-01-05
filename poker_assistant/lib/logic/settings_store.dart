import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/poker_models.dart';

class SettingsStore {
  static const _k = "pokerassistant_settings_v2";

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
        openRaisePctByPos: (m["openRaisePctByPos"] as List)
            .map((x) => (x as num).toDouble())
            .toList(),
        callBufferEarly: ((m["callBufferEarly"] as num?) ?? 7.0).toDouble(),
        callBufferLate: ((m["callBufferLate"] as num?) ?? 10.0).toDouble(),
        preflopRaiseEqBase:
            ((m["preflopRaiseEqBase"] as num?) ?? 52.0).toDouble(),
        preflopRaiseEqPerOpp:
            ((m["preflopRaiseEqPerOpp"] as num?) ?? 3.0).toDouble(),
        preflopCallEqBase:
            ((m["preflopCallEqBase"] as num?) ?? 40.0).toDouble(),
        preflopCallEqPerOpp:
            ((m["preflopCallEqPerOpp"] as num?) ?? 2.0).toDouble(),
        postflopNoBetRaiseEq:
            ((m["postflopNoBetRaiseEq"] as num?) ?? 62.0).toDouble(),
        postflopNoBetCallEq:
            ((m["postflopNoBetCallEq"] as num?) ?? 38.0).toDouble(),
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
      "callBufferEarly": s.callBufferEarly,
      "callBufferLate": s.callBufferLate,
      "preflopRaiseEqBase": s.preflopRaiseEqBase,
      "preflopRaiseEqPerOpp": s.preflopRaiseEqPerOpp,
      "preflopCallEqBase": s.preflopCallEqBase,
      "preflopCallEqPerOpp": s.preflopCallEqPerOpp,
      "postflopNoBetRaiseEq": s.postflopNoBetRaiseEq,
      "postflopNoBetCallEq": s.postflopNoBetCallEq,
    };
    await sp.setString(_k, json.encode(m));
  }
}
