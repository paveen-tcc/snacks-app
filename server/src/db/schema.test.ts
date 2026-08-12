import { describe, test, expect } from 'bun:test';
import { Database } from 'bun:sqlite';
import { drizzle } from 'drizzle-orm/bun-sqlite';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { eq } from 'drizzle-orm';
import * as schema from './schema';
import {
    users,
    snacks,
    orders,
    appSettings,
    pushTokens,
    dailyPurchaseItems,
} from './schema';

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

    test('budget columns and daily purchase items use integer defaults', async () => {
        const db = createTestDb();
        const [user] = await db.insert(users)
            .values({ username: 'budget', email: 'budget@example.com' })
            .returning();
        const [snack] = await db.insert(snacks)
            .values({ name: 'Tea', category: 'Drinks', priceRupees: 18 })
            .returning();
        expect(snack!.priceRupees).toBe(18);

        const [order] = await db.insert(orders).values({
            userId: user!.id,
            date: '2026-08-12',
            snackId: snack!.id,
            snackNameSnapshot: 'Tea',
            snackPriceRupeesSnapshot: 18,
            snackShareCountSnapshot: 2,
            snackCategorySnapshot: 'Drinks',
        }).returning();
        expect(order!.snackPriceRupeesSnapshot).toBe(18);
        expect(order!.snackShareCountSnapshot).toBe(2);
        expect(order!.snackCategorySnapshot).toBe('Drinks');

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
});
