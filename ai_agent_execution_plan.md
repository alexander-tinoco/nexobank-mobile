# Plan de Ejecución con Agentes de IA — NexoBank Mobile

**Fecha:** 2026-06-23  
**Modelo:** Claude Sonnet 4.6 (claude-sonnet-4-6) vía Claude Code CLI  
**Stack:** Flutter 3.x · Riverpod 2 · GoRouter · Dio 5  
**Backend:** nexobank-backend (FastAPI) — ya construido.

---

## Identidad visual (del logo)

| Token | Hex | Uso en la app |
|---|---|---|
| `colorPrimary` | `#08102A` | Fondo oscuro, AppBar, Drawer |
| `colorBrand` | `#10C4FF` | Gradiente del logo, CTAs primarios |
| `colorBrandDeep` | `#1E3A8A` | Gradiente inicio, estados activos |
| `colorAccent` | `#1E3A8A` | Bordes de tarjetas, íconos secundarios |
| `colorTurquoise` | `#00B4D8` | Badges, tags de estado "activo" |
| `colorSurface` | `#F2F4F7` | Fondos de tarjetas, inputs |
| `colorOnPrimary` | `#FFFFFF` | Texto sobre fondos oscuros |

El logo es la letra **N** con degradado de `#1E3A8A` → `#10C4FF` → teal. La tipografía es sans-serif moderna, lowercase.

---

## Modelo mental: ¿qué es un "agente" aquí?

Cada agente es una **sesión de Claude Code con scope fijo**, corriendo sobre:
- Una rama de git dedicada (`feature/core`, `feature/auth`, etc.)
- Un prompt de entrada preciso (definido en este documento)
- Criterios de done verificables (`flutter analyze` + tests pasan)

Los agentes de la **Fase 2 corren en paralelo** — cada uno en su propia rama, sin tocarse. Al terminar, el agente integrador hace los merges.

```
Agente 0: Bootstrap ──────────────────────────────────── (bloqueante)
                    │
Agente 1: Core/Foundation ────────────────────────────── (bloqueante)
                    │
          ┌─────────┼──────────┬──────────────┐
   Agente A    Agente B    Agente C      Agente D       ← paralelo
   Auth      Accounts    Transfers   Notifications
          └─────────┼──────────┴──────────────┘
                    │
Agente 5: Integración ────────────────────────────────── (final)
                    │
Agente 6: QA / Pulido ────────────────────────────────── (final)
```

---

## Agente 0 — Bootstrap del proyecto

**Rama:** `main`  
**Bloqueante:** sí (todos los demás dependen de esto)  
**Duración estimada:** 1 sesión corta

### Qué hace

1. `flutter create nexobank_mobile --org com.nexobank --platforms ios,android`
2. Limpiar el boilerplate de `main.dart` y `widget_test.dart`.
3. Crear la estructura de carpetas vacía:
   ```
   lib/
   ├── core/
   │   ├── network/
   │   ├── errors/
   │   ├── storage/
   │   ├── config/
   │   ├── router/
   │   └── theme/
   └── features/
       ├── auth/
       ├── accounts/
       ├── cards/
       ├── transfers/
       ├── transactions/
       └── notifications/
   ```
4. Escribir `pubspec.yaml` completo con todas las dependencias.
5. Escribir `analysis_options.yaml` en modo strict.
6. Crear `.gitignore` adecuado (excluye `google-services.json`, `GoogleService-Info.plist`, `.env`).
7. Primer commit: `chore: scaffold proyecto Flutter con estructura feature-first`.

### pubspec.yaml — dependencias definitivas

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Estado
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  # Navegación
  go_router: ^14.2.0
  # HTTP
  dio: ^5.4.3
  # Almacenamiento seguro
  flutter_secure_storage: ^9.2.2
  # Caché local
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
  path_provider: ^2.1.3
  # Dinero
  decimal: ^2.3.3
  intl: ^0.19.0
  # WebSocket
  web_socket_channel: ^3.0.1
  # Localización
  flutter_localizations:
    sdk: flutter
  # IDs únicos (idempotency_key)
  uuid: ^4.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.9
  mockito: ^5.4.4
  mocktail: ^1.0.4
  isar_generator: ^3.1.0
