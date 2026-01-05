import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../logic/montecarlo.dart';
import '../logic/range_matrix.dart';
import '../models/poker_models.dart';
import 'widgets.dart';

class HandScreen extends StatefulWidget {
  final AppSettings settings;
  const HandScreen({super.key, required this.settings});
  @override
  State<HandScreen> createState() => _HandScreenState();
}

class _HandScreenState extends State<HandScreen> {
  late AppSettings s;
  Street street = Street.preflop;

  late Pos9Max pos; // rotates +1 per hand
  int playersInHand = 9; // adjustable per street

  // hero cards
  CardPick h1 = const CardPick();
  CardPick h2 = const CardPick();

  // board (flop1/2/3, turn, river)
  CardPick f1 = const CardPick();
  CardPick f2 = const CardPick();
  CardPick f3 = const CardPick();
  CardPick t = const CardPick();
  CardPick r = const CardPick();

  // pot & bet for postflop
  final potCtl = TextEditingController(text: "0");
  final betCtl = TextEditingController(text: "0");

  double? equity;
  ActionRec rec = ActionRec.fold;
  String reason = "Seleziona carte";

  bool matrixOpen = false;
  Timer? _debounce;

  static const ranks = [14,13,12,11,10,9,8,7,6,5,4,3,2];
  static const rankLabel = {
    14:"A", 13:"K", 12:"Q", 11:"J", 10:"T",
    9:"9", 8:"8", 7:"7", 6:"6", 5:"5", 4:"4", 3:"3", 2:"2",
  };
  static const suits = [0,1,2,3];
  static const suitLabel = {0:"P",1:"C",2:"Q",3:"F"}; // Picche, Cuori, Quadri, Fiori

  @override
  void initState() {
    super.initState();
    s = widget.settings;
    pos = s.startPos;
    playersInHand = s.playersAtTable;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    potCtl.dispose();
    betCtl.dispose();
    super.dispose();
  }

  void newHand() {
    setState(() {
      street = Street.preflop;
      pos = pos.next(); // +1
      playersInHand = s.playersAtTable;

      h1 = const CardPick();
      h2 = const CardPick();
      f1 = const CardPick();
      f2 = const CardPick();
      f3 = const CardPick();
      t = const CardPick();
      r = const CardPick();
      equity = null;
      rec = ActionRec.fold;
      reason = "Seleziona carte";
      potCtl.text = "0";
      betCtl.text = "0";
    });
  }

  Color actionColor(ActionRec a) {
    switch (a) {
      case ActionRec.raise: return Colors.green;
      case ActionRec.call: return Colors.orange;
      case ActionRec.fold: return Colors.red;
    }
  }

  bool _hasHero() => h1.complete && h2.complete;

  List<int>? _knownBoardIds() {
    final ids = <int>[];
    if (street.index >= Street.flop.index) {
      final a = f1.idOrNull(), b = f2.idOrNull(), c = f3.idOrNull();
      if (a == null || b == null || c == null) return null;
      ids.addAll([a,b,c]);
    }
    if (street.index >= Street.turn.index) {
      final x = t.idOrNull(); if (x == null) return null;
      ids.add(x);
    }
    if (street.index >= Street.river.index) {
      final x = r.idOrNull(); if (x == null) return null;
      ids.add(x);
    }
    return ids;
  }

  bool _hasDuplicates(List<int> ids) {
    final set = <int>{};
    for (final x in ids) {
      if (set.contains(x)) return true;
      set.add(x);
    }
    return false;
  }

  double _pot() => double.tryParse(potCtl.text) ?? 0.0;
  double _bet() => double.tryParse(betCtl.text) ?? 0.0;

  double? _potOdds() {
    final pot = _pot();
    final bet = _bet();
    if (bet <= 0) return null;
    return bet / (pot + bet);
  }

  ActionRec _baselineFromMatrix(double? eqNow) {
    // baseline by position using 169 range
    if (!h1.complete || !h2.complete) return ActionRec.fold;

    final label = holeTo169Label(h1.rank!, h1.suit!, h2.rank!, h2.suit!);
    final d = decisionForPos(s, pos);
    if (d.raise.contains(label)) return ActionRec.raise;
    if (d.call.contains(label)) return ActionRec.call;
    return ActionRec.fold;
  }

  ActionRec _combineAdvice(ActionRec base, double e) {
    // refine by equity & street
    // preflop: equity helps override (AA must be raise even multiway)
    if (street == Street.preflop) {
      final opp = (playersInHand - 1).clamp(1, 8);
      // thresholds scale with opponents
      final raiseTh = (52 - (opp - 1) * 3).clamp(35, 52).toDouble();
      final callTh  = (40 - (opp - 1) * 2).clamp(25, 40).toDouble();
      if (e >= raiseTh) return ActionRec.raise;
      if (e >= callTh) return base == ActionRec.raise ? ActionRec.raise : ActionRec.call;
      return ActionRec.fold;
    }

    // postflop: use pot odds
    final po = _potOdds();
    if (po == null) {
      // no bet: prefer raise with strong equity else check/call
      if (e >= 60) return ActionRec.raise;
      if (e >= 40) return ActionRec.call;
      return ActionRec.fold;
    }
    final need = po * 100.0;
    // small edge margins for speed
    if (e + 3 < need) return ActionRec.fold;
    if (e > need + 12) return ActionRec.raise;
    return ActionRec.call;
  }

