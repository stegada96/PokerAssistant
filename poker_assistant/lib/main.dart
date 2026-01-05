import 'package:flutter/material.dart';
import 'screens/setup_screen.dart';

void main() => runApp(const PokerAssistantApp());

class PokerAssistantApp extends StatelessWidget {
  const PokerAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokerAssistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const SetupScreen(),
    );
  }
}
