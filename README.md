# NexoBank Mobile

App móvil bancaria Flutter (iOS + Android) que consume la API REST de NexoBank.

## Requisitos

- Flutter 3.x (Dart 3+)
- Android SDK / Xcode (para simuladores)
- Backend `nexobank-backend` corriendo localmente

## Cómo ejecutar

### Android (emulador)
```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 \
  --dart-define=WS_BASE_URL=ws://10.0.2.2:8000/api/v1 \
  --dart-define=ENVIRONMENT=development
```

### iOS (simulador)
```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8000/api/v1 \
  --dart-define=WS_BASE_URL=ws://localhost:8000/api/v1 \
  --dart-define=ENVIRONMENT=development
```

## Levantar el backend

Ver instrucciones en el repo `nexobank-backend`. Con Docker:
```bash
docker compose up
```

## Tests

```bash
flutter analyze   # debe pasar con 0 issues
flutter test      # todos los tests deben pasar
```

## Arquitectura

Feature-first con capas internas: `presentation/` → `providers/` → `repositories/` → `data/`.

```
lib/
├── core/
│   ├── config/       # AppConfig — baseUrl vía --dart-define
│   ├── errors/       # AppError (sealed), Result<T>
│   ├── network/      # DioClient + AuthInterceptor + ErrorInterceptor + LoggingInterceptor
│   ├── router/       # AppRouter (GoRouter + guard) + AppShell (BottomNavigationBar)
│   ├── storage/      # SecureStorage (flutter_secure_storage)
│   ├── theme/        # AppTheme + AppColors (paleta NexoBank)
│   └── widgets/      # OfflineBanner
└── features/
    ├── auth/         # Login, Register, ForgotPassword, SplashScreen
    ├── accounts/     # HomeScreen, AccountDetailScreen, BalanceDisplayWidget
    ├── cards/        # CardWidget, congelar/descongelar
    ├── transfers/    # TransferForm → Confirm → Result (con idempotency_key)
    ├── transactions/ # Historial con paginación por cursor
    ├── notifications/ # WebSocket + NotificationCenter + badge
    └── profile/      # ProfileScreen, EditProfileScreen
```

- **Estado:** Riverpod (`AsyncNotifier` / `Notifier`)
- **Navegación:** GoRouter con guard de auth (redirige a `/login` sin token)
- **HTTP:** Dio con `AuthInterceptor` (renovación silenciosa de token), `ErrorInterceptor` (`error_code` → `AppError`)
- **Tokens:** exclusivamente en `flutter_secure_storage` (nunca `SharedPreferences`)
- **Dinero:** `String` de la API → `Decimal` → `NumberFormat.currency` (nunca `double`)

## Variables de entorno (--dart-define)

| Variable | Ejemplo | Descripción |
|---|---|---|
| `API_BASE_URL` | `http://10.0.2.2:8000/api/v1` | URL base del backend |
| `WS_BASE_URL` | `ws://10.0.2.2:8000/api/v1` | URL WebSocket para notificaciones |
| `ENVIRONMENT` | `development` | `development` o `production` |

> **Nota para emulador Android:** usar `10.0.2.2` en vez de `localhost` para alcanzar el host.
