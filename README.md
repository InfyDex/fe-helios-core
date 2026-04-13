# Helios

Modular Flutter **host** app: **Google Sign-In** → **Helios Core** (`POST /core/v1/auth/google`) → persisted **Helios JWT**. Feature modules live under `packages/` and consume `helios_auth_contract` only.

## Requirements

- Flutter stable (see `pubspec.yaml` SDK constraint)
- Android SDK / Xcode when building those platforms
- GCP OAuth clients (**Web**, **Android**, **iOS**) in one project; backend `GOOGLE_CLIENT_ID` may list all client IDs comma-separated

## Run (mobile)

```bash
flutter pub get
flutter run --dart-define=API_BASE=https://your-core-host \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

- **Android ID token:** Needs a **Web** OAuth client id (`.apps.googleusercontent.com`). The **Google Services** plugin writes `default_web_client_id` from **`google-services.json`** when `oauth_client` includes **`"client_type": 3`**. If your JSON has **no** Web client, add **`GOOGLE_SERVER_CLIENT_ID`** to **`android/local.properties`** (the app’s Gradle injects it only in that case—never duplicate the Firebase merge). Type **1** is Android-only and is not enough for `idToken` alone. A **HELIOS** Gradle warning appears when neither Web client nor override exists.
- **Android:** Add your app's SHA-1/256 in the Google Cloud **Android** OAuth client. If you omit `GOOGLE_SERVER_CLIENT_ID`, the ID token audience is the Android client ID — ensure Helios Core accepts that `aud`.
- **iOS:** Add the **reversed iOS client ID** URL scheme to `Info.plist` / Xcode (Google Sign-In iOS setup). Use the **iOS** OAuth client in Google Cloud.

## Run (Web)

```bash
flutter run -d chrome \
  --dart-define=API_BASE=https://your-core-host \
  --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

In Google Cloud Console → **Web client** → **Authorized JavaScript origins**, add the origins you use (e.g. `http://localhost:8080`, your staging host). Flutter web dev server ports vary; add each origin you use.

Build:

```bash
flutter build web --dart-define=API_BASE=... --dart-define=GOOGLE_WEB_CLIENT_ID=...
```

## Defines reference

| `--dart-define` | Purpose |
|-----------------|--------|
| `API_BASE` | Helios Core origin, **no** trailing slash (e.g. `https://api.dev.example`). |
| `GOOGLE_WEB_CLIENT_ID` | **Web only** — required for `google_sign_in` on Flutter web. |
| `GOOGLE_SERVER_CLIENT_ID` | Optional — Web client ID passed as `serverClientId` on Android/iOS for ID token audience alignment. |
| `TODO_API_BASE` | Stub only; future todo service (see `packages/todo`). |
| `MOVIES_API_BASE` | Stub only; future movies service (see `packages/movies`). |

Do **not** commit OAuth secrets; use CI/CD or local defines.

## Project layout

- `lib/` — host app, router, login, `HeliosAuthService`
- `packages/helios_auth_contract/` — `HeliosAuth`, `HeliosUser`, snapshots
- `packages/todo/`, `packages/movies/` — stub plugins (no `google_sign_in`)

More detail: **`AGENTS.md`**.

## Tests / analysis

```bash
flutter analyze
flutter test
```

After substantive changes, run **both** above until clean (see `.cursor/rules/helios-flutter.mdc`). Integration-style checks (Google Sign-In, secure storage) remain manual or device tests; HTTP and URL logic are covered in `test/`.

## GCP reminders

1. Create **OAuth 2.0 Client IDs** for Web, Android, and iOS in the same GCP project.
2. Web client: correct **Authorized JavaScript origins** for Flutter web.
3. Android: package name `com.infydex.helios` + signing certificate fingerprints.
4. iOS: bundle ID `com.infydex.helios` + URL scheme from reversed client ID.
5. Helios Core: `GOOGLE_CLIENT_ID` includes every client ID whose tokens you accept.
6. The app requests **`https://www.googleapis.com/auth/user.phonenumbers.read`** (Google’s spelling) so the **Google ID token** may include phone claims; Helios Core should read them from the JWT. The app does **not** send `phone` in the auth request body. If you use this scope, complete **OAuth consent screen** / **People API** setup in GCP as Google requires for sensitive scopes.
