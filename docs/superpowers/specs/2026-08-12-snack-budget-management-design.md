# Snack Budget Management Design

## Goal

Add admin-only price and expense reporting without changing employee ordering or the existing WhatsApp summary. Admins can maintain catalog prices, correct what was actually purchased each day, and inspect day, week, and month totals split between snacks and drinks.

## Confirmed product decisions

- Employee orders remain unchanged as the original order record.
- Actual purchases are stored separately as editable daily purchase lines.
- Daily purchase lines never have a finalized or locked state; admins may edit them at any time.
- Catalog prices are defaults. A price is copied into the order/purchase history so later catalog price changes do not alter historical totals.
- Prices are whole Indian rupees. Decimals, limits, approvals, pantry reconciliation, invoice uploads, and budget targets are out of scope.
- Both snacks and hot drinks count toward the total, with independent Snacks and Drinks views/subtotals.
- Admins may add a custom one-off daily item without adding it to the catalog.
- Financial reporting begins with the current calendar month. Existing orders earlier in this month are backfilled from current catalog prices and remain editable. Older orders are excluded.
- The existing Today’s Summary and “Send to WhatsApp” message remain item-and-quantity only.
- Budget is a fifth, admin-only bottom navigation destination (visual Option A).
- Everything is implemented and migrated locally; no remote deployment or push is part of this work.

## Considered approaches

### 1. Separate daily purchase ledger (selected)

Keep original orders immutable from the budget feature and materialize an editable purchase list for each day. This cleanly separates “what employees requested” from “what the office bought,” supports substitutions, and preserves historical prices.

### 2. Edit employee orders directly

This needs fewer tables, but substitutions would rewrite employee history and make it impossible to compare requested and purchased items. It was rejected explicitly.

### 3. Adjustment-only event ledger

Store only deltas such as replacements and price corrections on top of live order aggregates. This offers a detailed audit trail, but makes reads and UI behavior substantially more complex than the reporting-only requirement. It is unnecessary for the first version.

## Data model

### `snacks`

Add:

- `price_rupees integer not null default 0`

This is the current default procurement-unit price shown and edited in Manage Snacks. Public employee screens do not display it.

### `orders`

Add nullable snapshot fields:

- `snack_price_rupees_snapshot integer`
- `snack_share_count_snapshot integer`
- `snack_category_snapshot text`

New orders populate these values from the selected catalog item. Existing current-month orders fall back to the catalog values during one-time materialization. Price and share-count snapshots prevent later catalog edits from changing financial history.

### `daily_purchase_items`

Create a table with:

- `id text primary key`
- `date text not null` (`YYYY-MM-DD`)
- `source_key text` (stable snack-ID plus order-name-snapshot identity; null for manual lines)
- `source_snack_id text` (nullable reference for traceability)
- `name text not null` (editable snapshot)
- `item_type text not null` (`snack` or `drink`)
- `quantity integer not null`
- `unit_price_rupees integer not null`
- `is_edited integer/boolean not null default false`
- `is_removed integer/boolean not null default false`
- `created_at integer`
- `updated_at integer`

Indexes:

- unique `(date, source_key)` for non-null generated source keys
- `(date)` for report ranges

Validation requires a non-empty name, recognized item type, quantity of at least one for visible lines, and non-negative whole-rupee price.

## Materialization and historical behavior

The server derives source groups from orders using snack ID plus the stored name snapshot, preserving existing distinctions such as regular and sugar-free drinks. That same pair forms the generated line's stable source key. Procurement quantity continues to use `ceil(selected count / share count)`.

When a budget date/range is read, the server synchronizes generated lines:

- Missing grouped-order lines are inserted with the order snapshot values.
- Unedited generated lines may receive current order quantity changes.
- Admin-edited or removed lines are never overwritten by synchronization.
- Manual lines are never touched by synchronization.
- A generated line that disappears from the source orders is hidden only when it has not been edited.

For dates earlier in the current month that predate snapshot fields, generation uses the current catalog price, share count, and category. Once generated, those line values are persistent and independent of later catalog changes. Dates before the current month are not materialized or included.

## Server boundaries and API

