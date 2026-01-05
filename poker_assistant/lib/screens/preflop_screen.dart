import 'package:flutter/material.dart';
import '../models/poker_models.dart';
import '../logic/montecarlo.dart';

class PreflopScreen extends StatefulWidget {
  final int initialPlayers; // include hero (2..6)
  const PreflopScreen({super.key, required this.initialPlayers});

  @override
  State<PreflopScreen> createState() => _PreflopScreenState();
}

class _PreflopScreenState extends State<PreflopScreen> {
  Position6Max pos = Position6Max.sb;
  late int players;

  CardPick c1 = const CardPick(), c2 = const CardPick();
  double? eq;
  String advice = "Seleziona le carte";

  final ranks = [14,13,12,11,10,9,8,7,6,5,4,3,2];
  final suits = ["♠","♥","♦","♣"];

  @override
  void initState() {
    super.initState();
    players = widget.initialPlayers;
  }

  void newHand() {
    setState(() {
      pos = pos.next();
      c1 = const CardPick();
      c2 = const CardPick();
      eq = null;
      advice = "Seleziona le carte";
    });
  }

  void calc() {
    if (!c1.complete || !c2.complete) return;

    final h1 = c1.id();
    final h2 = c2.id();
    if (h1 == h2) {
      setState(() {
        eq = null;
        advice = "Carte duplicate";
      });
      return;
    }

    final opponents = (players - 1).clamp(1, 5);
    final e = monteCarlo(h1, h2, opponents, 10000);

    setState(() {
      eq = double.parse(e.toStringAsFixed(1));
      final x = eq!;
      advice = x >= 55 ? "RAISE" : x >= 45 ? "CALL" : "FOLD";
    });
  }

  String rankLabel(int r) {
    if (r == 14) return "A";
    if (r == 13) return "K";
    if (r == 12) return "Q";
    if (r == 11) return "J";
    if (r == 10) return "T";
    return "$r";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Preflop • ${pos.label}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: newHand,
            tooltip: "Nuova mano (+1 posizione)",
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: Text("Players rimasti (te incluso): $players")),
              IconButton(
                onPressed: () { setState(() => players = (players - 1).clamp(2, 6)); calc(); },
                icon: const Icon(Icons.remove_circle_outline),
              ),
              IconButton(
                onPressed: () { setState(() => players = (players + 1).clamp(2, 6)); calc(); },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text("Equity: ${eq?.toStringAsFixed(1) ?? '--'}%",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(advice, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 28),

          const Text("Carta 1", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 6,
            children: ranks.map((r) => ChoiceChip(
              label: Text(rankLabel(r)),
              selected: c1.rank == r,
              onSelected: (_) { setState(() => c1 = CardPick(rank: r, suit: c1.suit)); calc(); },
            )).toList(),
          ),
          Wrap(
            spacing: 6,
            children: List.generate(4, (i) => ChoiceChip(
              label: Text(suits[i]),
              selected: c1.suit == i,
              onSelected: (_) { setState(() => c1 = CardPick(rank: c1.rank, suit: i)); calc(); },
            )),
          ),

          const SizedBox(height: 14),
          const Text("Carta 2", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 6,
            children: ranks.map((r) => ChoiceChip(
              label: Text(rankLabel(r)),
              selected: c2.rank == r,
              onSelected: (_) { setState(() => c2 = CardPick(rank: r, suit: c2.suit)); calc(); },
            )).toList(),
          ),
          Wrap(
            spacing: 6,
            children: List.generate(4, (i) => ChoiceChip(
              label: Text(suits[i]),
              selected: c2.suit == i,
              onSelected: (_) { setState(() => c2 = CardPick(rank: c2.rank, suit: i)); calc(); },
            )),
          ),

          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: newHand,
                  child: const Text("FOLD"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Prossimo step: aggiungiamo FLOP/Turn/River")),
                    );
                  },
                  child: const Text("CHECK/CALL"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
