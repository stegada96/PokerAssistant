enum Position6Max { sb, bb, utg, mp, co, btn }

extension Position6MaxX on Position6Max {
  String get label => ["SB","BB","UTG","MP","CO","BTN"][index];
  Position6Max next() => Position6Max.values[(index + 1) % 6];
}

class CardPick {
  final int? rank; // 2..14
  final int? suit; // 0..3
  const CardPick({this.rank, this.suit});
  bool get complete => rank != null && suit != null;
  int id() => (rank! - 2) * 4 + suit!;
}
