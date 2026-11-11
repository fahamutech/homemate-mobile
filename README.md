# HomeMate Africa — the app

The Flutter app (Android and PWA) for everyone outside the office: customers
finding, enquiring about and paying for a home, and the brokers and landlords
who list them. It talks only to
[homemate-functions](https://github.com/fahamutech/homemate-functions), the
API; HomeMate staff use [homemate-portal](https://github.com/fahamutech/homemate-portal).

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

### Which server a build talks to

`API_BASE_URL` is optional, and what happens when it is absent depends on the
build mode:

| Build | `API_BASE_URL` passed | Talks to |
|---|---|---|
| `flutter run` / `--debug` / `--profile` | no | `http://localhost:3001` |
| `flutter build … --release` | no | `https://homemate-faas.bfast.smartstock.co.tz` |
| any | yes | whatever was passed |

So a release build can never ship pointed at a laptop, even if somebody
forgets the flag — that failure would otherwise land on a customer's phone
rather than on anyone's screen here. `.env.prod.json` still exists and still
works; it now restates the default rather than being the only thing standing
between the Play Store and `localhost`.

```bash
flutter build appbundle --release                                  # production
flutter build appbundle --release --dart-define-from-file=.env.prod.json  # same, explicit
flutter build apk --release --dart-define=API_BASE_URL=https://staging…    # staging
```

`Env.describe()` reports the resolved URL and the build mode, and the Profile
screen shows a banner whenever a build is not talking to production — so a
tester is never left guessing which server they are looking at.

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

## Roles

One account, one app, any of three roles: **customer**, **broker** and
**landlord**. Everyone signs in the same way. Someone with more than one role
picks which to open after sign-in, and switches later from the role chip on
the home screen or from Profile. The choice is remembered on the phone, and
signing out signs out of every role.

- `features/roles/` holds the role controller and the switcher.
- `features/partner_shared/` is the broker and landlord workspace: setup and
  application (landlords add proof of ownership), listings, enquiries and
  earnings.
- `features/broker/` and `features/landlord/` hold each role's home. Landlords
  also get their tenancies, and confirm or dispute a broker's listing of their
  property.

While a partner role is open, every request carries `X-Partner-Role`, and the
API checks it against the roles the session holds.

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

## Releases

`main` is protected: changes arrive through a reviewed pull request with
green CI. Every pull request runs the analyzer and tests and builds both
release targets. A push to `main` then ships them:

- the PWA to Firebase Hosting;
- the signed App Bundle to the Google Play **internal** track.

The version name comes from `pubspec.yaml`; bump it in the release pull
request. The build number is the CI run number plus an offset, so it always
increases.

## Secrets

This repository is public, and so is anything shipped in the app: a web build
can be downloaded and an APK unpacked. The app holds no secret of its own.

- The upload keystore, its passwords and the Play and Firebase service
  accounts exist only as GitHub Actions secrets; CI writes them to the
  runner's temp directory for the signing step. `android/key.properties`,
  `*.jks`, `.env*` and service-account files are gitignored.
- `.env.prod.json` is committed on purpose: it holds public URLs only.
- `.github/workflows/secret-scan.yml` runs [gitleaks](https://github.com/gitleaks/gitleaks)
  over the full history on every push and pull request.
- If a secret is ever committed, **rotate it first**, then remove it.

See [SECURITY.md](SECURITY.md) to report a vulnerability.

## Not in this phase

Reviews (CUS-009) are designed but deliberately not built.
# homemate-mobile
