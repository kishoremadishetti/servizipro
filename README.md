# Servizipro

Hybrid Flutter app (single codebase for Android, iOS, phones and tablets) with a
phone-number-based signup flow: **Signup → OTP popup → Dashboard**.

## Getting started

```bash
flutter pub get
flutter run --dart-define=ENV=test    # or qa / prod
```

If `--dart-define=ENV` is omitted it defaults to `test`.

To build:

```bash
flutter build apk --dart-define=ENV=prod        # Android
flutter build ios --dart-define=ENV=prod        # iOS
```

## Project structure

```
lib/
  core/
    environment.dart      # Test / QA / Prod base URLs & app name
    app_theme.dart         # Shared Material theme
  services/
    api_service.dart       # send-otp / resend-otp / verify-otp HTTP calls
    storage_service.dart   # SharedPreferences: OTP cache & session state
  utils/
    validators.dart        # Indian mobile number + OTP validation
  widgets/
    responsive_center.dart # Keeps layouts readable on tablets
  screens/
    splash_screen.dart       # Routes first-time vs returning users
    registration_screen.dart # Phone number + T&C/Privacy checkbox + Signup
    otp_dialog.dart           # OTP popup: Verify, Resend, Edit
    dashboard_screen.dart     # Landing page after successful verification
  main.dart
```

## Flow

1. **First launch** → `SplashScreen` checks local storage; no session found →
   `RegistrationScreen`.
2. User enters a 10-digit Indian mobile number, must check the **Terms and
   Conditions / Privacy Policy** box (each opens its own link), then taps
   **Sign up**.
3. App validates the number (`^[6-9]\d{9}$` after stripping `+91`/`0`
   prefixes), calls `POST {baseUrl}/auth/send-otp`, stores the returned OTP
   + requestId + expiry locally, and opens the **OTP popup**.
4. In the popup:
   - **Verify OTP** — checks the entered code against the locally cached
     OTP, then confirms with `POST {baseUrl}/auth/verify-otp`. On success,
     marks the user registered and navigates to `DashboardScreen`.
   - **Resend OTP** — disabled for 30s after each send; calls
     `POST {baseUrl}/auth/resend-otp` and refreshes the local OTP cache.
   - **Edit** — closes the popup and returns to `RegistrationScreen` so the
     user can correct the phone number.
5. **Subsequent launches**, if a session was previously verified, `SplashScreen`
   sends the user straight to `DashboardScreen`.

## Environments

Configured in `lib/core/environment.dart`:

| Environment | ENV value | Base URL |
|---|---|---|
| Test | `test` | `https://test-api.servizipro.com/api` |
| QA | `qa` | `https://qa-api.servizipro.com/api` |
| Prod | `prod` | `https://api.servizipro.com/api` |

Update these placeholder URLs to your real backend endpoints.

## Expected API contract

**POST `/auth/send-otp`** — body `{ "phoneNumber": "+91XXXXXXXXXX" }`
→ `{ "otp": "123456", "requestId": "abc123", "expiresInSeconds": 120 }`

**POST `/auth/resend-otp`** — body `{ "phoneNumber": "...", "requestId": "..." }`
→ same shape as send-otp

**POST `/auth/verify-otp`** — body `{ "phoneNumber": "...", "otp": "...", "requestId": "..." }`
→ `{ "verified": true, "authToken": "..." }`

> ⚠️ **Security note:** returning the OTP to the client and caching it in
> local storage (as specified) is convenient for a demo but is **not**
> secure for production — anyone with device/storage access could read it.
> A production build should have the server generate and store the OTP,
> and rely solely on `/auth/verify-otp` for validation (this app already
> calls that endpoint as the authoritative check; treat the local copy as
> a UI convenience only, not as the source of truth).

## Notes

- Update the Terms & Privacy Policy URLs in `registration_screen.dart`
  (`_openLink` calls) to your real, hosted pages.
- `ResponsiveCenter` caps content width on tablets/iPads so forms don't
  stretch edge-to-edge; adjust `maxWidth` per screen as needed.
