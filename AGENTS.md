# Helios Flutter host (`helios`)

## Purpose

Helios is the **host Flutter application** for a modular product: it owns global navigation, **Google Sign-In**, exchange with **Helios Core** (Go backend), **secure persistence of the Helios JWT**, session state, and a small **`HeliosAuth` contract** that feature packages use. Feature modules are separate packages and must **not** embed Google Sign-In.

## Identity

| Item | Value |
|------|--------|
| Display name | Helios |
| Android `applicationId` / namespace | `com.infydex.helios` |
| iOS bundle ID | `com.infydex.helios` |
| Pub package name | `helios` |

Platforms: **Android**, **iOS**, **Web** (first-class).

## Auth and backend flow

1. User taps **Continue with Google** on the single login screen (`lib/features/auth/presentation/login_page.dart`).
2. `google_sign_in` obtains a **Google ID token**. The host also requests **`https://www.googleapis.com/auth/user.phonenumbers.read`** (Google’s documented scope name; not `.../user.phonenumber.read`) so Google may attach **`phone_number`** (and related) claims to the ID token when the user consents. The app **does not** send a separate `phone` field to Helios Core — only `idToken`. After `signIn`, the host best-effort calls **`requestScopes`** / **`canAccessScopes`** where needed (especially **web**, per `google_sign_in` guidance); if the user **denies** phone access, sign-in **still completes** and Core may omit phone until another flow sets it.
3. Host `POST {API_BASE}/core/v1/auth/google` with JSON `{ "idToken": "<token>" }` only.
4. Helios Core returns `{ "user": { id, email, name, avatar, phone }, "token": "<Helios JWT>" }`.
5. Host stores JWT + minimal user JSON via **`flutter_secure_storage`** (see Web below).
6. Plugins never call Google; they call `HeliosAuth.getHeliosJwt()` when their HTTP clients need `Authorization: Bearer …`.

Helios Core should decode the Google **ID token** JWT to populate **`user.phone`** when `phone_number` (or your chosen claim) is present.

Optional: `GET {API_BASE}/core/v1/health` is implemented in `HeliosCoreApi.healthOk()` but **not** wired into the UI in this revision.

### Configure `API_BASE` (no hardcoded prod)

Use compile-time defines, for example:

```bash
flutter run --dart-define=API_BASE=https://api.dev.example --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
```

See `lib/core/env/helios_env.dart` for all supported defines.

### Google Sign-In defines

| Define | When |
|--------|------|
| `API_BASE` | Required for login (Helios Core origin, no trailing slash). |
| `GOOGLE_WEB_CLIENT_ID` | **Required on Web** — OAuth Web client ID. |
| `GOOGLE_SERVER_CLIENT_ID` | **Effectively required on Android** unless `google-services.json` includes a Web OAuth client (`oauth_client` with `"client_type": 3`). `client_type` **1** is Android-only and does **not** enable ID tokens. Use the **Web** client ID, or set `GOOGLE_SERVER_CLIENT_ID` in `android/local.properties`. |

Align OAuth clients (Web, Android, iOS) in one GCP project; backend `GOOGLE_CLIENT_ID` can be a comma-separated list of those client IDs.

### Phone / `user.phone`

The host requests **`user.phonenumbers.read`** so the returned **Google ID token** may include phone claims for Core to map into `user.phone`. **No `phone` key** is sent in the `POST /core/v1/auth/google` body. If the user **denies** the phone scope, login still succeeds; Core may return an empty phone until you handle it elsewhere.

## Modular host / plugin rules

- **Host** may depend on `google_sign_in`, Helios Core HTTP client, secure storage, `go_router`, etc.
- **Plugins** (`packages/todo`, `packages/movies`, …) depend only on **`helios_auth_contract`** for identity. They receive `HeliosAuth` via **constructor injection** from the host router (`context.read<HeliosAuthService>()` passed as `HeliosAuth`).
- **Exactly one** login screen; **Google only** in this phase.
- Helios JWT exists **only** after a successful Core exchange, not from Google alone.

## Folder map (indicative)

```
lib/
  main.dart, app.dart
  core/env/helios_env.dart
  core/router/app_router.dart
  features/auth/
    helios_auth_service.dart          # implements HeliosAuth + ChangeNotifier
    data/helios_core_api.dart
    data/secure_session_store.dart
    presentation/login_page.dart
  shell/home_shell.dart
packages/helios_auth_contract/        # HeliosAuth + HeliosUser + snapshots
packages/todo/                          # stub feature
packages/movies/                        # stub feature
```

## How plugins obtain the Helios JWT

1. Hold a reference to `HeliosAuth` (interface from `helios_auth_contract`).
2. Before calling a feature microservice, `await auth.getHeliosJwt()` and set header `Authorization: Bearer <jwt>` if non-null.
3. Listen to `auth.authStateStream` (or host-driven navigation) to react to sign-out.

The stub todo page includes a **demo button** that reads the JWT length for wiring checks.

## Web secure storage tradeoffs

`flutter_secure_storage` on Web uses **IndexedDB + Web Crypto** (see package docs). This is **stronger than raw `localStorage`** but **not equivalent** to iOS Keychain / Android hardware-backed keystore: any XSS or malicious script in the same origin could theoretically read storage. Mitigations: strict CSP, short JWT TTL, refresh flows when Core supports them, and treating Web as a higher-risk surface than mobile.

## Assumptions (minor)

- API errors from Core are surfaced as plain text on the login screen (no structured error codes yet).
- iOS **Google Sign-In URL scheme** (`CFBundleURLTypes` / reversed client ID) must be added in Xcode / `Info.plist` per Google’s iOS setup when you configure the real OAuth client (not committed here).