```

### Prompt de entrada para este agente

```
Eres el agente Bootstrap de NexoBank Mobile. Tu único trabajo es:
1. Crear el proyecto Flutter en el directorio actual con `flutter create . --org com.nexobank --platforms ios,android`.
2. Reemplazar lib/main.dart con un main.dart mínimo que solo muestre un MaterialApp vacío.
3. Crear la estructura de carpetas de lib/ según el CLAUDE.md.
4. Escribir el pubspec.yaml con las dependencias listadas en ai_agent_execution_plan.md.
5. Escribir analysis_options.yaml en modo strict (include: package:flutter_lints/flutter.yaml + analyzer: strict-casts: true, strict-inference: true, strict-raw-types: true).
6. Crear .gitignore apropiado.
7. Correr `flutter pub get` y verificar que no hay errores.
8. Commit: "chore: scaffold proyecto Flutter con estructura feature-first".
No escribas ninguna lógica de negocio. Solo infraestructura inicial.
```

---

## Agente 1 — Core / Foundation

**Rama:** `feature/core`  
**Depende de:** Agente 0  
**Bloqueante:** sí (los agentes de Fase 2 importan de `core/`)

### Archivos que produce

| Archivo | Responsabilidad |
|---|---|
| `lib/core/config/app_config.dart` | `baseUrl` y `wsUrl` via `--dart-define` |
| `lib/core/errors/app_error.dart` | `sealed class AppError` con todos los casos del backend |
| `lib/core/errors/result.dart` | `typedef Result<T> = ...` usando package:result_dart o patrón propio |
| `lib/core/storage/secure_storage.dart` | Wrapper de `flutter_secure_storage` con métodos tipados |
| `lib/core/network/dio_client.dart` | Instancia Dio + registra los 3 interceptores |
| `lib/core/network/auth_interceptor.dart` | Bearer, refresh silencioso, logout en 401 |
| `lib/core/network/error_interceptor.dart` | `{"error_code","message","request_id"}` → `AppError` |
| `lib/core/network/logging_interceptor.dart` | Solo debug, redacta campos sensibles |
| `lib/core/router/app_router.dart` | GoRouter con guard de auth, rutas anónimas vs. autenticadas |
| `lib/core/theme/app_theme.dart` | Material 3 con paleta NexoBank + tema oscuro |
| `lib/core/theme/app_colors.dart` | Constantes de color del brand |
| `test/core/` | Tests unitarios de `SecureStorage`, `ErrorInterceptor`, `AppRouter` guard |

### Paleta en código (app_colors.dart)

```dart
abstract final class AppColors {
  static const Color primary    = Color(0xFF08102A); // Azul Profundo
  static const Color brand      = Color(0xFF10C4FF); // Azul Corporativo
  static const Color brandDeep  = Color(0xFF1E3A8A); // Azul Methoplus
  static const Color turquoise  = Color(0xFF00B4D8); // Turquesa
  static const Color surface    = Color(0xFFF2F4F7); // Gris Claro
  static const Color onPrimary  = Color(0xFFFFFFFF);

  // Gradiente del logo N
  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandDeep, brand, turquoise],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
