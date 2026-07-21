# Neon Postgres → Cloudflare D1 Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the snacks-app server's database from Neon Postgres (personal account) to Cloudflare D1 (org account), with zero change to the JSON contract the Flutter client sees.

**Architecture:** The Drizzle schema is rewritten from `pg-core` to `sqlite-core`, the driver swaps from `drizzle-orm/neon-http` to `drizzle-orm/d1`, and the DB reaches the Worker as a `D1Database` binding instead of a `DATABASE_URL` secret. Routes are untouched — they consume `c.get('db')` and never import the driver. Because a D1 binding must live in the same Cloudflare account as its Worker, the Worker also moves to the org account; a tiny proxy Worker stays on the personal account at the old URL so existing app installs keep working.

**Tech Stack:** Cloudflare Workers + D1, Hono 4, drizzle-orm 0.45.x (`drizzle-orm/d1`, `drizzle-orm/bun-sqlite` for tests), drizzle-kit 0.31.x (sqlite dialect), wrangler 4.x, Bun for scripts/tests.

## Global Constraints

- **JSON contract is frozen.** The Flutter client reads `date` fields as `'YYYY-MM-DD'` strings (`orders_tab.dart:70` does `order['date'] as String`), timestamps as ISO-8601 strings, booleans as JSON true/false. Every schema choice below preserves this: `date` → `text`, `timestamp` → `integer { mode: 'timestamp_ms' }` (Drizzle returns `Date`, Hono's `c.json` serializes to ISO), `boolean` → `integer { mode: 'boolean' }`.
- **Timestamp mode is `timestamp_ms` (milliseconds) everywhere** — never plain `timestamp` (seconds). The data-import script writes epoch **milliseconds**; mixing modes corrupts every date display.
- **D1 database name is `snacks-db`** in every wrangler command and script. The binding name is `DB`.
- **Same-account rule:** the D1 database and the Worker must both be on the **org** Cloudflare account. Task 6 verifies `wrangler whoami` before anything remote.
- **Old URL keeps working:** `https://snacks-app.paveenkumar-dev.workers.dev` (personal account, hardcoded default in `app/lib/core/network/api_client.dart:12`) must forward to the org Worker after cutover (Task 7).
- **Use `bun`/`bunx`, never `npm`/`npx`** (per `server/CLAUDE.md`).
- **Never commit `seed.sql` or `neon-export.sql`** (the export contains user emails). Both are gitignored in Task 3/4.
- Existing dependency versions stay: drizzle-orm `^0.45.1`, drizzle-kit `^0.31.9`, wrangler `^4.71.0`, hono `^4.12.5`. `@neondatabase/serverless` stays until Task 8 (the export script needs it).
- All server commands run from `server/`.

## Prerequisites (user-provided, needed at Task 6)

- Wrangler authenticated to the **org** Cloudflare account (and separately to the personal account for Task 7's shim deploy).
- The production Neon `DATABASE_URL` (for the data export).
- Values for secrets on the org Worker: `JWT_SECRET`, `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `FCM_SERVICE_ACCOUNT`. **If the original `JWT_SECRET` value is unknown, generate a new one — every user is signed out once and must sign in again (acceptable; MSAL re-auth is silent for most).**

---

### Task 1: SQLite schema + schema tests + fresh migrations

**Files:**
- Modify: `server/src/db/schema.ts` (full rewrite)
- Modify: `server/drizzle.config.ts`
- Delete: `server/drizzle/*.sql`, `server/drizzle/meta/`
- Test: `server/src/db/schema.test.ts` (new)

**Interfaces:**
- Consumes: nothing.
- Produces: table objects `users`, `snacks`, `orders`, `holidays`, `shutdownDays`, `appSettings`, `pushTokens`, `syncQueue` with the **same exported names and same TS field types** as today (`id: string`, `createdAt: Date | null`, `isAdmin: boolean | null`, `orders.date: string`, `syncQueue.payload: unknown`), so no route file changes. Also produces `server/drizzle/0000_*.sql`, the initial SQLite migration all later tasks apply.

- [ ] **Step 1: Write the failing test**

Create `server/src/db/schema.test.ts`:

```ts
import { describe, test, expect } from 'bun:test';
import { Database } from 'bun:sqlite';
import { drizzle } from 'drizzle-orm/bun-sqlite';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { eq } from 'drizzle-orm';
import * as schema from './schema';
import { users, snacks, orders, appSettings, pushTokens } from './schema';

const MIGRATIONS_DIR = join(import.meta.dir, '../../drizzle');

// Applies the real generated migrations, so these tests also prove the DDL
// drizzle-kit emits actually runs on SQLite (same statements D1 will run).
function createTestDb() {
    const sqlite = new Database(':memory:');
    const files = readdirSync(MIGRATIONS_DIR)
        .filter((f) => f.endsWith('.sql'))
        .sort();
    expect(files.length).toBeGreaterThan(0);
    for (const file of files) {
        const contents = readFileSync(join(MIGRATIONS_DIR, file), 'utf8');
        for (const statement of contents.split('--> statement-breakpoint')) {
            const trimmed = statement.trim();
            if (trimmed) sqlite.run(trimmed);
        }
    }
    return drizzle(sqlite, { schema });
}

describe('D1 schema', () => {
    test('users get uuid ids and Date createdAt without explicit values', async () => {
        const db = createTestDb();
        const [user] = await db.insert(users)
            .values({ username: 'alice', email: 'alice@example.com' })
            .returning();
        expect(user!.id).toMatch(/^[0-9a-f-]{36}$/);
        expect(user!.createdAt).toBeInstanceOf(Date);
        expect(Math.abs(user!.createdAt!.getTime() - Date.now())).toBeLessThan(5_000);
        expect(user!.isAdmin).toBe(false);
    });

    test('order JSON shape matches the old Postgres contract', async () => {
        const db = createTestDb();
        const [user] = await db.insert(users)
            .values({ username: 'bob', email: 'bob@example.com' })
            .returning();
        const [order] = await db.insert(orders)
            .values({
                userId: user!.id,
                date: '2026-07-15',
                snackId: crypto.randomUUID(),
                snackNameSnapshot: 'Veg Samosa',
                updatedAt: new Date(),
            })
            .returning();

        // What Hono's c.json() would send to the Flutter client:
        const serialized = JSON.parse(JSON.stringify(order));
        expect(serialized.date).toBe('2026-07-15');                       // plain string
        expect(serialized.orderedAt).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/); // ISO string
        expect(serialized.isDefaultAssigned).toBe(false);                 // JSON boolean
    });

    test('appSettings upsert works (onConflictDoUpdate)', async () => {
        const db = createTestDb();
        await db.insert(appSettings).values({ key: 'cutoff_time', value: '12:00' });
        await db.insert(appSettings)
            .values({ key: 'cutoff_time', value: '13:30' })
            .onConflictDoUpdate({ target: appSettings.key, set: { value: '13:30' } });
        const [row] = await db.select().from(appSettings)
            .where(eq(appSettings.key, 'cutoff_time'));
        expect(row!.value).toBe('13:30');
    });

    test('pushTokens upsert re-points a device to a new user', async () => {
        const db = createTestDb();
        const [u1] = await db.insert(users)
            .values({ username: 'u1', email: 'u1@example.com' }).returning();
        const [u2] = await db.insert(users)
            .values({ username: 'u2', email: 'u2@example.com' }).returning();
        const values = { token: 'tok-1', userId: u1!.id, platform: 'ios', updatedAt: new Date() };
        await db.insert(pushTokens).values(values);
        await db.insert(pushTokens)
            .values({ ...values, userId: u2!.id })
            .onConflictDoUpdate({
                target: pushTokens.token,
                set: { userId: u2!.id, platform: 'ios', updatedAt: new Date() },
            });
        const rows = await db.select().from(pushTokens);
        expect(rows).toHaveLength(1);
        expect(rows[0]!.userId).toBe(u2!.id);
    });

    test('summary-style aggregate query runs on SQLite', async () => {
        const db = createTestDb();
        const [user] = await db.insert(users)
            .values({ username: 'agg', email: 'agg@example.com' }).returning();
        const [snack] = await db.insert(snacks)
            .values({ name: 'Tea', category: 'Drinks', shareCount: 1 }).returning();
        await db.insert(orders).values([
            { userId: user!.id, date: '2026-07-15', snackId: snack!.id, snackNameSnapshot: 'Tea' },
            { userId: user!.id, date: '2026-07-15', snackId: snack!.id, snackNameSnapshot: 'Tea' },
        ]);
        const { sql } = await import('drizzle-orm');
        const counts = await db
            .select({
                snackId: orders.snackId,
                snackName: sql<string>`coalesce(${orders.snackNameSnapshot}, ${snacks.name}, 'Unknown')`,
                selectedCount: sql<number>`count(*)`.mapWith(Number),
                shareCount: sql<number>`coalesce(max(${snacks.shareCount}), 1)`.mapWith(Number),
            })
            .from(orders)
            .leftJoin(snacks, eq(orders.snackId, snacks.id))
            .where(sql`${orders.date} = ${'2026-07-15'}`)
            .groupBy(orders.snackId, sql`coalesce(${orders.snackNameSnapshot}, ${snacks.name}, 'Unknown')`);
        expect(counts).toHaveLength(1);
        expect(counts[0]!.selectedCount).toBe(2);
    });
});
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd server && bun test src/db/schema.test.ts`
Expected: FAIL — the old Postgres migration SQL (`CREATE TABLE ... uuid PRIMARY KEY DEFAULT gen_random_uuid()`) is not valid SQLite, and/or schema still imports `pg-core`.

- [ ] **Step 3: Rewrite `server/src/db/schema.ts` for sqlite-core**

Replace the entire file with:

```ts
import {
    sqliteTable,
    text,
    integer,
    index,
} from 'drizzle-orm/sqlite-core';

// D1/SQLite has no uuid type or gen_random_uuid(); ids are generated
// app-side so inserted rows still get Postgres-style uuid strings.
const uuidPk = (name: string) =>
    text(name).primaryKey().$defaultFn(() => crypto.randomUUID());

// Stored as epoch milliseconds; Drizzle returns Date, so JSON output stays
// ISO-8601 strings — identical to the old timestamptz behavior.
const timestampMs = (name: string) =>
    integer(name, { mode: 'timestamp_ms' });

// Users (username + email, unique username)
export const users = sqliteTable('users', {
    id: uuidPk('id'),
    username: text('username', { length: 100 }).unique().notNull(),
    email: text('email', { length: 255 }).unique().notNull(),
    microsoftId: text('microsoft_id', { length: 255 }).unique(),
    deviceId: text('device_id', { length: 255 }),
    isAdmin: integer('is_admin', { mode: 'boolean' }).default(false),
    createdAt: timestampMs('created_at').$defaultFn(() => new Date()),
});

// Snack catalog (flat list, admin controls visibility)
export const snacks = sqliteTable('snacks', {
    id: uuidPk('id'),
    name: text('name', { length: 100 }).notNull(),
    category: text('category', { length: 100 }),
    emoji: text('emoji', { length: 512 }),
    isVeg: integer('is_veg', { mode: 'boolean' }).default(true),
    isDefault: integer('is_default', { mode: 'boolean' }).default(false), // admin-designated default
    isActive: integer('is_active', { mode: 'boolean' }).default(true),    // admin toggle to show/hide
    servingSize: text('serving_size', { length: 50 }), // per-person: "2 pieces", "1 bowl"
    shareCount: integer('share_count').notNull().default(1), // 1 = per-person, 2 = serves two, etc.
    sortOrder: integer('sort_order').default(0),
    createdAt: timestampMs('created_at').$defaultFn(() => new Date()),
});

// Employee snack orders (one per user per day); date is 'YYYY-MM-DD' text,
// matching what the Flutter client already parses.
export const orders = sqliteTable('orders', {
    id: uuidPk('id'),
    userId: text('user_id').references(() => users.id).notNull(),
    date: text('date').notNull(),
    snackId: text('snack_id').notNull(),
    snackNameSnapshot: text('snack_name_snapshot', { length: 100 }),
    snackEmojiSnapshot: text('snack_emoji_snapshot', { length: 512 }),
    isDefaultAssigned: integer('is_default_assigned', { mode: 'boolean' }).default(false),
    orderedAt: timestampMs('ordered_at').$defaultFn(() => new Date()),
    updatedAt: timestampMs('updated_at').$defaultFn(() => new Date()),
}, (t) => ({
    userDateIdx: index('orders_user_date_idx').on(t.userId, t.date),
}));

// Holidays (hybrid: auto-fetched + manual)
export const holidays = sqliteTable('holidays', {
    id: uuidPk('id'),
    date: text('date').unique().notNull(),
    name: text('name', { length: 100 }),
    source: text('source', { length: 20 }).default('manual'), // 'auto' or 'manual'
    createdBy: text('created_by').references(() => users.id),
});

// Temporary shutdown days
export const shutdownDays = sqliteTable('shutdown_days', {
    id: uuidPk('id'),
    date: text('date').unique().notNull(),
    reason: text('reason', { length: 255 }),
    createdBy: text('created_by').references(() => users.id),
});

// App settings (admin-configurable)
export const appSettings = sqliteTable('app_settings', {
    key: text('key', { length: 50 }).primaryKey(),
    value: text('value').notNull(),
    advanceOrderMode: integer('advance_order_mode', { mode: 'boolean' }).notNull().default(false),
    advanceWindowStart: text('advance_window_start', { length: 5 }).notNull().default('06:00'),
    advanceWindowEnd: text('advance_window_end', { length: 5 }).notNull().default('22:00'),
    // Keys: cutoff_time, whatsapp_number, whatsapp_is_group,
    //        whatsapp_template, holiday_country
});

// Device push tokens (FCM). One row per device install; token is unique, so a
// device that re-logs-in as another user simply re-points to the new userId.
export const pushTokens = sqliteTable('push_tokens', {
    token: text('token', { length: 512 }).primaryKey(),
    userId: text('user_id').references(() => users.id).notNull(),
    platform: text('platform', { length: 20 }).default('android'),
    updatedAt: timestampMs('updated_at').$defaultFn(() => new Date()),
}, (t) => ({
    userIdx: index('push_tokens_user_idx').on(t.userId),
}));

// Offline sync queue
export const syncQueue = sqliteTable('sync_queue', {
    id: uuidPk('id'),
    userId: text('user_id').references(() => users.id).notNull(),
    tableName: text('table_name', { length: 50 }).notNull(),
    recordId: text('record_id').notNull(),
    action: text('action', { length: 10 }).notNull(), // INSERT, UPDATE, DELETE
    payload: text('payload', { mode: 'json' }),
    createdAt: timestampMs('created_at').$defaultFn(() => new Date()),
    syncedAt: timestampMs('synced_at'),
});
```

- [ ] **Step 4: Point drizzle-kit at SQLite**

Replace `server/drizzle.config.ts` with:

```ts
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
    schema: './src/db/schema.ts',
    out: './drizzle',
    dialect: 'sqlite',
});
```

(No credentials needed — migrations are applied by wrangler, not drizzle-kit.)

- [ ] **Step 5: Delete the Postgres migrations and generate the SQLite one**

```bash
cd server
git rm -r drizzle/
bun run db:generate
```

Expected: a new `drizzle/0000_<name>.sql` containing `CREATE TABLE` statements with `text`/`integer` columns, plus `drizzle/meta/`.

- [ ] **Step 6: Run the tests to verify they pass**

Run: `cd server && bun test src/db/schema.test.ts`
Expected: PASS (5 tests). Note `src/db/index.ts` still imports the neon driver — that's Task 2; the tests intentionally don't import it.

- [ ] **Step 7: Commit**

```bash
git add server/src/db/schema.ts server/src/db/schema.test.ts server/drizzle.config.ts server/drizzle
git commit -m "feat(server): rewrite Drizzle schema for SQLite/D1 with contract tests"
```

---

### Task 2: D1 driver wiring (Worker binding replaces DATABASE_URL)

**Files:**
- Modify: `server/src/db/index.ts`
- Modify: `server/src/index.ts:15-22` (Bindings), `server/src/index.ts:40-45` (middleware)
- Modify: `server/src/scheduled.ts:166`
- Modify: `server/wrangler.toml`
- Modify: `server/package.json` (scripts)

**Interfaces:**
- Consumes: `schema.ts` from Task 1.
- Produces: `createDb(d1: D1Database): Database` and `type Database` (same export names as before — routes, `orderWindow.ts`, and `scheduled.ts` keep importing `Database` from `../db` unchanged). `Bindings` gains `DB: D1Database` and loses `DATABASE_URL`. Scripts `db:migrate:local` / `db:migrate:remote` that Tasks 3–6 call.

- [ ] **Step 1: Swap the driver in `server/src/db/index.ts`**

Replace the entire file with:

```ts
import { drizzle } from 'drizzle-orm/d1';
import * as schema from './schema';

// D1Database is a global type via tsconfig "types": ["@cloudflare/workers-types"].
export function createDb(d1: D1Database) {
    return drizzle(d1, { schema });
}

export type Database = ReturnType<typeof createDb>;
```

- [ ] **Step 2: Update `Bindings` and middleware in `server/src/index.ts`**

Replace lines 15–22 (the `Bindings` type):

```ts
// Cloudflare Worker env bindings
export type Bindings = {
    DB: D1Database;
    JWT_SECRET: string;
    AZURE_TENANT_ID: string;
    AZURE_CLIENT_ID: string;
    // Firebase service-account JSON (string) for sending FCM push reminders.
    FCM_SERVICE_ACCOUNT?: string;
};
```

Replace the middleware body at lines 40–45:

```ts
// Inject db and jwtSecret into every request context
app.use('*', async (c, next) => {
    const db = createDb(c.env.DB);
    c.set('db', db);
    c.set('jwtSecret', c.env.JWT_SECRET);
    await next();
});
```

- [ ] **Step 3: Update the cron handler in `server/src/scheduled.ts`**

Line 166, change:

```ts
    const db = createDb(env.DATABASE_URL);
```

to:

```ts
    const db = createDb(env.DB);
```

- [ ] **Step 4: Add the D1 binding to `server/wrangler.toml`**

Replace the whole file with:

```toml
name = "snacks-app"
main = "src/index.ts"
compatibility_date = "2024-12-01"
compatibility_flags = ["nodejs_compat"]

[dev]
ip = "0.0.0.0"
port = 8787

# Runs the daily "order closing soon" reminder. The handler only does work
# during the single minute that is `reminder_lead_minutes` (default 20) before
# the order window closes, so a per-minute schedule is intentional.
# (On D1 this is billed in rows read, not compute-hours, so the per-minute
# tick is cheap — unlike Neon, which it kept awake 24/7.)
[triggers]
crons = ["* * * * *"]

# database_id is a placeholder until the org database is created in the
# cutover task; `wrangler dev` and `--local` commands work fine with it.
[[d1_databases]]
binding = "DB"
database_name = "snacks-db"
database_id = "00000000-0000-0000-0000-000000000000"
migrations_dir = "drizzle"

# Secrets (set via: bunx wrangler secret put <KEY>)
# JWT_SECRET = "your-secret"
# AZURE_TENANT_ID = "your-azure-tenant-id"
# AZURE_CLIENT_ID = "your-azure-client-id"
# FCM_SERVICE_ACCOUNT = "<firebase service-account JSON, single line>"
```

- [ ] **Step 5: Update `server/package.json` scripts**

Replace the `scripts` block (drops `dev:bun` — D1 bindings only exist in the workerd runtime, so `bun run --hot src/index.ts` can no longer work — and replaces `db:push` with wrangler-driven migrations):

```json
"scripts": {
    "dev": "wrangler dev",
    "deploy": "wrangler deploy",
    "db:generate": "drizzle-kit generate",
    "db:migrate:local": "wrangler d1 migrations apply snacks-db --local",
    "db:migrate:remote": "wrangler d1 migrations apply snacks-db --remote",
    "db:seed": "bun run src/db/generate-seed-sql.ts && wrangler d1 execute snacks-db --local --file=seed.sql",
    "db:seed:remote": "bun run src/db/generate-seed-sql.ts && wrangler d1 execute snacks-db --remote --file=seed.sql",
    "push:test": "bun run src/dev/send-test-push.ts"
}
```

(`db:seed` scripts reference a file created in Task 3; they aren't run until then.)

- [ ] **Step 6: Type-check**

Run: `cd server && bunx tsc --noEmit`
Expected: clean, **except** errors in `src/dev/send-test-push.ts` and `src/db/seed.ts` (both still pass a string to `createDb`). Those are rewritten in Tasks 3 and 5 — any error in other files must be fixed now.

- [ ] **Step 7: Local smoke test**

```bash
cd server
bun run db:migrate:local
```
Expected: `🚣 1 migrations applied` (creates the local SQLite file under `.wrangler/state/`).

Start the dev server (leave running): `bun run dev`
Then:

```bash
curl -s http://localhost:8787/health
curl -s http://localhost:8787/api/snacks
```
Expected: `{"status":"ok","timestamp":"..."}` and `{"snacks":[]}` — proves the Worker boots, binds D1, and Drizzle queries execute.

- [ ] **Step 8: Commit**

```bash
git add server/src/db/index.ts server/src/index.ts server/src/scheduled.ts server/wrangler.toml server/package.json
git commit -m "feat(server): swap Neon HTTP driver for D1 binding"
```

---

### Task 3: Seed rewritten as SQL generation

D1 has no connection string, so the old `seed.ts` (which connected via `DATABASE_URL`) is replaced by a script that *generates* `seed.sql`, applied via `wrangler d1 execute`. **Behavior change (accepted):** the old seed also *updated* existing snacks from the catalog; the SQL version only inserts missing ones. Updates to existing snacks go through `POST /api/admin/snacks/bulk`.

**Files:**
- Create: `server/src/db/generate-seed-sql.ts`
- Delete: `server/src/db/seed.ts`
- Modify: `server/.gitignore`

**Interfaces:**
- Consumes: `menuSnackCatalog` from `server/src/db/menu_catalog.ts` (items: `{ name, category, emoji, isVeg, servingSize, sortOrder }`); the `db:seed` scripts added in Task 2.
- Produces: `server/seed.sql` (gitignored, regenerated on every run).

- [ ] **Step 1: Write the generator**

Create `server/src/db/generate-seed-sql.ts`:

```ts
import { menuSnackCatalog } from './menu_catalog';

// Mirrors the normalization the old Postgres seed used for duplicate checks.
const normalizeWhitespace = (value: string) => value.trim().replace(/\s+/g, ' ');
const normalizeName = (value: string) => normalizeWhitespace(value).toLowerCase();
const normalizeCategory = (value: string | null | undefined) => {
    if (value == null) return 'general';
    const normalized = normalizeWhitespace(value);
    return normalized.length === 0 ? 'general' : normalized.toLowerCase();
};
const q = (value: string | null | undefined) =>
    value == null ? 'NULL' : `'${value.replace(/'/g, "''")}'`;

const lines: string[] = [];

// App settings — INSERT OR IGNORE mirrors the old onConflictDoNothing().
const settings: Array<[string, string]> = [
    ['cutoff_time', '12:00'],
    ['whatsapp_number', '919876543210'],
    ['whatsapp_is_group', 'false'],
    ['holiday_country', 'IN'],
];
for (const [key, value] of settings) {
    lines.push(
        `INSERT OR IGNORE INTO app_settings (key, value, advance_order_mode, advance_window_start, advance_window_end) ` +
        `VALUES (${q(key)}, ${q(value)}, 0, '06:00', '22:00');`,
    );
}

// Menu catalog — insert-if-missing on normalized (name, category). The SQL
// normalization (lower/trim) doesn't collapse internal whitespace like the
// old JS check did; catalog names are clean so this is equivalent in practice.
for (const item of menuSnackCatalog) {
    lines.push(
        `INSERT INTO snacks (id, name, category, emoji, is_veg, is_default, is_active, serving_size, share_count, sort_order, created_at) ` +
        `SELECT ${q(crypto.randomUUID())}, ${q(item.name)}, ${q(item.category)}, ${q(item.emoji)}, ${item.isVeg ? 1 : 0}, 0, 1, ${q(item.servingSize)}, 1, ${item.sortOrder}, ${Date.now()} ` +
        `WHERE NOT EXISTS (SELECT 1 FROM snacks WHERE lower(trim(name)) = ${q(normalizeName(item.name))} ` +
        `AND lower(coalesce(nullif(trim(category), ''), 'general')) = ${q(normalizeCategory(item.category))});`,
    );
}

await Bun.write('seed.sql', lines.join('\n') + '\n');
console.log(`Wrote seed.sql with ${lines.length} statements`);
```

- [ ] **Step 2: Delete the old seed and gitignore the artifacts**

```bash
cd server
git rm src/db/seed.ts
printf 'seed.sql\nneon-export.sql\n' >> .gitignore
```

- [ ] **Step 3: Seed locally and verify**

```bash
cd server
bun run db:seed
```
Expected: `Wrote seed.sql with N statements`, then wrangler reports the execute succeeded.

With `bun run dev` running:

```bash
curl -s http://localhost:8787/api/snacks | head -c 400
```
Expected: `{"snacks":[{"id":"...","name":...` — a non-empty catalog with `isVeg`/`isActive` as JSON booleans and `createdAt` as an ISO string.

Re-run `bun run db:seed` once more, then re-check the count is unchanged (idempotency):

```bash
bunx wrangler d1 execute snacks-db --local --json --command "SELECT count(*) AS n FROM snacks"
```
Expected: same `n` after both runs.

- [ ] **Step 4: Type-check and test**

Run: `cd server && bunx tsc --noEmit && bun test`
Expected: only `src/dev/send-test-push.ts` errors remain (fixed in Task 5); schema tests still pass.

- [ ] **Step 5: Commit**

```bash
git add server/src/db/generate-seed-sql.ts server/.gitignore
git commit -m "feat(server): generate seed.sql for D1 instead of connecting via DATABASE_URL"
```

---

### Task 4: Neon → D1 data export script + local rehearsal

**Files:**
- Create: `server/src/dev/export-neon-to-d1.ts`

**Interfaces:**
- Consumes: production Neon `DATABASE_URL` (env var, user-provided); `@neondatabase/serverless` (still a dependency until Task 8).
- Produces: `server/neon-export.sql` (gitignored) — the exact file Task 6 imports into the org D1.

- [ ] **Step 1: Write the export script**

Create `server/src/dev/export-neon-to-d1.ts`:

```ts
import { neon } from '@neondatabase/serverless';

// One-off Neon → D1 exporter. Reads every table from the old Postgres
// database and writes neon-export.sql containing SQLite INSERTs matching the
// new schema (booleans → 0/1, timestamptz → epoch ms, jsonb → JSON text).
// Usage: DATABASE_URL='postgresql://...' bun run src/dev/export-neon-to-d1.ts

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
    throw new Error('Set DATABASE_URL to the Neon connection string.');
}
const sql = neon(databaseUrl);

type ColType = 'text' | 'bool' | 'ts' | 'json' | 'int';

// Insertion order satisfies foreign keys (users first).
const TABLES: Array<{ name: string; columns: Array<[string, ColType]> }> = [
    { name: 'users', columns: [['id', 'text'], ['username', 'text'], ['email', 'text'], ['microsoft_id', 'text'], ['device_id', 'text'], ['is_admin', 'bool'], ['created_at', 'ts']] },
    { name: 'snacks', columns: [['id', 'text'], ['name', 'text'], ['category', 'text'], ['emoji', 'text'], ['is_veg', 'bool'], ['is_default', 'bool'], ['is_active', 'bool'], ['serving_size', 'text'], ['share_count', 'int'], ['sort_order', 'int'], ['created_at', 'ts']] },
    { name: 'holidays', columns: [['id', 'text'], ['date', 'text'], ['name', 'text'], ['source', 'text'], ['created_by', 'text']] },
    { name: 'shutdown_days', columns: [['id', 'text'], ['date', 'text'], ['reason', 'text'], ['created_by', 'text']] },
    { name: 'app_settings', columns: [['key', 'text'], ['value', 'text'], ['advance_order_mode', 'bool'], ['advance_window_start', 'text'], ['advance_window_end', 'text']] },
    { name: 'push_tokens', columns: [['token', 'text'], ['user_id', 'text'], ['platform', 'text'], ['updated_at', 'ts']] },
    { name: 'orders', columns: [['id', 'text'], ['user_id', 'text'], ['date', 'text'], ['snack_id', 'text'], ['snack_name_snapshot', 'text'], ['snack_emoji_snapshot', 'text'], ['is_default_assigned', 'bool'], ['ordered_at', 'ts'], ['updated_at', 'ts']] },
    { name: 'sync_queue', columns: [['id', 'text'], ['user_id', 'text'], ['table_name', 'text'], ['record_id', 'text'], ['action', 'text'], ['payload', 'json'], ['created_at', 'ts'], ['synced_at', 'ts']] },
];

function lit(value: unknown, type: ColType): string {
    if (value === null || value === undefined) return 'NULL';
    switch (type) {
        case 'bool':
            return value === true || value === 't' || value === 1 ? '1' : '0';
        case 'ts': {
            const d = value instanceof Date ? value : new Date(String(value));
            if (Number.isNaN(d.getTime())) throw new Error(`Bad timestamp: ${String(value)}`);
            return String(d.getTime());
        }
        case 'int':
            return String(Number(value));
        case 'json':
            return `'${JSON.stringify(value).replace(/'/g, "''")}'`;
        case 'text':
            return `'${String(value).replace(/'/g, "''")}'`;
    }
}

const lines: string[] = ['PRAGMA defer_foreign_keys = true;'];
const counts: Record<string, number> = {};

for (const table of TABLES) {
    const rows = (await sql.query(`SELECT * FROM ${table.name}`)) as Record<string, unknown>[];
    counts[table.name] = rows.length;
    const columnNames = table.columns.map(([name]) => name).join(', ');
    for (const row of rows) {
        const values = table.columns.map(([name, type]) => lit(row[name], type)).join(', ');
        lines.push(`INSERT INTO ${table.name} (${columnNames}) VALUES (${values});`);
    }
}

await Bun.write('neon-export.sql', lines.join('\n') + '\n');
console.log('Exported row counts:', JSON.stringify(counts, null, 2));
console.log('Wrote neon-export.sql — do NOT commit this file (contains user emails).');
```

- [ ] **Step 2: Type-check**

Run: `cd server && bunx tsc --noEmit`
Expected: only the known `send-test-push.ts` errors remain.

- [ ] **Step 3: Rehearse the import locally** *(requires the Neon `DATABASE_URL`)*

```bash
cd server
DATABASE_URL='<neon-connection-string>' bun run src/dev/export-neon-to-d1.ts
```
Expected: printed per-table row counts, `neon-export.sql` written.

Reset local D1 and import (delete `.wrangler/state/` first so the rehearsal starts from empty; this wipes only local dev data):

```bash
rm -rf .wrangler/state
bun run db:migrate:local
bunx wrangler d1 execute snacks-db --local --file=neon-export.sql
bunx wrangler d1 execute snacks-db --local --json --command "SELECT (SELECT count(*) FROM users) AS users, (SELECT count(*) FROM orders) AS orders, (SELECT count(*) FROM snacks) AS snacks, (SELECT count(*) FROM push_tokens) AS push_tokens"
```
Expected: counts equal to the exporter's printed counts.

With `bun run dev` running, verify real data serializes correctly:

```bash
curl -s http://localhost:8787/api/snacks | head -c 400
curl -s http://localhost:8787/api/snacks/settings
```
Expected: real catalog rows; settings shows the production `cutoffTime`.

- [ ] **Step 4: Commit (script only — never the dump)**

```bash
git add server/src/dev/export-neon-to-d1.ts
git commit -m "feat(server): add one-off Neon-to-D1 data export script"
```

---

### Task 5: Rework `send-test-push.ts` to query D1 via wrangler

**Files:**
- Modify: `server/src/dev/send-test-push.ts`

**Interfaces:**
- Consumes: the remote `snacks-db` (via `wrangler d1 execute --remote`; works only after Task 6 creates it — local verification here is type-level plus `--list` against local).
- Produces: same CLI (`bun run push:test [--list] [--platform=ios|android|any] [--title=..] [--body=..]`).

- [ ] **Step 1: Rewrite the DB access**

Replace the entire file with:

```ts
import { existsSync, readFileSync } from 'fs';
import { isFcmConfigured, sendPushToTokens } from '../lib/fcm';

// Dev utility: sends a test FCM push to the most recently registered device.
// Post-D1 it reads tokens through `wrangler d1 execute --remote` instead of a
// database connection string.

type DevEnv = { FCM_SERVICE_ACCOUNT?: string };

function unquote(value: string): string {
    const trimmed = value.trim();
    if (
        (trimmed.startsWith('"') && trimmed.endsWith('"')) ||
        (trimmed.startsWith("'") && trimmed.endsWith("'"))
    ) {
        return trimmed.slice(1, -1);
    }
    return trimmed;
}

function loadDevVars(): DevEnv {
    const file = '.dev.vars';
    if (!existsSync(file)) return {};
    const env: DevEnv = {};
    for (const rawLine of readFileSync(file, 'utf8').split(String.fromCharCode(10))) {
        const line = rawLine.trim();
        if (!line || line.startsWith('#')) continue;
        const separator = line.indexOf('=');
        if (separator === -1) continue;
        const key = line.slice(0, separator).trim();
        if (key === 'FCM_SERVICE_ACCOUNT') env[key] = unquote(line.slice(separator + 1));
    }
    return env;
}

function argValue(name: string): string | undefined {
    const prefix = `--${name}=`;
    return process.argv.find((arg) => arg.startsWith(prefix))?.slice(prefix.length);
}

async function d1Query<T>(query: string): Promise<T[]> {
    const proc = await Bun.$`wrangler d1 execute snacks-db --remote --json --command ${query}`.quiet();
    const parsed = JSON.parse(proc.stdout.toString()) as Array<{ results?: T[] }>;
    return parsed[0]?.results ?? [];
}

const localEnv = loadDevVars();
const serviceAccount = process.env.FCM_SERVICE_ACCOUNT ?? localEnv.FCM_SERVICE_ACCOUNT;
const platform = argValue('platform') ?? 'ios';
const shouldList = process.argv.includes('--list');
const title = argValue('title') ?? 'TCC Pantry local test';
const body = argValue('body') ?? `Push test sent from local Worker dev tools at ${new Date().toLocaleTimeString()}`;

// platform is interpolated into SQL below — allowlist it.
if (!['ios', 'android', 'any'].includes(platform)) {
    throw new Error(`--platform must be ios, android, or any (got "${platform}")`);
}

type TokenRow = { token: string; platform: string | null; updated_at: number | null };

async function printTokenSummary() {
    const rows = await d1Query<{ platform: string | null; count: number; latest: number | null }>(
        'SELECT platform, count(*) AS count, max(updated_at) AS latest FROM push_tokens GROUP BY platform',
    );
    if (rows.length === 0) {
        console.log('Registered push tokens: none');
        return;
    }
    console.log('Registered push tokens by platform:');
    for (const row of rows) {
        const latest = row.latest == null ? 'unknown' : new Date(Number(row.latest)).toISOString();
        console.log(`- ${row.platform ?? 'unknown'}: ${row.count} latest=${latest}`);
    }
}

if (shouldList) {
    await printTokenSummary();
    process.exit(0);
}

if (!isFcmConfigured(serviceAccount)) {
    throw new Error('FCM_SERVICE_ACCOUNT is missing or invalid. Add the Firebase service-account JSON to server/.dev.vars.');
}

const where = platform === 'any' ? '' : `WHERE platform = '${platform}' `;
const [target] = await d1Query<TokenRow>(
    `SELECT token, platform, updated_at FROM push_tokens ${where}ORDER BY updated_at DESC LIMIT 1`,
);

if (!target) {
    await printTokenSummary();
    throw new Error(`No registered ${platform} push token found. Run the app, sign in, and allow notifications first.`);
}

const [result] = await sendPushToTokens(serviceAccount, [target.token], { title, body }, 1);
if (!result?.ok) {
    const error = result?.error ?? 'no response';
    if (error.includes('THIRD_PARTY_AUTH_ERROR')) {
        throw new Error(
            'FCM could not authenticate with APNs for this iOS app. Upload or fix the APNs auth key/certificate in Firebase Console > Project settings > Cloud Messaging for bundle id company.thecloud.pantry. Original FCM response: ' +
                error,
        );
    }
    throw new Error(`FCM send failed with status ${result?.status ?? 'unknown'}: ${error}`);
}

const updatedLabel = target.updated_at == null ? 'unknown time' : new Date(Number(target.updated_at)).toISOString();
console.log(`Sent local test push to latest ${target.platform ?? platform} device token updated at ${updatedLabel}.`);
```

- [ ] **Step 2: Type-check everything is now clean**

Run: `cd server && bunx tsc --noEmit`
Expected: zero errors anywhere in the project.

- [ ] **Step 3: Sanity-run the summary path against local data**

Temporarily verify the query/parsing logic against the local rehearsal DB (swap `--remote` for `--local` only for this check):

```bash
cd server
bunx wrangler d1 execute snacks-db --local --json --command "SELECT platform, count(*) AS count, max(updated_at) AS latest FROM push_tokens GROUP BY platform"
```
Expected: JSON with `results` matching what Task 4 imported. (`bun run push:test -- --list` itself needs the remote DB from Task 6.)

- [ ] **Step 4: Commit**

```bash
git add server/src/dev/send-test-push.ts
git commit -m "chore(server): read push tokens via wrangler d1 in test-push tool"
```

---

### Task 6: Org-account cutover (create D1, import data, deploy Worker)

**This is the only task with production impact. Run it in the evening (after the order cutoff), and treat the window between the export and Task 7's shim deploy as a write-freeze — anything written to the old Neon-backed Worker after the export is lost.**

**Files:**
- Modify: `server/wrangler.toml` (real `database_id`)

**Interfaces:**
- Consumes: `neon-export.sql` regeneration (Task 4 script), migrations (Task 1), secrets values (user-provided).
- Produces: live org Worker at `https://snacks-app.<ORG_SUBDOMAIN>.workers.dev` — the hostname Task 7 forwards to and Task 8 documents. Record `<ORG_SUBDOMAIN>` from the deploy output.

- [ ] **Step 1: Confirm wrangler is on the org account**

Run: `cd server && bunx wrangler whoami`
Expected: the **org** account (not the personal one that owns `paveenkumar-dev.workers.dev`). If wrong: `bunx wrangler logout && bunx wrangler login`, or set `CLOUDFLARE_ACCOUNT_ID` to the org account id. **Do not proceed until this shows the org.**

- [ ] **Step 2: Create the database and record its id**

```bash
bunx wrangler d1 create snacks-db
```
Expected output includes `database_id = "<uuid>"`. Edit `server/wrangler.toml` and replace `00000000-0000-0000-0000-000000000000` with that uuid.

- [ ] **Step 3: Apply migrations remotely**

```bash
bun run db:migrate:remote
```
Expected: `1 migrations applied` against the org `snacks-db`.

- [ ] **Step 4: Fresh export from Neon, import to D1** *(write-freeze starts now)*

```bash
DATABASE_URL='<neon-connection-string>' bun run src/dev/export-neon-to-d1.ts
bunx wrangler d1 execute snacks-db --remote --file=neon-export.sql
bunx wrangler d1 execute snacks-db --remote --json --command "SELECT (SELECT count(*) FROM users) AS users, (SELECT count(*) FROM orders) AS orders, (SELECT count(*) FROM snacks) AS snacks, (SELECT count(*) FROM push_tokens) AS push_tokens"
```
Expected: remote counts equal the exporter's printed counts.

- [ ] **Step 5: Set secrets on the org Worker**

```bash
bunx wrangler secret put JWT_SECRET
bunx wrangler secret put AZURE_TENANT_ID
bunx wrangler secret put AZURE_CLIENT_ID
bunx wrangler secret put FCM_SERVICE_ACCOUNT
```
(Reuse the old `JWT_SECRET` value if available so existing sessions survive; a new value forces a one-time re-login for everyone.)

- [ ] **Step 6: Deploy and verify**

```bash
bun run deploy
```
Expected output ends with the org URL: `https://snacks-app.<ORG_SUBDOMAIN>.workers.dev`. **Record `<ORG_SUBDOMAIN>` — Tasks 7 and 8 need it.**

```bash
curl -s https://snacks-app.<ORG_SUBDOMAIN>.workers.dev/health
curl -s https://snacks-app.<ORG_SUBDOMAIN>.workers.dev/api/snacks | head -c 300
curl -s https://snacks-app.<ORG_SUBDOMAIN>.workers.dev/api/snacks/settings
```
Expected: health ok; real catalog data; production cutoff settings. Also verify an authenticated flow end-to-end by pointing a dev build of the app at the new URL: `flutter run --dart-define=API_BASE_URL=https://snacks-app.<ORG_SUBDOMAIN>.workers.dev/api`, sign in, and place a test order.

- [ ] **Step 7: Commit the real database id**

```bash
git add server/wrangler.toml
git commit -m "chore(server): point wrangler at org D1 database"
```

---

### Task 7: Legacy-URL proxy shim + Flutter base URL

Old app installs call `snacks-app.paveenkumar-dev.workers.dev` (the hardcoded default). Overwrite that personal-account Worker with a forwarder so they keep working, then point new builds at the org URL.

**Files:**
- Create: `legacy-proxy/wrangler.toml`
- Create: `legacy-proxy/src/index.ts`
- Modify: `app/lib/core/network/api_client.dart:11-12`

**Interfaces:**
- Consumes: `<ORG_SUBDOMAIN>` recorded in Task 6.
- Produces: old URL transparently serves the org Worker (which ends the write-freeze); new app builds default to the org URL.

- [ ] **Step 1: Create the shim**

Create `legacy-proxy/wrangler.toml`:

```toml
# Deployed to the PERSONAL account under the old Worker name, so the legacy
# URL https://snacks-app.paveenkumar-dev.workers.dev keeps serving traffic.
name = "snacks-app"
main = "src/index.ts"
compatibility_date = "2024-12-01"
```

Create `legacy-proxy/src/index.ts` (replace `<ORG_SUBDOMAIN>` with the Task 6 value):

```ts
// Forwards all traffic from the legacy personal-account URL to the org
// Worker, so app builds shipped before the D1 migration keep working.
const ORG_HOST = 'snacks-app.<ORG_SUBDOMAIN>.workers.dev';

export default {
    fetch(request: Request): Promise<Response> {
        const url = new URL(request.url);
        url.hostname = ORG_HOST;
        return fetch(new Request(url.toString(), request));
    },
};
```

- [ ] **Step 2: Deploy to the PERSONAL account**

```bash
cd legacy-proxy
bunx wrangler logout && bunx wrangler login   # authenticate as the personal account
bunx wrangler deploy
```
Expected: deploys as `snacks-app` on the personal account, replacing the old Neon-backed Worker. (This also removes the old Worker's cron trigger — Neon stops being queried entirely.) Re-login to the org account afterwards if you keep working.

- [ ] **Step 3: Verify the legacy URL end-to-end**

```bash
curl -s https://snacks-app.paveenkumar-dev.workers.dev/health
curl -s https://snacks-app.paveenkumar-dev.workers.dev/api/snacks | head -c 300
```
Expected: identical responses to the org URL — old app installs now transparently use D1. Write-freeze over.

- [ ] **Step 4: Point new app builds at the org URL**

In `app/lib/core/network/api_client.dart`, replace the default URL (around lines 11–12):

```dart
      'https://snacks-app.paveenkumar-dev.workers.dev/api';
```

with:

```dart
      'https://snacks-app.<ORG_SUBDOMAIN>.workers.dev/api';
```

Run: `cd app && flutter analyze`
Expected: no new issues. Ship this with the next normal app release — no urgency, the shim covers old builds indefinitely.

- [ ] **Step 5: Commit**

```bash
git add legacy-proxy app/lib/core/network/api_client.dart
git commit -m "feat: forward legacy worker URL to org account; default app to org API"
```

---

### Task 8: Cleanup + docs

**Files:**
- Modify: `server/package.json` (drop `@neondatabase/serverless`, `dotenv-cli`)
- Delete: `server/src/dev/export-neon-to-d1.ts`, `server/neon-export.sql`, `server/seed.sql`
- Modify: `CLAUDE.md` (root)

**Interfaces:**
- Consumes: successful cutover (Task 6) and shim (Task 7) — do not start before both are verified in production.
- Produces: repo with no Neon references outside git history.

- [ ] **Step 1: Remove the Neon dependency and one-off script**

```bash
cd server
bun remove @neondatabase/serverless
git rm src/dev/export-neon-to-d1.ts
rm -f neon-export.sql seed.sql
bunx tsc --noEmit && bun test
```
Expected: clean type-check, all tests pass.

- [ ] **Step 2: Update root `CLAUDE.md`**

Make these replacements:
- `` `server/` — Cloudflare Workers backend (Hono + Drizzle ORM + Neon Postgres) running on Bun `` → `` `server/` — Cloudflare Workers backend (Hono + Drizzle ORM + Cloudflare D1) running on Bun ``
- In the server commands block, replace the `dev:bun` / `db:push` / `db:seed` lines with:

```bash
bun install
bun run dev                 # wrangler dev on :8787 (local D1 via miniflare)
bun run deploy              # wrangler deploy (org account)
bun run db:generate         # drizzle-kit generate migrations from schema.ts
bun run db:migrate:local    # apply migrations to local D1
bun run db:migrate:remote   # apply migrations to org D1
bun run db:seed             # generate seed.sql and apply to local D1
```

- Replace the secrets sentence with: `` Secrets are set with `bunx wrangler secret put <KEY>` for: `JWT_SECRET`, `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `FCM_SERVICE_ACCOUNT` (listed in [wrangler.toml](server/wrangler.toml)). The database is a D1 binding (`DB`), not a secret. ``
- In Architecture → Server, replace the middleware sentence with: `Per-request middleware constructs a Drizzle client over the D1 binding (c.env.DB) and stashes it in c.set('db', ...) along with jwtSecret.`
- Add one line to the server architecture section: `The legacy personal-account URL (snacks-app.paveenkumar-dev.workers.dev) is a proxy Worker in legacy-proxy/ forwarding to the org Worker.`

- [ ] **Step 3: Final full verification**

```bash
cd server && bunx tsc --noEmit && bun test
cd ../app && flutter analyze
```
Expected: all clean.

- [ ] **Step 4: Commit**

```bash
git add server/package.json server/bun.lock CLAUDE.md
git commit -m "chore: finish Neon-to-D1 migration cleanup and docs"
```

---

## Post-migration notes (no action required)

- **Neon decommission:** after a few days of soak with no issues, delete the Neon project from the personal account (user action in the Neon console). Until then it sits idle — with the old Worker replaced by the shim, nothing queries it, so it scales to zero and burns ~no compute.
- **The per-minute cron is fine on D1** (a few rows read per tick against a 5M rows/day free allowance), so the original compute-burn issue is structurally gone. Narrowing the schedule is optional hygiene, not needed.
- **Rollback path:** until Task 8 runs, rollback = redeploy the pre-migration commit from the personal account with the old secrets; Neon still has all data up to the export timestamp.
