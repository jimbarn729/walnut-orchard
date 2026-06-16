#!/usr/bin/env bash
set -euo pipefail

echo "Проверяю окружение для flutter..."
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter не найден в PATH. Пожалуйста, установите Flutter: https://docs.flutter.dev/get-started/install"
  exit 1
fi

echo "Flutter найден: $(flutter --version | head -n1)"

echo "Выполняю flutter pub get..."
flutter pub get

echo "Готово. Чтобы запустить приложение используйте:"
echo "  flutter run"
echo "или для веба:"
echo "  flutter run -d web-server --web-port 8080"