```

### AppError — casos del backend

```dart
sealed class AppError {
  const AppError();
}
final class InsufficientFundsError extends AppError { const InsufficientFundsError(); }
final class AccountNotFoundError   extends AppError { const AccountNotFoundError(); }
final class CardFrozenError        extends AppError { const CardFrozenError(); }
final class UnauthorizedError      extends AppError { const UnauthorizedError(); }
final class SessionExpiredError    extends AppError { const SessionExpiredError(); }
final class NetworkError           extends AppError {
  const NetworkError(this.message);
  final String message;
}
final class UnknownError           extends AppError {
  const UnknownError(this.code, this.message);
  final String code;
  final String message;
}
```

### GoRouter — rutas y guard

```
/splash          → SplashScreen (sin guard)
/login           → LoginScreen  (anónima)
/register        → RegisterScreen (anónima)
/forgot-password → ForgotPasswordScreen (anónima)
/home            → HomeScreen   (autenticada)
/accounts/:id    → AccountDetailScreen (autenticada)
/cards/:id       → CardDetailScreen (autenticada)
/transfer        → TransferFormScreen (autenticada)
/transfer/confirm → TransferConfirmScreen (autenticada)
/transfer/result  → TransferResultScreen (autenticada)
/notifications   → NotificationCenterScreen (autenticada)
/profile         → ProfileScreen (autenticada)
/profile/edit    → EditProfileScreen (autenticada)
```

Guard: si el usuario no tiene `access_token` en `SecureStorage`, redirige a `/login`. Si está en ruta anónima con sesión activa, redirige a `/home`.

### Prompt de entrada para este agente

```
Eres el agente Core de NexoBank Mobile. El proyecto Flutter ya existe con su estructura de carpetas.
Tu trabajo es implementar toda la capa core/ descrita en ai_agent_execution_plan.md:
- AppConfig (dart-define)
- AppColors con la paleta: #08102A, #10C4FF, #1E3A8A, #00B4D8, #F2F4F7
- AppTheme (Material 3, tema claro y oscuro, usando AppColors)
- AppError (sealed class con los casos listados)
- Result<T> typedef
- SecureStorage wrapper
- DioClient con AuthInterceptor, ErrorInterceptor, LoggingInterceptor
- AppRouter con guard de autenticación y todas las rutas listadas

Reglas no negociables (del CLAUDE.md):
- Tokens SOLO en flutter_secure_storage, nunca SharedPreferences.
- AuthInterceptor renueva access_token silenciosamente con el refresh_token.
- ErrorInterceptor mapea {"error_code","message","request_id"} → AppError tipado.
- LoggingInterceptor en debug, sin loguear Authorization ni password.
- baseUrl via --dart-define=API_BASE_URL, nunca hardcodeada.

Escribe tests unitarios para: SecureStorage (mock del plugin), ErrorInterceptor (casos de cada error_code), AppRouter guard (redirige sin token, permite acceso con token).
Al terminar: `flutter analyze` debe pasar sin warnings.
```

---

## Agente A — Feature: Auth

**Rama:** `feature/auth`  
**Base:** merge de `feature/core`  
**Paralelo con:** B, C, D

### Archivos que produce

```
lib/features/auth/
├── data/
│   ├── dtos/
│   │   ├── login_request_dto.dart
│   │   ├── login_response_dto.dart
│   │   ├── register_request_dto.dart
│   │   └── register_response_dto.dart
│   └── auth_repository_impl.dart
├── domain/
│   ├── models/
│   │   └── auth_user.dart
│   └── auth_repository.dart
└── presentation/
    ├── screens/
    │   ├── splash_screen.dart
    │   ├── login_screen.dart
    │   ├── register_screen.dart
    │   ├── forgot_password_screen.dart
    │   └── reset_password_screen.dart
    ├── widgets/
    │   ├── nexo_text_field.dart   (campo reutilizable con estilo brand)
    │   └── nexo_primary_button.dart
    └── providers/
        └── auth_notifier.dart     (AsyncNotifier)
```

### Endpoints que consume

| Método | Ruta | DTO request | DTO response |
|---|---|---|---|
| POST | `/auth/login` | `LoginRequestDto` | `LoginResponseDto` |
| POST | `/auth/register` | `RegisterRequestDto` | `RegisterResponseDto` |
| POST | `/auth/refresh` | — (refresh_token del storage) | `LoginResponseDto` |
| POST | `/auth/logout` | — (access_token via interceptor) | 204 |
| POST | `/auth/forgot-password` | `{email}` | 200 |
| POST | `/auth/reset-password` | `{token, new_password}` | 200 |

### AuthNotifier — estados

```
state: AsyncValue<AuthUser?>
métodos:
  login(email, password) → guarda tokens, emite AuthUser
  register(name, email, password) → igual
  logout() → llama /auth/logout + borra tokens + emite null
  checkSession() → lee storage, valida token, emite AuthUser o null
