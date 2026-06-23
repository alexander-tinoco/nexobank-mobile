# Planeación — NexoBank Mobile

**Proyecto:** NexoBank · App móvil Flutter (iOS + Android)
**Backend:** `nexobank-backend` (FastAPI + PostgreSQL + Redis) — ya construido y documentado.
**Objetivo:** cliente móvil que consume la API `/api/v1/` del backend con una UX de app bancaria real.

---

## 1. Stack tecnológico

| Componente | Tecnología | Motivo |
|---|---|---|
| Framework | Flutter 3.x (Dart 3+) | Un solo codebase para iOS y Android |
| Estado | Riverpod 2 (AsyncNotifier) | Async nativo, sin boilerplate, testeable |
| Navegación | GoRouter | Declarativo, soporta deep links y guards |
| HTTP | Dio 5 | Interceptores, timeout, cancelación, logging |
| Almacenamiento seguro | flutter_secure_storage | Keychain (iOS) / Keystore (Android) para tokens |
| Almacenamiento local | Hive o Isar | Caché offline de cuentas y transacciones |
| WebSocket | dart:io WebSocket o web_socket_channel | Notificaciones en tiempo real |
| Inyección de dependencias | Riverpod providers | Sin librerías adicionales de DI |
| Internacionalización | flutter_localizations + intl | Soporte español MX desde el inicio |
| Formateo de dinero | intl `NumberFormat.currency` + paquete `decimal` | Nunca `double` para dinero |
| Tests | flutter_test + mockito / mocktail | Unit, widget e integration tests |
| Lint | flutter_lints + reglas custom | Cero warnings antes de cada commit |

---

## 2. Arquitectura

### Feature-first con capas internas

```
lib/
├── core/
│   ├── network/
│   │   ├── dio_client.dart          # instancia Dio + interceptores
│   │   ├── auth_interceptor.dart    # adjunta Bearer, renueva token, redirige en 401
│   │   ├── error_interceptor.dart   # traduce {"error_code","message"} → AppError
│   │   └── logging_interceptor.dart # solo en debug, sin campos sensibles
│   ├── errors/
│   │   ├── app_error.dart           # tipos de error de dominio
│   │   └── result.dart              # Result<T, AppError>
│   ├── storage/
│   │   └── secure_storage.dart      # wrapper de flutter_secure_storage
│   ├── config/
│   │   └── app_config.dart          # baseUrl y constantes desde --dart-define
│   ├── router/
│   │   └── app_router.dart          # GoRouter con guards de auth
│   └── theme/
│       └── app_theme.dart           # Material 3 con paleta NexoBank
│
└── features/
    ├── auth/
    ├── accounts/
    ├── cards/
    ├── transfers/
    ├── transactions/
    └── notifications/
```

### Capas dentro de cada feature

```
features/<name>/
├── data/
│   ├── dtos/            # mapea exactamente el JSON de la API
│   └── <name>_repository_impl.dart   # implementación con DioClient
├── domain/
│   ├── models/          # modelo de dominio (puede diferir del DTO)
│   └── <name>_repository.dart        # interfaz abstracta
└── presentation/
    ├── screens/
    ├── widgets/
    └── providers/       # AsyncNotifier / Notifier de Riverpod
```

### Flujo de datos

```
Screen → (observe) → AsyncNotifier → (call) → Repository (interface)
                                                      │
                                              RepositoryImpl
                                                      │
                                               DioClient → API
```

---

## 3. Pantallas y flujos

### Autenticación

| Pantalla | Endpoints que consume |
|---|---|
| Splash / verificar sesión | — (lee secure storage) |
| Login | `POST /auth/login` |
| Registro | `POST /auth/register` |
| Forgot password | `POST /auth/forgot-password` |
| Reset password | `POST /auth/reset-password` |

### Home / Dashboard

| Pantalla | Endpoints que consume |
|---|---|
| Dashboard (resumen de cuentas) | `GET /accounts` |
| Detalle de cuenta | `GET /accounts/{id}` |
| Historial de transacciones | `GET /accounts/{id}/transactions` (paginación cursor) |

### Tarjetas