  String _reasonText(ActionRec base, double e) {
    if (street == Street.preflop) {
      return "Base ${base.name.toUpperCase()} da ${pos.label} • Equity ${e.toStringAsFixed(1)}% (vs ${playersInHand - 1})";
    }
    final po = _potOdds();
    if (po == null) return "Equity ${e.toStringAsFixed(1)}% • nessuna bet (usa check/raise)";
    final need = (po * 100).toStringAsFixed(1);
    return "Equity ${e.toStringAsFixed(1)}% vs PotOdds $need% (Pot ${_pot()} / Bet ${_bet()})";
  }

  void trigger() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 130), () async {
      if (!_hasHero()) return;

      final hero1 = h1.idOrNull()!;
      final hero2 = h2.idOrNull()!;
      final board = _knownBoardIds() ?? const <int>[];
      final used = <int>[hero1, hero2, ...board];
      if (_hasDuplicates(used)) {
        setState(() {
          equity = null;
          rec = ActionRec.fold;
          reason = "Carte duplicate";
        });
        return;
      }

      final base = _baselineFromMatrix(equity);
      setState(() => reason = "Calcolo…");

      final opp = (playersInHand - 1).clamp(1, 8);
      final res = await compute(
        computeEquity,
        EquityRequest(
          hero1: hero1,
          hero2: hero2,
          knownBoard: board,
          opponents: opp,
          iterations: s.iterations,
        ),
      );

      final e = double.parse(res.equity.toStringAsFixed(1));
      final combined = _combineAdvice(base, e);

      setState(() {
        equity = e;
        rec = combined;
        reason = _reasonText(base, e);
      });
    });
  }

  void nextStreet() {
    setState(() {
      if (street == Street.preflop) street = Street.flop;
      else if (street == Street.flop) street = Street.turn;
      else if (street == Street.turn) street = Street.river;
    });
    trigger();
  }

  Widget _rangeMatrixWidget() {
    // 13x13: ranks (A..2). Cells = AA..22 etc.
    final d = decisionForPos(s, pos);
    String cellLabel(int hi, int lo, bool suited) {
      String f(int r) => rankLabel[r]!;
      if (hi == lo) return "${f(hi)}${f(lo)}";
      return "${f(hi)}${f(lo)}${suited ? "s" : "o"}";
    }

    Color cellColor(String lab) {
      if (d.raise.contains(lab)) return Colors.green.withOpacity(0.55);
      if (d.call.contains(lab)) return Colors.orange.withOpacity(0.55);
      return Colors.red.withOpacity(0.25);
    }

    final rows = ranks;
    final cols = ranks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Range per posizione (13×13)", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: rows.map((rowR) {
              return Row(
                children: cols.map((colR) {
                  final hi = rowR;
                  final lo = colR;
                  final suited = (hi < lo); // upper triangle suited
                  final a = hi >= lo ? hi : lo;
                  final b = hi >= lo ? lo : hi;
                  final lab = (a == b) ? cellLabel(a, b, false) : cellLabel(a, b, suited);
                  return Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.all(1),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cellColor(lab),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(rankLabel[ (a==b ? a : (hi)) ]!, style: const TextStyle(fontSize: 10)),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        const Text("Verde=Raise • Giallo=Call • Rosso=Fold", style: TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = equity;
    final color = actionColor(rec);

    return Scaffold(
      appBar: AppBar(
        title: Text("${street.name.toUpperCase()} • ${pos.label}"),
        actions: [
          IconButton(onPressed: newHand, icon: const Icon(Icons.refresh), tooltip: "Nuova mano (+1 posizione)"),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: Text("In mano adesso (te incluso): $playersInHand")),
              IconButton(
                onPressed: () { setState(() => playersInHand = (playersInHand - 1).clamp(2, 9)); trigger(); },
                icon: const Icon(Icons.remove_circle_outline),
              ),
              IconButton(
                onPressed: () { setState(() => playersInHand = (playersInHand + 1).clamp(2, 9)); trigger(); },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text("SB ${s.sb} / BB ${s.bb} • Ante ${s.ante} • ${s.mode == GameMode.cash ? "Cash" : "Torneo"}"),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e == null ? "Equity: —" : "Equity: ${e.toStringAsFixed(1)}%",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 6),
                Text(reason),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Pulsanti azione colorati
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(backgroundColor: rec == ActionRec.raise ? Colors.green : Colors.green.withOpacity(0.25)),
                  icon: const Icon(Icons.trending_up),
                  label: const Text("RAISE"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    // check/call: chiedi se passare street
                    final go = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Passare alla street successiva?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("NO")),
                          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("SÌ")),
                        ],
                      ),
                    );
                    if (go == true) nextStreet();
                  },
                  style: FilledButton.styleFrom(backgroundColor: rec == ActionRec.call ? Colors.orange : Colors.orange.withOpacity(0.25)),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("CHECK/CALL"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () { newHand(); },
                  style: FilledButton.styleFrom(backgroundColor: rec == ActionRec.fold ? Colors.red : Colors.red.withOpacity(0.25)),
                  icon: const Icon(Icons.close),
                  label: const Text("FOLD"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Pot & Bet (solo postflop, ma puoi metterli sempre)
          if (street != Street.preflop) ...[
            Row(
              children: [
                const Expanded(child: Text("POT")),
                SizedBox(width: 120, child: TextField(controller: potCtl, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => trigger())),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Expanded(child: Text("BET da chiamare")),
                SizedBox(width: 120, child: TextField(controller: betCtl, keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (_) => trigger())),
              ],
            ),
            const SizedBox(height: 10),
          ],

          const Divider(height: 26),

          // HERO cards
          const Text("Hero", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Carta 1"),
          ChipPicker<int>(values: ranks, label: (v) => rankLabel[v]!, selected: h1.rank, onPick: (v){ setState(()=>h1=CardPick(rank:v,suit:h1.suit)); trigger(); }),
          const SizedBox(height: 8),
          ChipPicker<int>(values: suits, label: (v) => suitLabel[v]!, selected: h1.suit, onPick: (v){ setState(()=>h1=CardPick(rank:h1.rank,suit:v)); trigger(); }),

          const SizedBox(height: 12),
          const Text("Carta 2"),
          ChipPicker<int>(values: ranks, label: (v) => rankLabel[v]!, selected: h2.rank, onPick: (v){ setState(()=>h2=CardPick(rank:v,suit:h2.suit)); trigger(); }),
          const SizedBox(height: 8),
          ChipPicker<int>(values: suits, label: (v) => suitLabel[v]!, selected: h2.suit, onPick: (v){ setState(()=>h2=CardPick(rank:h2.rank,suit:v)); trigger(); }),

          const Divider(height: 26),

          // BOARD by street
          if (street.index >= Street.flop.index) ...[
            const Text("FLOP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text("Flop 1"),
            ChipPicker<int>(values: ranks, label: (v) => rankLabel[v]!, selected: f1.rank, onPick: (v){ setState(()=>f1=CardPick(rank:v,suit:f1.suit)); trigger(); }),
            const SizedBox(height: 6),
            ChipPicker<int>(values: suits, label: (v) => suitLabel[v]!, selected: f1.suit, onPick: (v){ setState(()=>f1=CardPick(rank:f1.rank,suit:v)); trigger(); }),

            const SizedBox(height: 10),
            const Text("Flop 2"),
            ChipPicker<int>(values: ranks, label: (v) => rankLabel[v]!, selected: f2.rank, onPick: (v){ setState(()=>f2=CardPick(rank:v,suit:f2.suit)); trigger(); }),
            const SizedBox(height: 6),
            ChipPicker<int>(values: suits, label: (v) => suitLabel[v]!, selected: f2.suit, onPick: (v){ setState(()=>f2=CardPick(rank:f2.rank,suit:v)); trigger(); }),

            const SizedBox(height: 10),
            const Text("Flop 3"),
            ChipPicker<int>(values: ranks, label: (v) => rankLabel[v]!, selected: f3.rank, onPick: (v){ setState(()=>f3=CardPick(rank:v,suit:f3.suit)); trigger(); }),
            const SizedBox(height: 6),
            ChipPicker<int>(values: suits, label: (v) => suitLabel[v]!, selected: f3.suit, onPick: (v){ setState(()=>f3=CardPick(rank:f3.rank,suit:v)); trigger(); }),
          ],

          if (street.index >= Street.turn.index) ...[
            const Divider(height: 26),
            const Text("TURN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ChipPicker<int>(values: ranks, label: (v) => rankLabel[v]!, selected: t.rank, onPick: (v){ setState(()=>t=CardPick(rank:v,suit:t.suit)); trigger(); }),
            const SizedBox(height: 6),
            ChipPicker<int>(values: suits, label: (v) => suitLabel[v]!, selected: t.suit, onPick: (v){ setState(()=>t=CardPick(rank:t.rank,suit:v)); trigger(); }),
          ],

          if (street.index >= Street.river.index) ...[
            const Divider(height: 26),
            const Text("RIVER", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ChipPicker<int>(values: ranks, label: (v) => rankLabel[v]!, selected: r.rank, onPick: (v){ setState(()=>r=CardPick(rank:v,suit:r.suit)); trigger(); }),
            const SizedBox(height: 6),
            ChipPicker<int>(values: suits, label: (v) => suitLabel[v]!, selected: r.suit, onPick: (v){ setState(()=>r=CardPick(rank:r.rank,suit:v)); trigger(); }),
          ],

          const Divider(height: 26),

          // Collapsible matrix
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("Range per ${pos.label} (tap per aprire/chiudere)"),
            trailing: Icon(matrixOpen ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => matrixOpen = !matrixOpen),
          ),
          if (matrixOpen) _rangeMatrixWidget(),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
