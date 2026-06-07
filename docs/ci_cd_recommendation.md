# Recommended CI/CD

Use GitHub Actions with three workflows:

## 1) PR Quality Gate

- `flutter pub get`
- `flutter analyze`
- `flutter test`

## 2) Staging Build

- Trigger on `develop`.
- Build Android APK + iOS archive.
- Upload artifacts.

## 3) Release Pipeline

- Trigger on version tags.
- Build signed AAB/IPA.
- Upload symbols to crash tooling.
- Publish to TestFlight + Play Internal track.

Use encrypted secrets for all `--dart-define` values.
