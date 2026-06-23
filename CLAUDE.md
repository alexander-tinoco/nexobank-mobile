# CLAUDE.md — NexoBank Mobile

Este archivo define cómo debe comportarse cualquier IA (Claude Code u otra) al escribir, modificar o revisar código en este repositorio. Es la app móvil de NexoBank: un cliente Flutter que consume la API del backend (`nexobank-backend`). Se desarrolla **con el estándar de una app bancaria real**. Las reglas aquí tienen prioridad sobre cualquier atajo de conveniencia.

---

## 0. Contexto del proyecto

- **App móvil Flutter** para iOS y Android que consume la API REST de NexoBank (`/api/v1/`).
- **Backend:** `nexobank-backend` (FastAPI + PostgreSQL + Redis). El contrato de la API está documentado en ese repo. Nunca asumir campos que no están en la respuesta real de la API.
- **Arquitectura:** feature-first con separación de capas dentro de cada feature:
  `presentation/` → `providers/` → `repositories/` → `data/` (DTOs + API client).
- **Estado:** Riverpod (AsyncNotifier / Notifier). No mezclar con otros gestores de estado.
- **Navegación:** GoRouter con guards de autenticación.
- **HTTP:** Dio con interceptores para auth y manejo centralizado de errores.
- **Almacenamiento seguro:** `flutter_secure_storage` para JWT y refresh tokens.

Este cliente será la única interfaz visual de los usuarios finales. **Cualquier cambio que altere flujos de auth, transferencias o datos financieros tiene impacto directo en la experiencia del usuario y en la seguridad de su dinero.**

---

## 1. Reglas no negociables (nunca se rompen)

1. **Nunca usar `double` para dinero.** Los montos vienen de la API como `String` (ej. `"500.00"`). Se muestran tal cual. Si se necesita aritmética en cliente (raro), usar el paquete `decimal`. Nunca `double.parse(amount)` para operaciones matemáticas.
2. **Nunca guardar tokens en `SharedPreferences`.** Los JWT (access token) y refresh tokens se almacenan exclusivamente en `flutter_secure_storage`. Es el único almacenamiento persistente para credenciales.
3. **Nunca loguear tokens, contraseñas, ni números de tarjeta.** En `debugPrint`, logs de Dio o cualquier sistema de analítica: redactar o excluir campos sensibles. Esto aplica también a crash reporters (Sentry, Firebase Crashlytics).
4. **El interceptor de Dio se encarga de adjuntar el Bearer token.** Ninguna llamada de repositorio agrega el header `Authorization` manualmente. Si el token expiró, el interceptor lo renueva transparentemente usando el refresh token. Si el refresh también falló, redirige a login.
5. **Manejar errores de API con tipos, no con `try/catch` genéricos.** Usar un tipo `Result<T, AppError>` (o `Either`) para que las pantallas sepan exactamente qué mostró y qué falló. Nunca dejar que una excepción no manejada llegue al `FlutterError.onError` en producción.
6. **El usuario solo ve sus propios datos.** Antes de navegar a un detalle de cuenta, tarjeta o transacción, verificar que el ID corresponde al usuario autenticado. La API también lo valida, pero la app no debe ni intentar mostrar recursos ajenos.
7. **No hay commits con `.env`, claves de API, `google-services.json` real, ni `GoogleService-Info.plist` real** en el repo. Solo versiones de ejemplo/placeholder.

Si una petición del usuario entra en conflicto con alguna de estas reglas, señalarlo explícitamente y proponer la alternativa segura.

---

## 2. Estándares de código

### Dart / Flutter
- Dart 3+, con `dart analyze` (modo strict en `analysis_options.yaml`) sin warnings antes de cerrar una tarea.
- `flutter_lints` + reglas adicionales en `analysis_options.yaml`. Cero warnings de lint.
- Nombres explícitos: `TransferRepository`, `AccountDetailScreen`, `AuthNotifier`. Nada de `Helper`, `Manager`, o `Utils` genéricos sin contexto.
- Funciones y métodos cortos. Si un widget `build()` supera ~60 líneas, extraer sub-widgets o refactorizar.
- Sin lógica de negocio en widgets. Los widgets solo: leen estado del provider, renderizan UI, despachan eventos al notifier.
- Sin llamadas HTTP directas desde widgets o providers. Todo acceso a la API pasa por repositorios.

### Arquitectura por feature
Cada feature sigue esta estructura:
```
lib/features/<feature_name>/
├── data/
│   ├── dtos/           # modelos que mapean exactamente el JSON de la API
│   └── <feature>_repository_impl.dart
├── domain/
│   ├── models/         # modelos de dominio de la UI (pueden diferir del DTO)
│   └── <feature>_repository.dart  # interfaz abstracta
└── presentation/
    ├── screens/
    ├── widgets/
    └── providers/      # Riverpod AsyncNotifier / Notifier
```

### API client
- Un único `DioClient` en `lib/core/network/dio_client.dart` con:
  - `AuthInterceptor`: adjunta `Bearer`, renueva token, redirige a login en 401.
  - `ErrorInterceptor`: transforma respuestas de error `{"error_code", "message", "request_id"}` del backend en `AppError` tipado.
  - `LoggingInterceptor`: activo solo en debug, sin loguear campos sensibles.
