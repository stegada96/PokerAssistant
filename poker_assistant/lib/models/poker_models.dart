enum GameMode { cash, tournament }

enum Street { preflop, flop, turn, river }

enum ActionRec { raise, call, fold }

enum StylePreset { tight, balanced, aggressive }

enum Pos9Max { utg, utg1, mp, lj, hj, co, btn, sb, bb }

extension Pos9MaxX on Pos9Max {
  String get label =>
      const ["UTG", "UTG+1", "MP", "LJ", "HJ", "CO", "BTN", "SB", "BB"][0] ==
              "UTG"
          ? ["UTG", "UTG+1", "MP", "LJ", "HJ", "CO", "BTN", "SB", "BB"][index]
          : toString();

  Pos9Max next() => Pos9Max.values[(index + 1) % Pos9Max.values.length];
}

class CardPick {
  final int? rank; // 2..14
  final int? suit; // 0..3
  const CardPick({this.rank, this.suit});
  bool get complete => rank != null && suit != null;
  int? idOrNull() => complete ? (rank! - 2) * 4 + suit! : null;
}

class AppSettings {
  final GameMode mode;
  final int playersAtTable; // 2..9
  final Pos9Max startPos; // hero position at start
  final int iterations; // Monte Carlo
  final double sb;
  final double bb;
  final double ante;

  final StylePreset preset;
  // Percentuali personalizzabili: open-raise per posizione (9 valori)
  final List<double> openRaisePctByPos; // 0..100

  const AppSettings({
    required this.mode,
    required this.playersAtTable,
    required this.startPos,
    required this.iterations,
    required this.sb,
    required this.bb,
    required this.ante,
    required this.preset,
    required this.openRaisePctByPos,
  });

  AppSettings copyWith({
    GameMode? mode,
    int? playersAtTable,
    Pos9Max? startPos,
    int? iterations,
    double? sb,
    double? bb,
    double? ante,
    StylePreset? preset,
    List<double>? openRaisePctByPos,
  }) {
    return AppSettings(
      mode: mode ?? this.mode,
      playersAtTable: playersAtTable ?? this.playersAtTable,
      startPos: startPos ?? this.startPos,
      iterations: iterations ?? this.iterations,
      sb: sb ?? this.sb,
      bb: bb ?? this.bb,
      ante: ante ?? this.ante,
      preset: preset ?? this.preset,
      openRaisePctByPos: openRaisePctByPos ?? this.openRaisePctByPos,
    );
  }

  static List<double> presetOpenRaise(StylePreset p) {
    // 9-max vs unknown: balanced = "gioco un po' di mani"
    // [UTG,UTG+1,MP,LJ,HJ,CO,BTN,SB,BB]
    switch (p) {
      case StylePreset.tight:
        return [12, 13, 15, 17, 19, 24, 35, 18, 0];
      case StylePreset.balanced:
        return [14, 15, 17, 19, 22, 28, 42, 22, 0];
      case StylePreset.aggressive:
        return [18, 19, 21, 24, 28, 34, 50, 28, 0];
    }
  }

  static AppSettings defaults() => AppSettings(
        mode: GameMode.cash,
        playersAtTable: 9,
        startPos: Pos9Max.bb,
        iterations: 10000,
        sb: 0.5,
        bb: 1.0,
        ante: 0.0,
        preset: StylePreset.balanced,
        openRaisePctByPos: presetOpenRaise(StylePreset.balanced),
      );
}
