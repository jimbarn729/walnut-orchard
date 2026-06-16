 # walnut-orchard

Игра "Walnut Farm" — Flutter проект. Этот README объясняет, как подготовить окружение и запустить приложение локально.

## Требования
- Установленный Flutter (рек. версия совместимая с SDK >= 3.12).
- Установленное `dart` и `flutter` в PATH.

## Быстрая инструкция по запуску
1. Установите Flutter: https://docs.flutter.dev/get-started/install
2. В корне проекта выполните:

```bash
cd /path/to/walnut-orchard
flutter pub get
flutter run
```

Для запуска на вебе:

```bash
flutter run -d web-server --web-port 8080
```

## Примечания
- В репозитории используется `cached_network_image` и другие зависимости, проверьте `pubspec.yaml`.
- Если в вашей системе отсутствуют `flutter`/`dart`, запустите `scripts/setup.sh` для проверки окружения (скрипт не установит Flutter автоматически).

## Что я сделал
- Упростил `lib/main.dart`, чтобы приложение использовало модульные экраны из `lib/screens`.
- Исправил отображение изображений в `lib/screens/market_screen.dart` (используется `CachedNetworkImage`).
- Добавил индикатор ежедневного бонуса и состояние звука в `WalletScreen`.
- Добавил этот README и скрипт проверки окружения.

Если захотите, могу попытаться запустить `flutter pub get` и `flutter analyze` в контейнере, но сейчас в окружении эти инструменты отсутствуют.