```

### UI de Login

- Fondo: `AppColors.primary` (`#08102A`)
- Logo centrado con gradiente brand
- Campo email + campo contraseña con `NexoTextField`
- Botón "Iniciar sesión" con gradiente brand
- Link "¿Olvidaste tu contraseña?"
- Link "Crear cuenta"
- Estado de carga: deshabilita el botón y muestra `CircularProgressIndicator` en el botón
- Estado de error: `SnackBar` con mensaje del `AppError`

### Tests requeridos

- `AuthNotifier`: login exitoso, login con credenciales inválidas (`UnauthorizedError`), logout limpia storage
- `AuthRepositoryImpl`: mock de DioClient, verifica que guarda tokens en SecureStorage
- Widget test de `LoginScreen`: muestra error en pantalla cuando el notifier falla

### Prompt de entrada para este agente

```
Eres el agente Auth de NexoBank Mobile. El core/ ya está implementado (DioClient, AppError, SecureStorage, AppRouter, AppTheme).
Tu trabajo es implementar la feature `auth` completa:
- DTOs para login, register, refresh, logout, forgot-password, reset-password
- AuthRepository (interfaz) y AuthRepositoryImpl (usa DioClient, guarda tokens en SecureStorage)
- AuthNotifier (AsyncNotifier de Riverpod) con métodos: login, register, logout, checkSession
- Pantallas: SplashScreen, LoginScreen, RegisterScreen, ForgotPasswordScreen, ResetPasswordScreen
- Widgets reutilizables: NexoTextField, NexoPrimaryButton (con paleta de AppColors)

Restricciones críticas:
- Tokens SOLO en SecureStorage (jamás SharedPreferences).
- El AuthInterceptor ya renueva el token; AuthRepositoryImpl no debe manejar refresh.
- Al logout: primero POST /auth/logout, luego limpiar storage.
- SplashScreen llama checkSession() y navega a /home o /login según resultado.
- LoginScreen deshabilita el botón mientras la petición está en vuelo.

Escribe tests: AuthNotifier (3 casos mínimo), AuthRepositoryImpl (mock de Dio), LoginScreen widget test.
`flutter analyze` sin warnings al terminar.
```

---

## Agente B — Feature: Accounts & Cards

**Rama:** `feature/accounts-cards`  
**Base:** merge de `feature/core`  
**Paralelo con:** A, C, D

### Archivos que produce

```
lib/features/accounts/
├── data/dtos/ → account_dto.dart, account_list_dto.dart
├── data/      → account_repository_impl.dart
├── domain/    → account.dart (model), account_repository.dart
└── presentation/
    ├── screens/ → home_screen.dart, account_detail_screen.dart
    ├── widgets/ → account_card_widget.dart, balance_display_widget.dart
    └── providers/ → accounts_notifier.dart, account_detail_notifier.dart

lib/features/cards/
├── data/dtos/ → card_dto.dart
├── data/      → card_repository_impl.dart
├── domain/    → card.dart (model), card_repository.dart
└── presentation/
    ├── screens/ → cards_list_screen.dart, card_detail_screen.dart
    ├── widgets/ → card_widget.dart (visual de tarjeta bancaria)
    └── providers/ → cards_notifier.dart
```

### Endpoints que consume

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/accounts` | Lista de cuentas del usuario |
| GET | `/accounts/{id}` | Detalle de una cuenta |
| GET | `/accounts/{id}/cards` | Tarjetas de una cuenta |
| PATCH | `/cards/{id}/freeze` | Congelar/descongelar tarjeta |

### Regla de seguridad crítica

Antes de `AccountDetailScreen`, verificar que el `accountId` del parámetro de ruta pertenece al usuario autenticado (comparar contra la lista en el notifier). Si no coincide: navegar a `/home` sin mostrar datos.

### Balance display

- Mostrar saldo con `NumberFormat.currency(locale: 'es_MX', symbol: 'MXN ')`
- El `String` de la API (`"1500.00"`) se parsea a `Decimal` solo para formatear
- Nunca `double.parse`

### Card widget visual

- Tarjeta con fondo gradiente brand (`#1E3A8A` → `#10C4FF`)
- Número de tarjeta enmascarado: `**** **** **** 1234`
- Badge de estado: "ACTIVA" (turquesa) / "CONGELADA" (gris)
- Botón de congelar/descongelar con confirmación modal

