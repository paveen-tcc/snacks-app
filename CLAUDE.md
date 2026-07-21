# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

This is a two-part monorepo for an office "snacks" ordering app:

- `app/` — Flutter client (iOS, Android, web, desktop) — Dart SDK `^3.11.1`
- `server/` — Cloudflare Workers backend (Hono + Drizzle ORM + Cloudflare D1) running on Bun

The Flutter app talks to the Workers API over HTTPS, authenticating users via Microsoft Entra ID (MSAL) and exchanging the Azure token for a server-issued JWT.

A separate `server/CLAUDE.md` exists with Bun-specific instructions (use `bun` over `node`/`npm`/`pnpm`, `bun test`, `Bun.serve`, etc.) — follow it when working inside `server/`.

## Common commands

### Flutter app (`cd app`)

```bash
flutter pub get                         # install deps
flutter run                             # run on attached device / simulator
flutter run -d chrome                   # web
flutter analyze                         # lint (flutter_lints rules)
flutter test                            # all tests
flutter test test/path/to/file_test.dart  # single test file
flutter test --plain-name "test name"     # single test by name

# Codegen (Drift schema + Freezed + json_serializable)
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch                              # rebuild on change
```

`app/lib/data/local/app_database.g.dart` is generated — regenerate via `build_runner` after editing `entity/schema.dart` or any `@DriftDatabase`/`@freezed` source. When changing the Drift schema, bump `schemaVersion` in [app_database.dart](app/lib/data/local/app_database.dart) and add an `onUpgrade` branch.

### Server (`cd server`)

```bash
bun install
bun run dev                 # wrangler dev on :8787 (local D1 via miniflare)
bun run deploy              # wrangler deploy (org account)
bun run db:generate         # drizzle-kit generate migrations from schema.ts
bun run db:migrate:local    # apply migrations to local D1
bun run db:migrate:remote   # apply migrations to org D1
bun run db:seed             # generate seed.sql and apply to local D1
```

Secrets are set with `bunx wrangler secret put <KEY>` for: `JWT_SECRET`, `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `FCM_SERVICE_ACCOUNT` (listed in [wrangler.toml](server/wrangler.toml)). The database is a D1 binding (`DB`), not a secret.

## Architecture

### Server (`server/src/`)

- Single Hono app exported as the Worker default export ([index.ts](server/src/index.ts)).
- Per-request middleware constructs a Drizzle client over the D1 binding (c.env.DB) and stashes it in c.set('db', ...) along with jwtSecret. Routes pull these via c.get(...) — **do not** instantiate the DB inside route handlers.
- `AppEnv` (`Bindings` + `Variables`) is the canonical Hono generic — propagate it through every `new Hono<AppEnv>()` and `Context<AppEnv>` so `c.get('db' | 'jwtSecret' | 'user')` stays typed.
- Auth ([middleware/auth.ts](server/src/middleware/auth.ts)): `authMiddleware` verifies the server-issued JWT and sets `c.set('user', payload)`; `adminMiddleware` requires `user.isAdmin`. The `/api/auth` routes themselves verify the MSAL/Azure token (via JWKS at `login.microsoftonline.com/{tenant}/discovery/v2.0/keys`) and mint the app JWT.
- Routes are mounted under `/api/{auth,snacks,orders,drinks,admin}`. Drizzle schema lives in [src/db/schema.ts](server/src/db/schema.ts); migrations go to `server/drizzle/`.

### Flutter app (`app/lib/`)

Layered architecture wired through `get_it`:

- `core/di/locator.dart` — composition root. Order matters: MSAL initialized first (async), then `ApiClient` + `AppDatabase`, then repositories, then `SyncEngine.start()`. Add new singletons here.
- `core/auth/msal_service.dart` — Microsoft Entra sign-in (config in `assets/msal_config.json`).
- `core/network/api_client.dart` — Dio client; attaches the server JWT from `SharedPreferences['auth_token']`.
- `data/local/` — Drift (SQLite) database. Tables: `LocalSnacks`, `LocalOrders`, `LocalSettings`, `SyncQueue`.
- `data/repositories/` — each repo wraps `ApiClient` (+ `AppDatabase` for snack/order) and is the only layer screens/blocs should touch.
- `data/sync/sync_engine.dart` — offline-first queue. Mutations that fail offline are written to `SyncQueue`; on `connectivity_plus` reconnect it replays them and drops 4xx as permanently failed.
- `presentation/` — feature folders (`onboarding`, `home`, `history`, `admin`) using `flutter_bloc`. Routing in [config/routes.dart](app/lib/config/routes.dart) via `go_router`; the redirect gates everything behind `SharedPreferences['auth_token']`.
- `core/theme/notion_theme.dart` — single `MaterialApp.router` theme applied app-wide.

### Auth flow end-to-end

1. App acquires an Azure access token via `MsalService` (configured via `assets/msal_config.json`).
2. App POSTs it to `/api/auth/...`; server verifies against Entra JWKS using `AZURE_TENANT_ID`/`AZURE_CLIENT_ID`, then mints a JWT signed with `JWT_SECRET` (admin flag included in payload).
3. App stores that JWT in `SharedPreferences['auth_token']`; `ApiClient` sends it as `Authorization: Bearer`. The router redirect uses the same key to decide onboarding vs home.

### Offline-first writes

User-initiated mutations (placing an order, voting on a drink) are designed to succeed offline by enqueueing into the local `SyncQueue` table; the `SyncEngine` drains the queue when connectivity returns. When adding a new mutation endpoint, follow the existing pattern (write locally + enqueue, let `SyncEngine` replay) rather than calling the API directly from the bloc.
