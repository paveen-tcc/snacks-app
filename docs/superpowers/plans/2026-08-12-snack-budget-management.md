# Snack Budget Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add admin-only whole-rupee catalog pricing, editable daily actual-purchase records, and Day/Week/Month expense reporting without changing employee orders or WhatsApp output.

**Architecture:** The server snapshots price/share/category onto new orders and materializes a separate `daily_purchase_items` ledger for current-month-onward reporting. Flutter keeps employee flows untouched, extends Manage Snacks with price maintenance, and adds a fifth admin-only Budget destination backed by typed report models and admin endpoints.

**Tech Stack:** Cloudflare Workers, Hono, Drizzle ORM, D1/SQLite, Bun tests, Flutter/Dart, Dio, Material 3, flutter_test.

## Global Constraints

- Prices are non-negative whole Indian rupees; no decimal storage or display.
- Employee order rows remain the original order record and are never rewritten by budget edits.
- Daily purchase records stay editable indefinitely; there is no finalized/locked state.
- Both snacks and drinks are included, with All/Snacks/Drinks filtering and subtotals.
- Reporting starts at the first day of the current office month; older data is excluded.
- Existing current-month orders may fall back to current catalog prices during first materialization.
- Existing Summary and WhatsApp item/quantity content must not change.
- Do not add a chart package; use existing design-system primitives.
- Run D1 migrations only against the local Wrangler database. Do not deploy or push.
- Preserve unrelated worktree changes, especially `upload-keystore.jks` and `.superpowers/`.

## File structure

- `server/src/db/schema.ts` — catalog price, order snapshots, daily purchase ledger schema.
- `server/drizzle/0001_*.sql` — generated D1 migration.
- `server/src/lib/budget.ts` — materialization, validation, mutation, and aggregate logic independent of HTTP.
- `server/src/routes/budget.ts` — admin-only HTTP contract for reports and daily edits.
- `server/src/routes/{orders,admin,snacks}.ts` — order snapshots, catalog price CRUD, employee-safe public snack selection.
- `server/src/db/schema.test.ts` — real-migration schema verification.
- `server/src/lib/budget.test.ts` — budget behavior and historical-price regression tests.
- `app/lib/core/formatters/rupees.dart` — shared whole-rupee parsing/formatting.
- `app/lib/data/models/budget_models.dart` — typed budget API payloads.
- `app/lib/data/repositories/admin_repository.dart` — budget API methods.
- `app/lib/presentation/admin/snacks_screen.dart` — price editing, display, and CSV parsing.
- `app/lib/presentation/admin/budget_screen.dart` — period selection, report loading, and day-editor orchestration.
- `app/lib/presentation/admin/budget_widgets.dart` — focused KPI, list, and editor components.
- `app/lib/presentation/shell/main_shell.dart` — fifth admin-only Budget destination.
- `app/test/{rupees,budget_models,budget_screen}_test.dart` — formatter, decoding, navigation/filter/editor coverage.

---

### Task 1: D1 pricing and purchase-ledger foundation

**Files:**
- Modify: `server/src/db/schema.ts`
- Modify: `server/src/db/schema.test.ts`
- Generate: `server/drizzle/0001_*.sql`

**Interfaces:**
- Produces: `snacks.priceRupees: number`
- Produces: nullable `orders.snackPriceRupeesSnapshot`, `orders.snackShareCountSnapshot`, `orders.snackCategorySnapshot`
- Produces: exported `dailyPurchaseItems` table with camel-case Drizzle fields matching the design spec.

- [ ] **Step 1: Add a failing real-migration schema test**

Extend `server/src/db/schema.test.ts` to insert a priced snack, an order with snapshots, and generated/manual daily purchase rows:

```ts
test('budget columns and daily purchase items use integer defaults', async () => {
    const db = createTestDb();
    const [snack] = await db.insert(snacks)
        .values({ name: 'Tea', category: 'Drinks', priceRupees: 18 })
        .returning();
    expect(snack!.priceRupees).toBe(18);

    const [line] = await db.insert(dailyPurchaseItems).values({
        date: '2026-08-12',
        sourceKey: `${snack!.id}::Tea`,
        sourceSnackId: snack!.id,
        name: 'Tea',
        itemType: 'drink',
        quantity: 3,
        unitPriceRupees: 18,
    }).returning();
    expect(line!.isEdited).toBe(false);
    expect(line!.isRemoved).toBe(false);
});
```

