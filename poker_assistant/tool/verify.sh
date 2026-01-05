#!/usr/bin/env bash
set -euo pipefail

echo "== PokerAssistant Verify =="

# Assicura di essere nella root Flutter (dove c'e pubspec.yaml)
if [[ ! -f "pubspec.yaml" ]]; then
  echo "ERRORE: pubspec.yaml non trovato. Esegui da /poker_assistant"
  exit 1
fi

export PATH="$HOME/flutter/bin:$PATH" || true

echo "-> flutter --version"
flutter --version

echo "-> flutter pub get"
flutter pub get

echo "-> dart format (fail se non formattato)"
dart format . --set-exit-if-changed

echo "-> flutter analyze"
flutter analyze

echo "-> flutter test"
flutter test

echo "-> Check: NO dot-shorthand (:\s*\.)"
if grep -R -nE ":\s*\." lib >/dev/null; then
  echo "ERRORE: trovata dot-shorthand (:\s*\.) nel codice. Rimuovila."
  grep -R -nE ":\s*\." lib || true
  exit 1
fi

echo "-> Check: import SetupScreen / HandScreen existence"
test -f lib/screens/setup_screen.dart
test -f lib/screens/hand_screen.dart

echo "OK ✅"