- `baseUrl` tomada de variables de entorno / `--dart-define`, nunca hardcodeada.

### Tokens y sesión
- Access token: guardado en `flutter_secure_storage`, TTL gestionado por el interceptor.
- Refresh token: también en `flutter_secure_storage`. Al renovar, reemplazar ambos atomicamente.
- Al logout: borrar ambos tokens del storage Y llamar `POST /auth/logout` al backend.

### Dinero en pantalla
- Siempre formatear con `NumberFormat.currency(locale: 'es_MX', symbol: 'MXN ')` (o la moneda de la cuenta).
- El `String` que viene de la API (`"1500.00"`) se parsea a `Decimal` solo para formatear, nunca para sumar o restar en cliente.

---

## 3. Seguridad — checklist antes de cerrar cualquier tarea

Antes de marcar terminada una tarea que toque auth, dinero o datos personales:

- [ ] ¿Los tokens se leen/escriben exclusivamente en `flutter_secure_storage`?
- [ ] ¿El interceptor de Dio cubre la renovación del access token sin que el repositorio lo sepa?
- [ ] ¿Se maneja el caso de refresh token expirado o revocado (→ logout forzado + pantalla de login)?
- [ ] ¿Los campos sensibles están excluidos de logs y crash reporters?
- [ ] ¿El flujo de transferencia muestra confirmación explícita antes de enviar (monto, cuenta destino)?
- [ ] ¿La navegación tiene guards que impiden acceder a pantallas autenticadas sin sesión activa?
- [ ] ¿La `idempotency_key` en transferencias se genera en el cliente y se asocia al intento actual (no reutilizar entre intentos diferentes)?

Si algún punto es "no" y debería ser "sí", la tarea no está terminada.

---

## 4. Testing — reglas estrictas

- **Toda lógica de repositorio** tiene tests con mock de `DioClient`. El contrato de la API no cambia sin que el test lo refleje.
- **Todo `AsyncNotifier`** tiene tests unitarios que cubren: estado inicial, carga exitosa, error de red, error de negocio (ej. `INSUFFICIENT_FUNDS`).
- **Flujos críticos** (login, transfer, logout) tienen widget tests o integration tests con golden files o verificación de navegación.
- No se deja un test en `skip` sin justificación en el propio código.
- Los tests no usan claves reales ni tokens reales — siempre fixtures/mocks.

---

## 5. Cómo debe trabajar la IA en este repo

1. **Antes de escribir código**, leer los archivos relevantes ya existentes para mantener consistencia de estilo y no duplicar lógica.
2. **Antes de un cambio multi-archivo** (nueva pantalla que toca provider + repositorio + DTO + router), explicar el plan brevemente y esperar confirmación si hay dudas de diseño.
3. **Cambios pequeños y verificables.** Si una tarea requiere crear más de 3 archivos nuevos, dividirla en pasos y avisar.
4. **Nunca inventar campos de la API.** Si necesitas un campo que no está en el README del backend o en la respuesta real, señalarlo y preguntar antes de inventarlo en el DTO.
5. **Después de cualquier cambio:** correr (o indicar que se deben correr) `flutter analyze` y `flutter test` antes de considerar la tarea terminada. Si no se pueden ejecutar en el entorno actual, decirlo explícitamente.
6. **Commits descriptivos:** el mensaje explica el "por qué", no solo el "qué". Ejemplo: `feat: interceptor renueva access token automáticamente para evitar 401 inesperados`, no `fix auth`.
7. **Si una petición es ambigua respecto a las reglas de este archivo**, preguntar antes de decidir por cuenta propia.
8. **Nunca forzar un push a main.** Si se detecta conflicto o divergencia, señalarlo al usuario.

---

## 6. Fuera de alcance para la IA sin confirmación explícita

- Cambiar el gestor de estado (Riverpod → Bloc o similares).
- Cambiar el router (GoRouter por otro).
- Agregar dependencias de peso (Firebase, ML Kit, mapas) sin que se pida explícitamente.
- Modificar `analysis_options.yaml` para deshabilitar reglas de lint.
- Conectar a un backend diferente al de `nexobank-backend` sin indicación explícita.
- Tocar `google-services.json`, `GoogleService-Info.plist`, o cualquier archivo de configuración de plataforma.

---

## 7. Definición de "terminado"

Una tarea en NexoBank Mobile se considera terminada solo si:

- El código sigue la arquitectura feature-first (widget → provider → repository → DioClient).
- `flutter analyze` y `dart analyze` pasan sin warnings.
- Hay tests para el provider y el repositorio de la funcionalidad nueva.
- El checklist de seguridad de la sección 3 pasa (si aplica).
- La pantalla fue probada manualmente en simulador/emulador (golden path + al menos un caso de error).
- No se rompe la navegación ni el flujo de auth al introducir el cambio.

Si alguno de estos puntos no se cumple, la tarea se reporta como **parcial**, no como completa.
