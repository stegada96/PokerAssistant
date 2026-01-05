import 'dart:math';

int rank(int c) => c ~/ 4;
int suit(int c) => c % 4;

int eval(List<int> h) {
  h.sort();
  int v = 0;
  for (final c in h) v = v * 53 + c;
  return v;
}

double monteCarlo(int h1, int h2, int opp, int iters) {
  final rng = Random();
  int win = 0, tie = 0;

  for (int i = 0; i < iters; i++) {
    final used = <int>{h1, h2};
    int draw() {
      int c;
      do { c = rng.nextInt(52); } while (used.contains(c));
      used.add(c);
      return c;
    }

    final hero = [h1, h2, draw(), draw(), draw(), draw(), draw()];
    final heroScore = eval(hero);

    bool best = true;
    int same = 0;
    for (int o = 0; o < opp; o++) {
      final oppHand = [draw(), draw(), draw(), draw(), draw(), draw(), draw()];
      final os = eval(oppHand);
      if (os > heroScore) best = false;
      if (os == heroScore) same++;
    }
    if (best && same == 0) win++;
    if (best && same > 0) tie++;
  }
  return (win + tie * 0.5) / iters * 100.0;
}
