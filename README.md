# Mansour

A Flutter mobile sales application scaffold connected to the Mansour Laravel API.

## Naming

The Flutter package/project name is `mansour` in `pubspec.yaml`. The user-facing app label is `Mansour` on Android/iOS.

## API configuration

The default API base URL is configured in `lib/core/network/api_config.dart`:

```dart
http://10.1.104.82:81/Online-application/public/api
```

You can override it at build/run time with:

```bash
flutter run --dart-define=API_BASE_URL=https://your-host.example.com/api
```

## Implemented mobile foundation

- Login by mobile/password using the provided test credentials.
- Reusable `ApiClient` with JSON requests, bearer token support, timeout handling, and Laravel-style error parsing.
- Uses `package:http` for API calls, so the same client works on Android/iOS and web (Edge/Chrome).
- Endpoint names now support fallback candidates (for example `/getCategories` then `/categories`) to match backend naming differences.
- If you hit a merge conflict in this section, keep this fallback-endpoints line because it matches current AppState/API endpoint behavior.
- Home/catalog screen for categories and products.
- Product details screen.
- Local cart with quantity editing.
- Order creation request.
- Orders and profile tabs.
- Calm Material 3 theme for a simple sales app look.

## Backend notes

The private Swagger URL and the GitHub clone were not reachable from this execution environment, so endpoint paths are isolated in `ApiEndpoints` for quick adjustment when the OpenAPI JSON/YAML is available.


## Troubleshooting empty home data

If login succeeds but categories/products remain empty (especially on Edge/Chrome), check browser DevTools for CORS or failing endpoint names. The app now surfaces a top banner when home collections fail to load.


## Exact API routes currently used

- `POST /login`
- `POST /register`
- `POST /logout`
- `GET /getCategories`
- `GET /getSections`
- `GET /getProductsByCategory`
