import 'package:flutter/material.dart';
import '../logic/settings_store.dart';
import '../models/poker_models.dart';
import 'hand_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  AppSettings s = AppSettings.defaults();
  bool loaded = false;

  final _sbCtl = TextEditingController();
  final _bbCtl = TextEditingController();
  final _anteCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    SettingsStore.load().then((v) {
      setState(() {
        s = v;
        loaded = true;
        _sbCtl.text = s.sb.toString();
        _bbCtl.text = s.bb.toString();
        _anteCtl.text = s.ante.toString();
      });
    });
  }

  Future<void> _save() async {
    // parse numeric fields
    final sb = double.tryParse(_sbCtl.text) ?? s.sb;
    final bb = double.tryParse(_bbCtl.text) ?? s.bb;
    final ante = double.tryParse(_anteCtl.text) ?? s.ante;
    final ss = s.copyWith(sb: sb, bb: bb, ante: ante);
    setState(() => s = ss);
    await SettingsStore.save(ss);
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("PokerAssistant — Impostazioni")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Tavolo attuale", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Row(
            children: [
              const Expanded(child: Text("Modalità")),
              SegmentedButton<GameMode>(
                segments: const [
                  ButtonSegment(value: GameMode.cash, label: Text("Cash")),
                  ButtonSegment(value: GameMode.tournament, label: Text("Torneo")),
                ],
                selected: {s.mode},
                onSelectionChanged: (v) async {
                  setState(() => s = s.copyWith(mode: v.first));
                  await _save();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              const Expanded(child: Text("Giocatori al tavolo (max 9)")),
              IconButton(
                onPressed: () async { setState(() => s = s.copyWith(playersAtTable: (s.playersAtTable - 1).clamp(2, 9))); await _save(); },
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text("${s.playersAtTable}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () async { setState(() => s = s.copyWith(playersAtTable: (s.playersAtTable + 1).clamp(2, 9))); await _save(); },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              const Expanded(child: Text("Posizione iniziale (tu)")),
              DropdownButton<Pos9Max>(
                value: s.startPos,
                items: Pos9Max.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => s = s.copyWith(startPos: v));
                  await _save();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              const Expanded(child: Text("SB")),
              SizedBox(width: 120, child: TextField(controller: _sbCtl, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => _save())),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(child: Text("BB")),
              SizedBox(width: 120, child: TextField(controller: _bbCtl, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => _save())),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(child: Text("Ante")),
              SizedBox(width: 120, child: TextField(controller: _anteCtl, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => _save())),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              const Expanded(child: Text("Simulazioni Monte Carlo")),
              DropdownButton<int>(
                value: s.iterations,
                items: const [
                  DropdownMenuItem(value: 5000, child: Text("5000")),
                  DropdownMenuItem(value: 10000, child: Text("10000")),
                  DropdownMenuItem(value: 20000, child: Text("20000")),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => s = s.copyWith(iterations: v));
                  await _save();
                },
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(),
          const Text("Stile di gioco", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Row(
            children: [
              const Expanded(child: Text("Preset")),
              DropdownButton<StylePreset>(
                value: s.preset,
                items: StylePreset.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  final open = AppSettings.presetOpenRaise(v);
                  setState(() => s = s.copyWith(preset: v, openRaisePctByPos: open));
                  await _save();
                },
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Text("Open-raise % per posizione (modificabile)"),
          const SizedBox(height: 8),

          ...List.generate(Pos9Max.values.length, (i) {
            final p = Pos9Max.values[i];
            final pct = s.openRaisePctByPos[i];
            return Row(
              children: [
                SizedBox(width: 70, child: Text(p.label)),
                Expanded(
                  child: Slider(
                    value: pct.clamp(0, 80),
                    min: 0,
                    max: 80,
                    divisions: 80,
                    label: "${pct.toStringAsFixed(0)}%",
                    onChanged: (v) async {
                      final lst = List<double>.from(s.openRaisePctByPos);
                      lst[i] = v;
                      setState(() => s = s.copyWith(openRaisePctByPos: lst));
                      await _save();
                    },
                  ),
                ),
                SizedBox(width: 52, child: Text("${pct.toStringAsFixed(0)}%")),
              ],
            );
          }),

          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () async {
                await _save();
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => HandScreen(settings: s)));
              },
              child: const Text("INIZIA (NUOVA MANO)"),
            ),
          ),
        ],
      ),
    );
  }
}