Budget services live separately from the existing summary route so WhatsApp behavior cannot accidentally inherit price fields.

Admin-only endpoints:

- `GET /api/admin/budget?start=YYYY-MM-DD&end=YYYY-MM-DD`
  - synchronizes missing current-month purchase lines in the range
  - returns overall, snack, and drink totals; daily totals; and item totals
- `GET /api/admin/budget/:date`
  - returns the editable purchase list and day totals
- `POST /api/admin/budget/:date/items`
  - creates a one-off custom line
- `PUT /api/admin/budget/:date/items/:id`
  - updates name, type, quantity, or unit price and marks the line edited
- `DELETE /api/admin/budget/:date/items/:id`
  - marks any line removed; generated tombstones prevent synchronization from recreating it

Existing snack create, update, and bulk-create endpoints accept and validate `priceRupees`. The CSV template gains a price column.

The public snack endpoint switches to an explicit field selection that excludes `priceRupees`, keeping catalog prices admin-only.

All calculations are performed with integers:

`line total = quantity × unit price rupees`

The server remains authoritative for totals. Flutter renders returned totals and does not recompute historical aggregates independently.

## Flutter experience

### Manage Snacks

- Add a `Price (₹)` whole-number field to Add/Edit Snack.
- Show the price on each admin snack list row.
- Include price in bulk upload parsing and the downloadable CSV template.
- Existing `₹0` items remain editable and are visually marked “Price needed” to make initial setup clear.

Price does not need to be added to the employee-facing Drift snack cache because it is an admin-only concern.

### Budget tab

Add an admin-only fifth bottom destination after Summary. Preserve the existing four destinations and indices for non-admin users.

The screen contains:

- Period selector: Day / Week / Month.
- Previous/next controls and a date picker.
- Type tabs: All / Snacks / Drinks.
- Summary cards: selected-period total plus snack and drink subtotals.
- Day view: editable purchase-line cards showing quantity, unit price, and line total; add custom item; edit; remove.
- Week view: Monday–Sunday daily totals and period item totals; tapping a date opens its Day editor.
- Month view: daily totals and top item totals for the calendar month; tapping a date opens its Day editor.
- Pull-to-refresh, loading skeletons, useful empty states, and inline validation/errors using existing design-system components.

The screen uses simple native bars and lists rather than adding a chart dependency.

## Data flow

1. An employee order captures catalog name, category, share count, and price snapshots.
2. Admin opens Budget for a day/week/month.
3. The server materializes any missing current-month purchase lines from grouped orders.
4. The server returns authoritative totals and line data.
5. Admin corrections update only `daily_purchase_items`.
6. Reports aggregate visible daily purchase lines; employee orders and WhatsApp output remain unchanged.

## Error handling

- Reject malformed dates and date ranges outside the current-month-onward reporting boundary.
- Reject negative prices, fractional values, zero/negative quantities, empty names, and unsupported item types with HTTP 400.
- Return 404 for unknown purchase lines.
- Keep admin authentication and authorization on every budget route.
- Flutter retains current data when refresh fails and shows a retryable message.
- Mutations disable their relevant controls while saving and reload authoritative server data after success.

## Verification strategy

Server tests cover:

- schema defaults and integer price snapshots
- order placement snapshotting price/share count/category
- current-month backfill behavior
- catalog price changes not altering materialized historical totals
- generated, edited, removed, substituted, and custom lines
- snack/drink/day/week/month totals
- validation and admin authorization
- unchanged existing summary response and WhatsApp inputs

Flutter tests cover:

- price validation and request payloads in Manage Snacks
- admin-only Budget navigation
- period and type switching
- day editor add/edit/remove flows
- whole-rupee formatting and total rendering
- empty/error/loading states

Final verification runs server tests/type checks, Flutter formatting/analyze/tests, local migration application, and an emulator smoke test of catalog price editing plus daily budget editing/reporting.

## Out of scope

- Employee-visible prices
- Spending caps or order limits
- Approval/finalization/reopen workflow
- Pantry accounts or access
- Pantry bill entry, variance reconciliation, or invoice storage
- WhatsApp price/total changes
- Reports before the current month
- Remote migration, deployment, push, or pull request
