import 'package:flutter/material.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int playersRemaining = 6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PokerAssistant — Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(child: Text('Players rimasti (te incluso)')),
                IconButton(
                  onPressed: () => setState(() => playersRemaining = (playersRemaining - 1).clamp(2, 6)),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$playersRemaining',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => setState(() => playersRemaining = (playersRemaining + 1).clamp(2, 6)),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Setup OK. Prossimo step: Preflop + Equity')),
                  );
                },
                child: const Text('INIZIA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