- [ ] **Step 2: Run the schema test and confirm red**

Run: `cd server && bun test src/db/schema.test.ts`

Expected: compile failure because the price/snapshot/table exports do not exist.

- [ ] **Step 3: Add the Drizzle schema**

Use integer fields and a composite unique index:

```ts
export const dailyPurchaseItems = sqliteTable('daily_purchase_items', {
    id: uuidPk('id'),
    date: text('date').notNull(),
    sourceKey: text('source_key'),
    sourceSnackId: text('source_snack_id'),
    name: text('name', { length: 100 }).notNull(),
    itemType: text('item_type', { enum: ['snack', 'drink'] }).notNull(),
    quantity: integer('quantity').notNull(),
    unitPriceRupees: integer('unit_price_rupees').notNull(),
    isEdited: integer('is_edited', { mode: 'boolean' }).notNull().default(false),
    isRemoved: integer('is_removed', { mode: 'boolean' }).notNull().default(false),
    createdAt: timestampMs('created_at').$defaultFn(() => new Date()),
    updatedAt: timestampMs('updated_at').$defaultFn(() => new Date()),
}, (t) => ({
    dateIdx: index('daily_purchase_items_date_idx').on(t.date),
    dateSourceUnique: uniqueIndex('daily_purchase_items_date_source_unique').on(t.date, t.sourceKey),
}));
```

Add `priceRupees` to `snacks` with default `0`, and the three nullable snapshot columns to `orders`.

- [ ] **Step 4: Generate the migration**

Run: `cd server && bun run db:generate`

Expected: one new migration adding four columns and the `daily_purchase_items` table/indexes without altering existing data.

- [ ] **Step 5: Run the real-migration test green**

Run: `cd server && bun test src/db/schema.test.ts`

Expected: all schema tests pass using every migration in order.

### Task 2: Catalog price snapshots and admin catalog management

**Files:**
- Modify: `server/src/routes/orders.ts`
- Modify: `server/src/routes/admin.ts`
- Modify: `server/src/routes/snacks.ts`
- Modify: `server/src/db/generate-seed-sql.ts`
- Test: `server/src/db/schema.test.ts`

**Interfaces:**
- Consumes: Task 1 schema fields.
- Produces: admin snack JSON with `priceRupees` and order rows with price/share/category snapshots.
- Preserves: public `/api/snacks` JSON fields currently consumed by Flutter, excluding price.

- [ ] **Step 1: Add failing snapshot and validation tests**

Add direct database assertions for snapshot columns and extract/export this validator from `admin.ts` for a unit test:

```ts
export function normalizePriceRupees(value: unknown): number {
    const parsed = Number(value);
    if (!Number.isInteger(parsed) || parsed < 0) {
        throw new Error('priceRupees must be a whole number greater than or equal to 0');
    }
    return parsed;
}
```

Cover `0`, `25`, `-1`, and `12.5`.

- [ ] **Step 2: Run focused tests red**

Run: `cd server && bun test src/db/schema.test.ts src/routes/admin-price.test.ts`

Expected: missing validator and missing snapshot behavior.

- [ ] **Step 3: Snapshot catalog values during order placement**

Select the additional fields and populate every saved order:

```ts
const selectedSnacks = await db.select({
    id: snacks.id,
    name: snacks.name,
    emoji: snacks.emoji,
    category: snacks.category,
    shareCount: snacks.shareCount,
    priceRupees: snacks.priceRupees,
}).from(snacks).where(inArray(snacks.id, uniqueSnackIds));

return {
    // existing fields
    snackPriceRupeesSnapshot: snack.priceRupees,
    snackShareCountSnapshot: snack.shareCount,
    snackCategorySnapshot: snack.category,
};
```

- [ ] **Step 4: Extend catalog create/update/bulk validation**

