# Secrets setup

## 1. Android local properties

Add this line to `android/local.properties`:

```properties
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
```

This key is used by the Android manifest for Google Maps.

## 2. Dart defines

Create a file named `dart_defines.json` at the project root by copying `dart_defines.example.json`.

Example:

```json
{
  "GOOGLE_MAPS_API_KEY": "your-google-maps-api-key"
}
```

## 3. Run command

Use:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

## Notes

- `GOOGLE_MAPS_API_KEY` is used by Dart services for Places/routing and by Android for map rendering.
- The chatbot uses Gemini through Firebase AI Logic, configured by the Firebase project files.
- `firebase_options.dart` was not changed here because Firebase client config is not treated like a server secret.
