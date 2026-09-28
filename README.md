# Kizart

Kizart is a private, local-first mobile library for children's artwork. Scan art with automatic edge detection and perspective correction, then organize it by child, grade, year, album, and tag.

## Included in this MVP

- Multiple child profiles
- Camera and photo-library scanning
- Automatic crop with manual corner adjustment
- Artwork titles, notes, year, grade, favorites, albums, and tags
- Search and child/favorite filters
- On-device SQLite storage and private image files
- Native share sheet for individual artwork
- iOS and Android project targets

Cloud sync, collaborative album sharing, and print ordering are intentionally presented as future features.

## Run locally

1. Install the [Flutter stable SDK](https://docs.flutter.dev/get-started/install).
2. Run `flutter pub get`.
3. Start an iOS simulator or Android API 24+ device.
4. Run `flutter run`.

For iOS, open `ios/Runner.xcworkspace` on macOS if signing configuration is needed. Camera scanning should be tested on a physical device.

## GitHub iOS builds

`.github/workflows/ios.yml` runs analysis, tests, and an unsigned iOS release build on pushes and pull requests to `main`. The resulting `Runner.app` is uploaded as a workflow artifact for build verification.

After signing is enabled, every successful push to `main` also uses Fastlane and the private `match-signing` repository to create a signed IPA and upload it to TestFlight. The permanent iOS bundle identifier is `com.kizart.app`.

The TestFlight job requires these encrypted GitHub Actions secrets:

- `TEAM_ID`
- `APPLE_KEY_ID`
- `APPLE_ISSUER_ID`
- `APPLE_KEY_CONTENT` (base64-encoded `.p8` key)
- `MATCH_PASSWORD`
- `MATCH_GIT_BASIC_AUTHORIZATION`

It also uses the repository variables `APP_ID`, `MATCH_REPOSITORY`, and `TESTFLIGHT_ENABLED`. Keep `TESTFLIGHT_ENABLED` set to `false` until the App Store Connect app exists and all secrets have been added.

## Verification

```sh
flutter analyze
flutter test
```