Accept `priceRupees`, default omitted legacy values to `0`, reject negative/fractional values, and include the field in bulk normalized types and inserts. Add `price_rupees` to seed SQL and to the public CSV template header/example.

- [ ] **Step 5: Keep public prices private**

Replace `.select()` in `server/src/routes/snacks.ts` with an explicit projection of the existing public fields (`id`, `name`, `category`, `emoji`, `isVeg`, `isDefault`, `isActive`, `servingSize`, `shareCount`, `sortOrder`, `createdAt`) and omit `priceRupees`.

- [ ] **Step 6: Run focused and full server tests**

Run: `cd server && bun test`

Expected: all tests pass and existing summary tests remain unchanged.

### Task 3: Budget materialization, CRUD, and reports

**Files:**
- Create: `server/src/lib/budget.ts`
- Create: `server/src/lib/budget.test.ts`
- Create: `server/src/routes/budget.ts`
- Modify: `server/src/index.ts`

**Interfaces:**
- Consumes: Task 1 schema and `Database` from `server/src/db/index.ts`.
- Produces: `getBudgetDay(db, date, officeToday)`, `getBudgetRange(db, start, end, officeToday)`, `createPurchaseItem`, `updatePurchaseItem`, and `removePurchaseItem`.
- Produces HTTP JSON:

```ts
type BudgetTotals = { total: number; snacks: number; drinks: number };
type BudgetLine = {
  id: string; date: string; name: string; itemType: 'snack' | 'drink';
  quantity: number; unitPriceRupees: number; lineTotalRupees: number;
  isEdited: boolean; isManual: boolean;
};
type BudgetRangeResponse = {
  start: string; end: string; totals: BudgetTotals;
  days: Array<{ date: string; totals: BudgetTotals }>;
  items: Array<{ name: string; itemType: 'snack' | 'drink'; quantity: number; totalRupees: number }>;
};
```

- [ ] **Step 1: Write failing materialization tests**

Use an in-memory migrated SQLite database and fixed dates. Cover:

```ts
test('materializes ceil(count/shareCount) using order price snapshot', async () => {
  // Three order rows, share snapshot 2, price snapshot 40 => quantity 2, total 80.
});

test('catalog price changes do not alter an existing purchase line', async () => {
  // Materialize at 40, update snacks.priceRupees to 55, read again => still 40.
});

test('edited and removed generated lines are not overwritten', async () => {});
test('custom lines contribute to the correct snack/drink totals', async () => {});
test('dates before the office month start are rejected', async () => {});
```

- [ ] **Step 2: Run budget tests red**

Run: `cd server && bun test src/lib/budget.test.ts`

Expected: module/functions missing.

- [ ] **Step 3: Implement strict date and integer validation**

Use `YYYY-MM-DD` round-trip validation, `start <= end`, a maximum range of 366 days, current-office-month lower bound, non-empty normalized names, quantity integer `>= 1`, price integer `>= 0`, and `itemType` in `{snack, drink}`.

- [ ] **Step 4: Implement source synchronization**

Aggregate orders by date, snack ID, and name snapshot. Use snapshot values first and catalog fallback only when the snapshot is null. Determine drink type from snapshot/fallback category equal to `drinks` case-insensitively. Insert missing source keys, update quantity only for untouched rows, tombstone disappeared untouched rows, and never overwrite `isEdited=true` rows.

- [ ] **Step 5: Implement daily CRUD and authoritative totals**

All `PUT` mutations set `isEdited=true`; all deletes set `isRemoved=true`. Exclude removed rows from day/range totals. Return `lineTotalRupees` from the server.

- [ ] **Step 6: Implement range aggregation**

Synchronize every distinct order date in range, return zero-filled daily entries across the selected range, and aggregate item quantities/totals by `name + itemType`.

- [ ] **Step 7: Add admin-only Hono routes**

Mount `budgetRoutes` at `/api/admin/budget` before/alongside the existing admin routes. Apply `authMiddleware` and `adminMiddleware` within the router. Route order must put `/` before `/:date` and item CRUD beneath `/:date/items`.

- [ ] **Step 8: Run budget and full server tests green**

Run: `cd server && bun test src/lib/budget.test.ts && bun test`