| Pantalla | Endpoints que consume |
|---|---|
| Lista de tarjetas de una cuenta | `GET /accounts/{id}/cards` |
| Detalle de tarjeta | — (datos ya en la lista) |
| Congelar / descongelar | `PATCH /cards/{id}/freeze` |

### Transferencias

| Pantalla | Endpoints que consume |
|---|---|
| Formulario de transferencia | — |
| Confirmación (monto + cuenta destino) | — |
| Resultado (éxito / error) | `POST /transfers` |

Flujo obligatorio: formulario → pantalla de confirmación → llamada a la API → resultado. El botón de envío se deshabilita mientras la petición está en vuelo para evitar doble submit.

La `idempotency_key` se genera con `uuid v4` al entrar a la pantalla de confirmación, no al presionar el botón.

### Notificaciones

| Pantalla | Endpoints que consume |
|---|---|
| Centro de notificaciones | WebSocket `WS /ws/notifications` |
| Registro de device token | `POST /device-tokens` |

### Perfil

| Pantalla | Endpoints que consume |
|---|---|
| Ver perfil | `GET /users/me` |
| Editar nombre / teléfono | `PATCH /users/me` |
| Logout | `POST /auth/logout` + limpiar secure storage |

---

## 4. Gestión de sesión y tokens

```
App startup
  │
  ├── Leer access_token de flutter_secure_storage
  │     ├── token presente y válido → HomeScreen
  │     ├── token expirado + refresh presente → renovar silenciosamente → HomeScreen
  │     └── sin tokens → LoginScreen
  │
AuthInterceptor (en cada petición)
  │
  ├── Adjuntar Authorization: Bearer <access_token>
  ├── Si 401:
  │     ├── Llamar POST /auth/refresh con el refresh token
  │     │     ├── OK → guardar nuevos tokens, reintentar petición original
  │     │     └── Error (401/403) → logout forzado → LoginScreen
  │     └── Si el endpoint es /auth/refresh → logout forzado (evitar loop)
  └── Continuar con la respuesta
```

---

## 5. Manejo de errores de API

El backend devuelve siempre:
```json
{ "error_code": "INSUFFICIENT_FUNDS", "message": "...", "request_id": "..." }
```

El `ErrorInterceptor` de Dio mapea esto a:

```dart
sealed class AppError {
  const AppError();
}
class InsufficientFundsError extends AppError { ... }
class AccountNotFoundError extends AppError { ... }
class UnauthorizedError extends AppError { ... }
class NetworkError extends AppError { ... }
class UnknownError extends AppError { ... }
```

Los providers exponen `AsyncValue<T>` de Riverpod. Los widgets leen `.when(data:, loading:, error:)` y muestran el mensaje correcto según el tipo de `AppError`.

---

## 6. WebSocket — notificaciones en tiempo real

Al entrar a la app (usuario autenticado), conectar al WebSocket:

```
WS /api/v1/ws/notifications
Headers: Authorization: Bearer <access_token>
```

El provider de notificaciones escucha el stream y:
- Muestra un badge en el ícono de campana.
- Dispara un `SnackBar` con el evento (ej. "Transferencia recibida: MXN 500.00").
- Reconecta automáticamente con backoff exponencial si se pierde la conexión.

Al hacer `POST /device-tokens` con el FCM/APNs token al iniciar sesión para habilitar push notifications cuando la app está en background.

---

## 7. Offline y caché

La app debe funcionar en modo lectura sin conexión:

- Caché de la lista de cuentas y las últimas 20 transacciones por cuenta (Hive o Isar).
- Mostrar un banner "Sin conexión — mostrando datos guardados" cuando `DioError` es de tipo `connectionTimeout` / `receiveTimeout`.
- Transferencias y operaciones de escritura: bloquear con mensaje "Sin conexión. Por favor intenta más tarde."

---

## 8. Internacionalización

- Idioma base: español (México) — `es_MX`.
- Formato de moneda: `MXN 1,500.00` (via `NumberFormat.currency`).
- Formato de fechas: `dd/MM/yyyy HH:mm` en listas, `dd de MMMM de yyyy` en detalles.
- Todas las cadenas de texto en archivos `.arb` desde el inicio (no strings literales en widgets).

---

## 9. Fases de desarrollo

### Fase 1 — Fundación (1 sprint, bloqueante)

Debe terminarse antes de arrancar las features en paralelo.