### Prompt de entrada para este agente

```
Eres el agente Accounts & Cards de NexoBank Mobile. El core/ ya está listo.
Tu trabajo es implementar las features `accounts` y `cards`:

Accounts:
- AccountDto (mapea exactamente el JSON de /accounts y /accounts/{id})
- AccountRepositoryImpl (GET /accounts, GET /accounts/{id})
- AccountsNotifier (lista de cuentas), AccountDetailNotifier (una cuenta)
- HomeScreen: muestra lista de AccountCardWidget con saldo formateado
- AccountDetailScreen: detalle + acceso a tarjetas y transacciones

Cards:
- CardDto (mapea /accounts/{id}/cards)
- CardRepositoryImpl (GET /accounts/{id}/cards, PATCH /cards/{id}/freeze)
- CardsNotifier
- CardWidget visual con gradiente brand (#1E3A8A → #10C4FF), número enmascarado, badge de estado
- Confirmación modal antes de congelar/descongelar

Reglas:
- Saldo: String de la API → Decimal → NumberFormat.currency(locale: 'es_MX'). NUNCA double.
- Verificar que accountId pertenece al usuario antes de mostrar AccountDetailScreen.
- Nunca loguear números de tarjeta.

Tests: AccountsNotifier, AccountDetailNotifier, CardRepositoryImpl (mock Dio), CardWidget (estado congelado vs activo).
```

---

## Agente C — Feature: Transfers & Transactions

**Rama:** `feature/transfers-transactions`  
**Base:** merge de `feature/core`  
**Paralelo con:** A, B, D

### Archivos que produce

```
lib/features/transfers/
├── data/dtos/ → transfer_request_dto.dart, transfer_response_dto.dart
├── data/      → transfer_repository_impl.dart
├── domain/    → transfer.dart, transfer_repository.dart
└── presentation/
    ├── screens/
    │   ├── transfer_form_screen.dart
    │   ├── transfer_confirm_screen.dart   ← idempotency_key se genera aquí
    │   └── transfer_result_screen.dart
    ├── widgets/ → amount_input_widget.dart, account_selector_widget.dart
    └── providers/ → transfer_notifier.dart

lib/features/transactions/
├── data/dtos/ → transaction_dto.dart, transaction_page_dto.dart
├── data/      → transaction_repository_impl.dart
├── domain/    → transaction.dart, transaction_repository.dart
└── presentation/
    ├── screens/ → transaction_history_screen.dart
    ├── widgets/ → transaction_item_widget.dart
    └── providers/ → transactions_notifier.dart   (paginación cursor)
```

### Endpoints que consume

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/transfers` | Ejecutar transferencia |
| GET | `/accounts/{id}/transactions` | Historial con cursor pagination |

### Flujo de transferencia (obligatorio)

```
TransferFormScreen
  │  (usuario llena monto + cuenta destino)
  ▼
TransferConfirmScreen
  │  ← idempotency_key = uuid.v4() se genera AL ENTRAR a esta pantalla
  │  Muestra: monto formateado, cuenta destino, comisión
  │  Botón "Confirmar" (se deshabilita durante la petición)
  ▼
TransferNotifier.execute(dto con idempotency_key)
  │
POST /transfers
  ├── 200 OK → TransferResultScreen (éxito)
  └── Error → TransferResultScreen (error con mensaje tipado)
      INSUFFICIENT_FUNDS → "Saldo insuficiente"
      ACCOUNT_NOT_FOUND  → "Cuenta destino no encontrada"