Expected: all tests pass; existing `/api/admin/summary` behavior is unchanged.

### Task 4: Whole-rupee Manage Snacks UI

**Files:**
- Create: `app/lib/core/formatters/rupees.dart`
- Modify: `app/lib/presentation/admin/snacks_screen.dart`
- Modify: `app/lib/data/repositories/admin_repository.dart`
- Create: `app/test/rupees_test.dart`

**Interfaces:**
- Produces: `int? parseWholeRupees(String value)` and `String formatRupees(num value)`.
- Consumes: existing map-based admin snack endpoint with `priceRupees`.
- Produces create/update/bulk payloads containing integer `priceRupees`.

- [ ] **Step 1: Write failing formatter tests**

```dart
test('whole rupees reject fractions and negatives', () {
  expect(parseWholeRupees('0'), 0);
  expect(parseWholeRupees('125'), 125);
  expect(parseWholeRupees('-1'), isNull);
  expect(parseWholeRupees('12.5'), isNull);
  expect(formatRupees(125), '₹125');
});
```

- [ ] **Step 2: Run formatter test red**

Run: `cd app && flutter test test/rupees_test.dart`

Expected: formatter library missing.

- [ ] **Step 3: Implement the formatter**

Parse only trimmed digit strings with `RegExp(r'^\d+$')`. Format with the rupee symbol and no decimal digits.

- [ ] **Step 4: Add price to Add/Edit Snack**

Initialize a numeric controller from `existing['priceRupees'] ?? 0`, use `TextInputType.number`, validate through `parseWholeRupees`, and send `priceRupees` in both create and update payloads. Keep `₹0` valid.

- [ ] **Step 5: Surface prices and setup gaps**

Show `formatRupees(price)` in each admin snack tile. When zero, add a compact `Price needed` status using warning colors while still displaying `₹0`.

- [ ] **Step 6: Extend bulk upload**

Use the column order `name, category, image URL, veg/non-veg, serving size, share count, price rupees, is active, sort order`; update parser indices, example copy, and payloads.

- [ ] **Step 7: Format, test, and analyze focused files**

Run: `cd app && dart format lib/core/formatters/rupees.dart lib/presentation/admin/snacks_screen.dart test/rupees_test.dart`

Run: `cd app && flutter test test/rupees_test.dart && flutter analyze`

Expected: formatter test passes and analyzer reports no issues introduced by this task.

### Task 5: Budget models, repository, screen, and navigation

**Files:**
- Create: `app/lib/data/models/budget_models.dart`
- Modify: `app/lib/data/repositories/admin_repository.dart`
- Create: `app/lib/presentation/admin/budget_widgets.dart`
- Create: `app/lib/presentation/admin/budget_screen.dart`
- Modify: `app/lib/presentation/shell/main_shell.dart`
- Create: `app/test/budget_models_test.dart`
- Create: `app/test/budget_screen_test.dart`

**Interfaces:**
- Consumes: Task 3 JSON contract and Task 4 `formatRupees`/`parseWholeRupees`.
- Produces: `BudgetTotals`, `BudgetLine`, `BudgetDay`, `BudgetRange` with `fromJson` factories.
- Produces repository methods:

```dart
Future<BudgetDay> getBudgetDay(String date);
Future<BudgetRange> getBudgetRange({required String start, required String end});
Future<void> addBudgetItem(String date, Map<String, dynamic> data);
Future<void> updateBudgetItem(String date, String id, Map<String, dynamic> data);
Future<void> removeBudgetItem(String date, String id);
```

- [ ] **Step 1: Write failing JSON model tests**

Decode representative server payloads and assert totals, day lists, item types, integer prices, and line totals. Include missing optional arrays as empty collections.

- [ ] **Step 2: Run model tests red**

Run: `cd app && flutter test test/budget_models_test.dart`

Expected: model library/classes missing.

- [ ] **Step 3: Implement immutable typed models and repository methods**

Use defensive `num?.toInt() ?? 0` parsing and encode dates as `YYYY-MM-DD`. Keep Dio error propagation consistent with the existing repository.

- [ ] **Step 4: Write failing screen tests with injected loaders/mutations**

