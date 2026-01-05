import 'package:flutter/material.dart';
import '../models/poker_models.dart';
import '../logic/montecarlo.dart';

class PreflopScreen extends StatefulWidget {
  const PreflopScreen({super.key});
  @override
  State<PreflopScreen> createState() => _PreflopScreenState();
}

class _PreflopScreenState extends State<PreflopScreen> {
  Position6Max pos = Position6Max.sb;
  int players = 6;
  CardPick c1 = const CardPick(), c2 = const CardPick();
  double? eq;
  String advice = "Seleziona le carte";

  final ranks = [14,13,12,11,10,9,8,7,6,5,4,3,2];
  final suits = ["♠","♥","♦","♣"];

  void calc() {
    if (!c1.complete || !c2.complete) return;
    if (c1.id() == c2.id()) {
      setState(() => advice = "Carte duplicate");
      return;
    }
    final e = monteCarlo(c1.id(), c2.id(), players - 1, 10000);
    setState(() {
      eq = e;
      advice = e >= 55 ? "RAISE" : e >= 45 ? "CALL" : "FOLD";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Preflop • ${pos.label}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              pos = pos.next();
              c1 = const CardPick(); c2 = const CardPick();
              eq = null; advice = "Seleziona le carte";
            }),
          )
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text("Players: $players"),
        Row(children: [
          IconButton(onPressed:(){setState(()=>players=(players-1).clamp(2,6));calc();}, icon: const Icon(Icons.remove)),
          IconButton(onPressed:(){setState(()=>players=(players+1).clamp(2,6));calc();}, icon: const Icon(Icons.add)),
        ]),
        const Divider(),

        Text("Equity: ${eq?.toStringAsFixed(1) ?? '--'}%", style: const TextStyle(fontSize: 22)),
        Text(advice, style: const TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
        const Divider(),

        const Text("Carta 1"),
        Wrap(children: ranks.map((r)=>ChoiceChip(
          label: Text(r==14?"A":r==13?"K":r==12?"Q":r==11?"J":"$r"),
          selected: c1.rank==r,
          onSelected: (_){setState(()=>c1=CardPick(rank:r,suit:c1.suit));calc();}
        )).toList()),
        Wrap(children: List.generate(4,(i)=>ChoiceChip(
          label: Text(suits[i]),
          selected: c1.suit==i,
          onSelected: (_){setState(()=>c1=CardPick(rank:c1.rank,suit:i));calc();}
        ))),

        const SizedBox(height: 10),
        const Text("Carta 2"),
        Wrap(children: ranks.map((r)=>ChoiceChip(
          label: Text(r==14?"A":r==13?"K":r==12?"Q":r==11?"J":"$r"),
          selected: c2.rank==r,
          onSelected: (_){setState(()=>c2=CardPick(rank:r,suit:c2.suit));calc();}
        )).toList()),
        Wrap(children: List.generate(4,(i)=>ChoiceChip(
          label: Text(suits[i]),
          selected: c2.suit==i,
          onSelected: (_){setState(()=>c2=CardPick(rank:c2.rank,suit:i));calc();}
        ))),
      ]),
    );
  }
}