| Entregable | Descripción |
|---|---|
| Setup Flutter + estructura de carpetas | `flutter create`, limpiar boilerplate, crear carpetas de `core/` y `features/` |
| `analysis_options.yaml` | Reglas strict de Dart + flutter_lints |
| `DioClient` + interceptores | `AuthInterceptor`, `ErrorInterceptor`, `LoggingInterceptor` |
| `AppError` + `Result<T, E>` | Tipos de error tipados |
| `SecureStorage` wrapper | Lectura/escritura de tokens con `flutter_secure_storage` |
| `AppRouter` (GoRouter) | Rutas, guards de auth, rutas anónimas vs. autenticadas |
| `AppTheme` | Material 3, paleta de colores NexoBank |
| `AppConfig` | `baseUrl` via `--dart-define`, constantes de configuración |
| `pubspec.yaml` completo | Todas las dependencias declaradas |
| CI mínima (GitHub Actions) | `flutter analyze` + `flutter test` en cada push |

### Fase 2 — Features en paralelo (arrancar todos a la vez)

#### Feature A — Auth
- Pantallas: Splash, Login, Registro, Forgot Password, Reset Password
- Provider: `AuthNotifier` (login, register, logout, refresh)
- Repository: `AuthRepository` → `POST /auth/*`
- Tests: unit del notifier + widget tests de Login

#### Feature B — Accounts & Cards
- Pantallas: Dashboard, Detalle de cuenta, Lista de tarjetas, Detalle de tarjeta
- Providers: `AccountsNotifier`, `AccountDetailNotifier`, `CardsNotifier`
- Repository: `AccountRepository`, `CardRepository`
- Tests: unit de providers + mock de repositorio

#### Feature C — Transfers & Transactions
- Pantallas: Formulario de transferencia, Confirmación, Resultado, Historial
- Providers: `TransferNotifier`, `TransactionsNotifier` (paginación cursor)
- Repository: `TransferRepository`, `TransactionRepository`
- Tests: unit del flujo de transferencia (happy path + `INSUFFICIENT_FUNDS` + idempotencia)

#### Feature D — Notifications & Profile
- WebSocket provider con reconexión automática
- Pantallas: Centro de notificaciones, Perfil, Editar perfil
- `POST /device-tokens` al login
- Tests: mock del WebSocket stream

### Fase 3 — Integración y pulido

| Tarea | Descripción |
|---|---|
| Integración end-to-end | Probar flujos completos contra el backend real en Docker |
| Caché offline | Implementar Hive/Isar + banner de desconexión |
| Manejo de errores UI | Revisar todos los estados de error y vacío de cada pantalla |
| Accesibilidad | `Semantics` en elementos clave, contraste de colores, tamaño de texto |
| Golden tests | Capturas de pantalla de los flows principales para regresión visual |
| README del repo | Setup, cómo correr localmente, cómo conectar al backend |

---

## 10. Variables de entorno

Se pasan con `--dart-define` (nunca hardcodeadas, nunca en `.env` commiteado):

| Variable | Ejemplo | Descripción |
|---|---|---|
| `API_BASE_URL` | `http://localhost:8000/api/v1` | URL del backend |
| `WS_BASE_URL` | `ws://localhost:8000/api/v1` | URL del WebSocket |
| `ENVIRONMENT` | `development` | `development` / `production` |

Ejemplo de ejecución:
```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 \
  --dart-define=WS_BASE_URL=ws://10.0.2.2:8000/api/v1 \
  --dart-define=ENVIRONMENT=development
```

> **Nota para emulador Android:** usar `10.0.2.2` en vez de `localhost` para llegar al host.

---

## 11. Criterios de aceptación de esta fase

- La app levanta con un solo comando (`flutter run`) apuntando al backend local.
- Un usuario puede registrarse, hacer login, ver sus cuentas, hacer una transferencia exitosa y ver el movimiento en el historial — todo sin errores en consola.
- Los tokens se guardan en `flutter_secure_storage` y la sesión persiste al cerrar la app.
- Un refresh token expirado redirige al login sin crash.
- `flutter analyze` y `flutter test` pasan en CI (GitHub Actions).
- Las pantallas de error muestran mensajes útiles (no stack traces ni códigos HTTP crudos).