Make `BudgetScreen` accept optional callback dependencies for tests while defaulting to `AdminRepository` methods in production. Test:

```dart
testWidgets('switches All Snacks Drinks without changing totals source', (tester) async {});
testWidgets('day editor validates and saves a whole-rupee custom item', (tester) async {});
testWidgets('week day tap opens the selected day editor', (tester) async {});
```

- [ ] **Step 5: Build focused reusable widgets**

In `budget_widgets.dart`, implement summary KPI cards, the All/Snacks/Drinks segmented control, daily total rows/bars, item total rows, purchase line cards, and the add/edit bottom sheet. Use existing `AppSpacing`, `AppRadii`, palette, buttons, and glass surface patterns.

- [ ] **Step 6: Implement period/date state and loading**

Day uses one date; Week uses Monday through Sunday; Month uses calendar month boundaries. Previous/next moves by the selected period. A calendar action updates the anchor. Filter visible line/item rows client-side by item type while displaying server-provided snack/drink subtotals.

- [ ] **Step 7: Implement day mutations**

Add custom, edit name/type/quantity/unit price, and remove with confirmation. Disable only the active mutation, reload the authoritative day/range on success, retain data on refresh failure, and show actionable SnackBars.

- [ ] **Step 8: Add the fifth admin-only destination**

Append Budget after Summary, update the admin maximum index from `3` to `4`, include `BudgetScreen(isActive: _index == 4)` in the `IndexedStack`, and keep non-admin indices unchanged.

- [ ] **Step 9: Format and run focused tests**

Run: `cd app && dart format lib/data/models/budget_models.dart lib/data/repositories/admin_repository.dart lib/presentation/admin/budget_screen.dart lib/presentation/admin/budget_widgets.dart lib/presentation/shell/main_shell.dart test/budget_models_test.dart test/budget_screen_test.dart`

Run: `cd app && flutter test test/budget_models_test.dart test/budget_screen_test.dart`

Expected: all focused tests pass.

### Task 6: Local migration, integration, and emulator verification

**Files:**
- Verify only: all files from Tasks 1–5
- Local runtime state: `server/.wrangler/state/**` (must remain untracked)

**Interfaces:**
- Consumes all previous tasks.
- Produces a locally migrated server and running Flutter debug build with the end-to-end admin flow verified.

- [ ] **Step 1: Review the combined diff and generated migration**

Run: `git status --short`

Run: `git diff --check`

Confirm no unrelated file is staged or modified by the feature and the migration contains only additive schema changes.

- [ ] **Step 2: Apply the D1 migration locally**

Run: `cd server && bun run db:migrate:local`

Expected: Wrangler applies the new migration to local `snacks-db`; no `--remote` command is used.

- [ ] **Step 3: Run complete server verification**

Run: `cd server && bun test`

Run: `cd server && bunx tsc --noEmit`

Expected: zero test/type failures.

- [ ] **Step 4: Run complete Flutter verification**

Run: `cd app && dart format --output=none --set-exit-if-changed lib test`

Run: `cd app && flutter analyze`

Run: `cd app && flutter test`

Expected: zero format, analyzer, or test failures.

- [ ] **Step 5: Start the local Worker and Flutter app**

Run the Worker with `cd server && bun run dev`, then run Flutter on `PixelM4` with a local API base URL if the app supports a compile-time override. Do not alter the production default URL permanently.

- [ ] **Step 6: Smoke-test the feature on `PixelM4`**

Verify as an admin:

1. Manage Snacks accepts and redisplays a whole-rupee price.
2. Budget appears only for admin and opens without disturbing Summary.
3. Day view materializes current-month orders.
4. A line can be substituted/renamed, repriced, requantified, removed, and supplemented with a custom snack or drink.
5. Day/Week/Month and All/Snacks/Drinks totals update correctly.
6. Today’s Summary WhatsApp message still contains only item names and quantities.

- [ ] **Step 7: Create local implementation commits without pushing**

Stage only feature files and generated migration; never stage `upload-keystore.jks`, `.superpowers/`, or Wrangler local state. Create scoped local commits for backend and Flutter work. Do not run `git push`.