```

**Nunca reutilizar la misma `idempotency_key` en dos intentos distintos.** Si el usuario vuelve atrás y reintenta, se navega de nuevo a `TransferConfirmScreen` y se genera una nueva key.

### Paginación de transacciones

- Paginación por cursor (no por página).
- `TransactionsNotifier` expone `fetchNextPage(cursor)`.
- La pantalla usa `ListView.builder` con un listener al scroll para cargar más.
- Estado inicial: primera página al abrir `AccountDetailScreen`.

### Prompt de entrada para este agente

```
Eres el agente Transfers & Transactions de NexoBank Mobile. El core/ ya está listo.
Tu trabajo es implementar las features `transfers` y `transactions`:

Transfers:
- TransferRequestDto (monto como String, cuenta_destino_id, idempotency_key)
- TransferRepositoryImpl (POST /transfers)
- TransferNotifier (estados: idle, loading, success, error tipado)
- TransferFormScreen → TransferConfirmScreen → TransferResultScreen
- CRÍTICO: idempotency_key = uuid.v4() se genera al entrar a TransferConfirmScreen, no al presionar Confirmar.
- El botón Confirmar se deshabilita durante la petición (estado loading).
- Nunca reutilizar la key si el usuario navega atrás y reintenta.

Transactions:
- TransactionDto + paginación por cursor
- TransactionsNotifier con fetchNextPage
- TransactionHistoryScreen con ListView lazy + infinite scroll

Reglas:
- Monto: String de la API, formatear con NumberFormat.currency(locale: 'es_MX'). NUNCA double.
- Pantalla de confirmación muestra monto + cuenta destino antes de enviar.
- Manejar INSUFFICIENT_FUNDS, ACCOUNT_NOT_FOUND con mensajes legibles.

Tests: TransferNotifier (happy path, INSUFFICIENT_FUNDS, doble submit bloqueado), TransferRepositoryImpl (mock Dio con idempotency_key), TransactionsNotifier (paginación: página 1, página 2, fin de resultados).
```

---

## Agente D — Feature: Notifications & Profile

**Rama:** `feature/notifications-profile`  
**Base:** merge de `feature/core`  
**Paralelo con:** A, B, C**

### Archivos que produce

```
lib/features/notifications/
├── data/dtos/  → notification_dto.dart
├── data/       → notification_repository_impl.dart
├── domain/     → notification.dart, notification_repository.dart
└── presentation/
    ├── screens/  → notification_center_screen.dart
    ├── widgets/  → notification_item_widget.dart, notification_badge_widget.dart
    └── providers/ → notifications_notifier.dart  (WebSocket stream)

lib/features/profile/
├── data/dtos/  → user_dto.dart, update_profile_request_dto.dart
├── data/       → profile_repository_impl.dart
├── domain/     → user.dart, profile_repository.dart
└── presentation/
    ├── screens/  → profile_screen.dart, edit_profile_screen.dart
    ├── widgets/  → profile_avatar_widget.dart
    └── providers/ → profile_notifier.dart
```

### Endpoints que consume

| Método | Ruta | Descripción |
|---|---|---|
| WS | `/ws/notifications` | Stream de notificaciones en tiempo real |
| POST | `/device-tokens` | Registrar token FCM/APNs al login |
| GET | `/users/me` | Datos del usuario autenticado |
| PATCH | `/users/me` | Actualizar nombre / teléfono |

### WebSocket — comportamiento del provider

```
NotificationsNotifier (extiende AsyncNotifier)
  ├── Al construirse: conectar WS con Bearer token
  ├── Escuchar stream: agregar notificación a la lista, incrementar badge
  ├── Reconexión: backoff exponencial (1s, 2s, 4s, 8s, max 30s)
  ├── Al hacer logout: cerrar conexión WS
  └── Mostrar SnackBar en el shell cuando llega una notificación nueva
```

El `access_token` para el WS se lee de `SecureStorage`. Si el WS recibe un error de autenticación (code 4001), disparar logout forzado.

### Prompt de entrada para este agente

```
Eres el agente Notifications & Profile de NexoBank Mobile. El core/ ya está listo.
Tu trabajo es implementar las features `notifications` y `profile`:

