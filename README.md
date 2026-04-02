# amethyst

A new Flutter project.

## Getting Started

### API_BASE_URL configuration (emulator / Wi‑Fi / remote)

This app **does not** rely on `localhost` or hardcoded LAN IPs. You must provide the backend URL via `--dart-define=API_BASE_URL=...`.

#### Required

If `API_BASE_URL` is missing, the app will show a startup screen telling you how to run/build with it.

#### Android emulator

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api
```

#### Real phone on the same Wi‑Fi (backend on your laptop)

1) Find your laptop LAN IP (example: `192.168.1.8`)  
2) Ensure backend listens on `0.0.0.0` and your firewall allows the port

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.8:4000/api
```

Or build an APK:

```bash
flutter build apk --dart-define=API_BASE_URL=http://192.168.1.8:4000/api
```

#### Different networks (ngrok / tunnel)

Expose your local backend via a tunnel and use the public HTTPS URL:

```bash
flutter run --dart-define=API_BASE_URL=https://your-ngrok-url.ngrok-free.app/api
flutter build apk --dart-define=API_BASE_URL=https://your-ngrok-url.ngrok-free.app/api
```

#### Public backend (production)

```bash
flutter build apk --dart-define=API_BASE_URL=https://my-api-url.com/api
```

### Common mistakes

- Using `localhost` on a real phone (it points to the phone itself).
- Using an old ngrok/tunnel URL after restarting the tunnel.
- Backend listening only on `127.0.0.1` instead of `0.0.0.0`.
- Firewall blocking the backend port.

### Troubleshooting

#### Same Wi‑Fi issues (LAN)
- Confirm phone + laptop are on the same Wi‑Fi.
- Test from the phone browser: `http://<LAN-IP>:4000/health` (or your backend health URL).
- Ensure backend binds `0.0.0.0` and port is open.

#### Different network issues (ngrok/public)
- Use the **HTTPS** tunnel URL and keep the `/api` suffix.
- If the tunnel URL changes, rebuild/re-run with the new `API_BASE_URL`.
- If you get TLS/handshake errors, confirm the URL is reachable in the phone browser.

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
