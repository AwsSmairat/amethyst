# amethyst

A new Flutter project.

## Getting Started

### API base URL (production + overrides)

The app uses **`API_BASE_URL`** for all HTTP calls (login, dashboards, products, sales, expenses, loads, etc.). It resolves to a single value via `ApiConfig.resolvedBaseUrl` and `DioClient`.

#### Production (Render)

The **default** base URL is the deployed backend on Render:

`https://YOUR-RENDER-URL.onrender.com/api`

Replace `YOUR-RENDER-URL` with your Render service hostname in `lib/core/config/api_config.dart` (`_productionDefault`), **or** pass a full URL at build/run time (recommended for CI):

```bash
flutter build apk --dart-define=API_BASE_URL=https://your-service.onrender.com/api
```

No backend code changes are required; only the Flutter `API_BASE_URL` must point at your live API (must include the `/api` suffix if that is how your server is mounted).

#### Override for local / staging / tests

`--dart-define` always overrides the compile-time default:

```bash
flutter run --dart-define=API_BASE_URL=https://your-service.onrender.com/api
```

#### Local development (optional)

Use your machine’s LAN IP or the Android emulator loopback as needed:

```bash
# Android emulator → host machine
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api
```

```bash
# Real phone, same Wi‑Fi as laptop
flutter run --dart-define=API_BASE_URL=http://192.168.1.8:4000/api
```

#### Tunnel (optional)

```bash
flutter run --dart-define=API_BASE_URL=https://your-tunnel.example.com/api
```

#### Startup validation

If `API_BASE_URL` is empty, not a valid `http`/`https` URL, or still contains the `YOUR-RENDER-URL` template, the app shows a configuration screen with details instead of connecting.

### Common mistakes

- Leaving `YOUR-RENDER-URL` in the default without replacing it or passing `--dart-define`.
- Using `localhost` on a real phone (it points to the phone itself).
- Using an old tunnel URL after the tunnel restarts.
- Backend listening only on `127.0.0.1` instead of `0.0.0.0` (local dev).
- Firewall blocking the backend port (local dev).

### Troubleshooting

#### Same Wi‑Fi issues (LAN)

- Confirm phone and laptop are on the same Wi‑Fi.
- Test from the phone browser: `http://<LAN-IP>:4000/health` (or your backend health URL).
- Ensure the backend binds `0.0.0.0` and the port is open.

#### Different network / production

- Prefer **HTTPS** (e.g. Render URL).
- If you change the deployed URL, rebuild the app or pass a new `--dart-define=API_BASE_URL=...`.

#### Backend not reachable

- Confirm the URL opens in the device browser.
- Check TLS/certificate issues for custom domains.

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
