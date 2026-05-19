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
  "OPENAI_API_KEY": "your-openai-api-key",
  "GOOGLE_MAPS_API_KEY": "your-google-maps-api-key"
}
```

## 3. Run command

Use:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

## Notes

- `OPENAI_API_KEY` is used by the chatbot service.
- `GOOGLE_MAPS_API_KEY` is used by Dart services for Places/routing and by Android for map rendering.
- `firebase_options.dart` was not changed here because Firebase client config is not treated like a server secret.