Notifications:
- NotificationDto (mapea el payload del WebSocket)
- NotificationsNotifier: conecta a WS /ws/notifications con Bearer, escucha el stream, reconexión con backoff exponencial, cierra al logout
- NotificationCenterScreen: lista de notificaciones
- Badge en el ícono de campana mostrando conteo no leído
- SnackBar cuando llega notificación nueva (visible desde cualquier pantalla autenticada)
- POST /device-tokens al iniciar sesión (llamado desde AuthNotifier tras login exitoso)

Profile:
- ProfileNotifier: GET /users/me
- ProfileScreen: avatar, nombre, email (solo lectura de campos sensibles)
- EditProfileScreen: PATCH /users/me (solo nombre y teléfono, no email)
- Logout: POST /auth/logout + limpiar SecureStorage + cerrar WS + navegar a /login

Tests: NotificationsNotifier (mock WebSocket stream, reconexión tras error), ProfileNotifier, EditProfile (validación de campos).
```

---

## Agente 5 — Integración

**Rama:** `main` (merge de A, B, C, D sobre `feature/core`)  
**Depende de:** todos los agentes anteriores

### Qué hace

1. Merge de ramas `feature/auth`, `feature/accounts-cards`, `feature/transfers-transactions`, `feature/notifications-profile` en orden.
2. Resolver conflictos (principalmente en `app_router.dart` — cada feature agrega rutas).
3. Conectar el `AppShell` (bottom navigation bar) que engloba las pantallas autenticadas:
   - Tab 1: Inicio (`/home`)
   - Tab 2: Transferencias (`/transfer`)
   - Tab 3: Notificaciones (`/notifications`) con badge
   - Tab 4: Perfil (`/profile`)
4. Verificar que `AuthNotifier.logout()` cierra el WS y redirige al login.
5. Correr `flutter analyze` y `flutter test --coverage` — corregir lo que falle.
6. Probar el golden path completo en emulador: registro → login → ver cuenta → transferir → ver historial → logout.

### Prompt de entrada para este agente

```
Eres el agente de Integración de NexoBank Mobile. Las 4 features (auth, accounts-cards, transfers-transactions, notifications-profile) ya están implementadas en sus ramas y mergeadas.
Tu trabajo es:
1. Implementar AppShell con BottomNavigationBar (4 tabs: Home, Transferir, Notificaciones con badge, Perfil).
2. Conectar todas las rutas en app_router.dart asegurando que el guard de auth funciona globalmente.
3. Verificar que logout() en AuthNotifier: cierra WS, borra storage, navega a /login.
4. Correr `flutter analyze` — cero warnings.
5. Correr `flutter test` — todos los tests pasan.
6. Reportar qué pantallas requieren prueba manual en emulador (lista de pasos).
No agregues features nuevas. Solo integración, corrección y verificación.
```

---

## Agente 6 — QA / Pulido final

**Rama:** `feature/qa-polish`  
**Depende de:** Agente 5

### Checklist de tareas

- [ ] Revisar que todos los `AsyncNotifier` muestran estado vacío ("No hay transacciones aún") además de loading y error.
- [ ] Revisar accesibilidad: `Semantics` en botones, íconos con `tooltip`, contraste de colores AA.
- [ ] Implementar banner "Sin conexión — mostrando datos guardados" cuando `DioError` es timeout.
- [ ] Implementar caché offline en Isar para lista de cuentas y últimas 20 transacciones.
- [ ] Golden tests de: LoginScreen, HomeScreen (con datos mock), TransferConfirmScreen.
- [ ] Revisar que `LoggingInterceptor` no loguea `Authorization`, `password`, ni números de tarjeta.
- [ ] Correr `flutter test --coverage` y reportar cobertura por feature.
- [ ] Escribir `README.md` con instrucciones de setup y cómo conectar al backend.

### Prompt de entrada para este agente

```
Eres el agente QA y pulido de NexoBank Mobile. La app ya está integrada.
Tu trabajo es revisar calidad sin agregar features nuevas:
1. Verificar que cada pantalla tiene estado vacío, estado de carga y estado de error manejados.
2. Agregar Semantics/tooltips en elementos interactivos clave.
3. Implementar caché Isar para cuentas y últimas 20 transacciones por cuenta.
4. Implementar banner de desconexión cuando Dio lanza ConnectionTimeout.
5. Escribir golden tests para LoginScreen, HomeScreen, TransferConfirmScreen.
6. Verificar que LoggingInterceptor no expone datos sensibles. Si lo hace, corregirlo.
7. Correr `flutter test --coverage` y reportar porcentaje por feature.
8. Escribir README.md con: requisitos, `flutter run` con dart-define, cómo levantar el backend.
Reporta al final qué puntos del checklist de seguridad del CLAUDE.md NO están cubiertos.
```

---

## Cómo ejecutar los agentes en Claude Code

### Fase 0 y 1 (secuenciales)

```bash
# Agente 0
claude "$(cat ai_agent_execution_plan.md)" --prompt "Ejecuta el rol del Agente 0 (Bootstrap)"

