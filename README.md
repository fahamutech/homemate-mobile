# HomeMate Africa — customer app

The Flutter app customers use to find, view, book and pay for a home. It is a
sibling of `homemate-functions` (the API) and `homemate-partner-portal` (the
backoffice), and talks only to the API.

## Running it

Configuration arrives as compile-time `--dart-define`s, not a bundled asset: a
Flutter web build is downloadable, so anything shipped as an asset is public.
Copy the example and point it at your backend.

```bash
cp .env.example .env.json   # then edit — it is JSON, not KEY=VALUE
flutter pub get
flutter run -d chrome --dart-define-from-file=.env.json
```

| Key | What it is |
|---|---|
| `API_BASE_URL` | Where the API lives, e.g. `http://localhost:3001` |
| `MAP_TILE_URL` | OpenStreetMap raster tiles; point at your own cache in production |
| `MAP_USER_AGENT` | Required by the OSM tile usage policy |
| `DEFAULT_LATITUDE` / `DEFAULT_LONGITUDE` | Where the map opens before a search |
| `REQUEST_TIMEOUT_SECONDS` | How long a request may take before it is a failure |

Nothing here is a secret. The only credential the app ever holds is the session
token, issued at sign-in and kept in `shared_preferences`.

## How it is put together

```
lib/
  core/            config, the one HTTP client, the provider graph
  design/          tokens from Figma, the Material theme, shared widgets
  features/<name>/
    data/          models, repositories, providers — no widgets
    presentation/  widgets — no HTTP, no SQL, no storage
  routing/         every path, and the one redirect that guards them
```

Four rules hold it together:

- **UI logic lives in widgets; service code lives outside them.** A screen
  never constructs an HTTP client, reads storage or knows a URL path. It asks a
  repository, and the repository is handed to it by Riverpod.
- **State is Riverpod, routing is go_router.** There is exactly one place that
  decides who may see what: the `redirect` in `routing/app_router.dart`. A new
  screen is guarded the moment it is added.
- **Shared widgets are shared.** `HmScaffold`, `HmAsync`, `HmStatusChip`,
  `HmPrompt`, `PropertyCard` and `PropertyImage` are used everywhere they fit;
  a second near-identical widget is how two screens drift apart.
- **Nothing hardcodes a colour or a spacing.** `design/tokens.dart` carries the
  Figma variables, so a change there is a change everywhere.

## Signing in

The phone number is proved **once** with an SMS code; after that the customer
signs in with a PIN. That is not only kinder than a code every time — each SMS
costs real credit, and an app that sends one per login is an app whose login
breaks the day the balance runs out.

OTP is therefore reserved for the cases that genuinely need the phone
re-proved: first registration, a forgotten PIN, and a new device. How often a
code may be asked for is decided in the database (`otp_quota_check`), so the
app, a future web client and any support tool are held to the same limits.

## Money

The app never takes payment. It shows the account details an operator
published in the portal, offers an **I have paid** button, and then says
plainly that someone is checking. A customer's claim settles nothing — only a
verified reconciliation in the backoffice does, which is BR-005 in practice.

## Tests

```bash
flutter test                                   # widget + unit
flutter analyze
flutter test integration_test/ \
  --device-id=flutter-tester \
  --dart-define-from-file=.env.json            # against a running backend
```

- `test/` runs every screen against in-memory fakes that mirror the server's
  **refusals** as well as its happy paths — a screen that ignores a conflict or
  pretends a payment is confirmed fails here.
- `integration_test/` runs the whole app — real widgets, real router, real HTTP,
  real Postgres — through onboarding, search, a property and an enquiry. It
  needs the backend up; it skips with a message if it is not.

To drive it in a real browser instead:

```bash
npx chromedriver --port=4444 &
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/customer_journey_test.dart \
  -d chrome --dart-define-from-file=.env.json
```

## Not in this phase

Reviews (CUS-009) are designed but deliberately not built.
# homemate-mobile