# Agente 1 (después de que termina el 0)
git checkout -b feature/core
claude --prompt "Ejecuta el rol del Agente 1 (Core/Foundation). Lee CLAUDE.md y ai_agent_execution_plan.md primero."
```

### Fase 2 (paralelo — 4 terminales)

```bash
# Terminal 1
git worktree add ../nexobank-auth feature/auth
cd ../nexobank-auth
claude --prompt "Ejecuta el rol del Agente A (Auth)..."

# Terminal 2
git worktree add ../nexobank-accounts feature/accounts-cards
cd ../nexobank-accounts
claude --prompt "Ejecuta el rol del Agente B (Accounts & Cards)..."

# Terminal 3
git worktree add ../nexobank-transfers feature/transfers-transactions
cd ../nexobank-transfers
claude --prompt "Ejecuta el rol del Agente C (Transfers & Transactions)..."

# Terminal 4
git worktree add ../nexobank-notifs feature/notifications-profile
cd ../nexobank-notifs
claude --prompt "Ejecuta el rol del Agente D (Notifications & Profile)..."
```

### Fase 3 (integración)

```bash
git checkout main
git merge feature/auth feature/accounts-cards feature/transfers-transactions feature/notifications-profile
claude --prompt "Ejecuta el rol del Agente 5 (Integración)..."
```

---

## Resumen de dependencias

```
Agente 0 (Bootstrap)
    └─► Agente 1 (Core)
            ├─► Agente A (Auth)          ─┐
            ├─► Agente B (Accounts)      ─┤─► Agente 5 (Integración) ─► Agente 6 (QA)
            ├─► Agente C (Transfers)     ─┤
            └─► Agente D (Notifications) ─┘
```

**Tiempo estimado:**
- Agente 0: 15 min
- Agente 1: 45–60 min
- Agentes A–D en paralelo: 60–90 min cada uno
- Agente 5: 30–45 min
- Agente 6: 45–60 min
- **Total wall-clock (paralelo real):** ~4–5 horas de sesiones de IA

---

## Criterios de done del proyecto completo

- [ ] `flutter analyze` — cero warnings en todos los archivos
- [ ] `flutter test` — todos los tests pasan (unit, widget, golden)
- [ ] El golden path completo funciona: registro → login → ver cuentas → transferir → ver historial → logout
- [ ] Los tokens persisten en `flutter_secure_storage` entre reinicios de app
- [ ] Un refresh token expirado redirige al login sin crash
- [ ] `flutter_secure_storage` es el ÚNICO lugar donde se guardan tokens
- [ ] Los logs no exponen tokens, passwords, ni números de tarjeta
- [ ] CI (GitHub Actions) pasa: `flutter analyze` + `flutter test`
- [ ] La app levanta con un solo comando: `flutter run --dart-define=API_BASE_URL=...`
