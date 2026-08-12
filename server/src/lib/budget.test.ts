import { describe, expect, test } from 'bun:test';
import { Database as SqliteDatabase } from 'bun:sqlite';
import { drizzle } from 'drizzle-orm/bun-sqlite';
import { eq } from 'drizzle-orm';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import type { Database } from '../db';
import * as schema from '../db/schema';
import { dailyPurchaseItems, orders, snacks, users } from '../db/schema';
import {
    createPurchaseItem,
    getBudgetDay,
    getBudgetRange,
    removePurchaseItem,
    updatePurchaseItem,
} from './budget';

const OFFICE_TODAY = '2026-08-12';
const MIGRATIONS_DIR = join(import.meta.dir, '../../drizzle');

function createTestDb(): Database {
    const sqlite = new SqliteDatabase(':memory:');
    for (const file of readdirSync(MIGRATIONS_DIR).filter((name) => name.endsWith('.sql')).sort()) {
        const migration = readFileSync(join(MIGRATIONS_DIR, file), 'utf8');
        for (const statement of migration.split('--> statement-breakpoint')) {
            if (statement.trim()) sqlite.run(statement.trim());
        }
    }
    return drizzle(sqlite, { schema }) as unknown as Database;
}

async function insertOrders(
    db: Database,
    count: number,
    overrides: Partial<typeof orders.$inferInsert> = {},
) {
    const [user] = await db.insert(users).values({
        username: crypto.randomUUID(),
        email: `${crypto.randomUUID()}@example.com`,
    }).returning();
    const [snack] = await db.insert(snacks).values({
        name: 'Samosa',
        category: 'Snacks',
        shareCount: 2,
        priceRupees: 40,
    }).returning();
    await db.insert(orders).values(Array.from({ length: count }, () => ({
        userId: user!.id,
        date: '2026-08-12',
        snackId: snack!.id,
        snackNameSnapshot: 'Samosa',
        snackPriceRupeesSnapshot: 40,
        snackShareCountSnapshot: 2,
        snackCategorySnapshot: 'Snacks',
        ...overrides,
    })));
    return snack!;
}

describe('budget materialization', () => {
    test('materializes ceil(count/shareCount) using order price snapshot', async () => {
        const db = createTestDb();
        await insertOrders(db, 3);

        const day = await getBudgetDay(db, '2026-08-12', OFFICE_TODAY);

        expect(day.items).toHaveLength(1);
        expect(day.items[0]).toMatchObject({
            name: 'Samosa',
            itemType: 'snack',
            quantity: 2,
            unitPriceRupees: 40,
            lineTotalRupees: 80,
            isEdited: false,
            isManual: false,
        });
        expect(day.totals).toEqual({ total: 80, snacks: 80, drinks: 0 });
    });

    test('catalog price changes do not alter an existing purchase line', async () => {
        const db = createTestDb();
        const snack = await insertOrders(db, 1);
        await getBudgetDay(db, '2026-08-12', OFFICE_TODAY);

        await db.update(snacks).set({ priceRupees: 55 }).where(eq(snacks.id, snack.id));
        const day = await getBudgetDay(db, '2026-08-12', OFFICE_TODAY);

        expect(day.items[0]!.unitPriceRupees).toBe(40);
    });

    test('concurrent first reads materialize one generated line without failing', async () => {
        const db = createTestDb();
        await insertOrders(db, 1);

        const [first, second] = await Promise.all([
            getBudgetDay(db, '2026-08-12', OFFICE_TODAY),
            getBudgetDay(db, '2026-08-12', OFFICE_TODAY),
        ]);

        expect(first.items).toHaveLength(1);
        expect(second.items).toHaveLength(1);
        const stored = await db.select().from(dailyPurchaseItems);
        expect(stored).toHaveLength(1);
    });

    test('edited and removed generated lines are not overwritten', async () => {
        const db = createTestDb();
        await insertOrders(db, 1);
        const first = await getBudgetDay(db, '2026-08-12', OFFICE_TODAY);
        const generated = first.items[0]!;

        await updatePurchaseItem(db, '2026-08-12', generated.id, {
            name: 'Substitute Samosa',
            itemType: 'snack',
            quantity: 7,
            unitPriceRupees: 45,
        }, OFFICE_TODAY);
        const edited = await getBudgetDay(db, '2026-08-12', OFFICE_TODAY);
        expect(edited.items[0]).toMatchObject({
            name: 'Substitute Samosa',
            quantity: 7,
            unitPriceRupees: 45,
            isEdited: true,
        });

        await removePurchaseItem(db, '2026-08-12', generated.id, OFFICE_TODAY);
        const removed = await getBudgetDay(db, '2026-08-12', OFFICE_TODAY);
        expect(removed.items).toEqual([]);
        const [stored] = await db.select().from(dailyPurchaseItems)
            .where(eq(dailyPurchaseItems.id, generated.id));
        expect(stored!.isRemoved).toBe(true);
    });

    test('custom lines contribute to the correct snack/drink totals', async () => {
        const db = createTestDb();
        await createPurchaseItem(db, '2026-08-12', {
            name: 'Fruit', itemType: 'snack', quantity: 2, unitPriceRupees: 30,
        }, OFFICE_TODAY);
        await createPurchaseItem(db, '2026-08-12', {
            name: 'Tea', itemType: 'drink', quantity: 3, unitPriceRupees: 10,
        }, OFFICE_TODAY);

        const day = await getBudgetDay(db, '2026-08-12', OFFICE_TODAY);

        expect(day.totals).toEqual({ total: 90, snacks: 60, drinks: 30 });
        expect(day.items.map((item) => item.lineTotalRupees)).toEqual([60, 30]);
    });

    test('updates one supplied field while preserving the other item values', async () => {
        const db = createTestDb();
        const created = await createPurchaseItem(db, '2026-08-12', {
            name: 'Fruit', itemType: 'snack', quantity: 2, unitPriceRupees: 30,
        }, OFFICE_TODAY);

        const updated = await updatePurchaseItem(
            db,
            '2026-08-12',
            created.id,
            { quantity: 4 },
            OFFICE_TODAY,
        );

        expect(updated).toMatchObject({
            name: 'Fruit', itemType: 'snack', quantity: 4, unitPriceRupees: 30, isEdited: true,
        });
    });

    test('tombstones an untouched generated line when its source orders disappear', async () => {
        const db = createTestDb();
        await insertOrders(db, 1);
        await getBudgetDay(db, '2026-08-12', OFFICE_TODAY);
        await db.delete(orders).where(eq(orders.date, '2026-08-12'));

        const day = await getBudgetDay(db, '2026-08-12', OFFICE_TODAY);

        expect(day.items).toEqual([]);
        const [stored] = await db.select().from(dailyPurchaseItems);
        expect(stored!.isRemoved).toBe(true);
    });

    test('range reports zero-filled days and aggregated item totals', async () => {
        const db = createTestDb();
        await insertOrders(db, 3);
        await createPurchaseItem(db, '2026-08-13', {
            name: 'Tea', itemType: 'drink', quantity: 2, unitPriceRupees: 15,
        }, OFFICE_TODAY);

        const range = await getBudgetRange(db, '2026-08-12', '2026-08-14', OFFICE_TODAY);

        expect(range.totals).toEqual({ total: 110, snacks: 80, drinks: 30 });
        expect(range.days).toEqual([
            { date: '2026-08-12', totals: { total: 80, snacks: 80, drinks: 0 } },
            { date: '2026-08-13', totals: { total: 30, snacks: 0, drinks: 30 } },
            { date: '2026-08-14', totals: { total: 0, snacks: 0, drinks: 0 } },
        ]);
        expect(range.items).toEqual([
            { name: 'Samosa', itemType: 'snack', quantity: 2, totalRupees: 80 },
            { name: 'Tea', itemType: 'drink', quantity: 2, totalRupees: 30 },
        ]);
    });
});

describe('budget validation', () => {
    test('dates before the office month start are rejected', async () => {
        const db = createTestDb();
        await expect(getBudgetDay(db, '2026-07-31', OFFICE_TODAY)).rejects.toThrow(
            'date must be on or after 2026-08-01',
        );
    });

    test.each([
        ['2026-02-30', 'invalid date'],
        ['12-08-2026', 'invalid date'],
    ])('rejects malformed date %s', async (date, message) => {
        const db = createTestDb();
        await expect(getBudgetDay(db, date, OFFICE_TODAY)).rejects.toThrow(message);
    });

    test('rejects invalid custom item values', async () => {
        const db = createTestDb();
        await expect(createPurchaseItem(db, '2026-08-12', {
            name: ' ', itemType: 'snack', quantity: 0, unitPriceRupees: -1,
        }, OFFICE_TODAY)).rejects.toThrow('name is required');
    });

    test('existing purchase rows remain editable after month rollover', async () => {
        const db = createTestDb();
        const [existing] = await db.insert(dailyPurchaseItems).values({
            date: '2026-08-12',
            name: 'Tea',
            itemType: 'drink',
            quantity: 2,
            unitPriceRupees: 15,
        }).returning();

        const updated = await updatePurchaseItem(
            db,
            '2026-08-12',
            existing!.id,
            { quantity: 3 },
            '2026-09-05',
        );
        expect(updated.quantity).toBe(3);

        await removePurchaseItem(db, '2026-08-12', existing!.id, '2026-09-05');
        const [removed] = await db.select().from(dailyPurchaseItems)
            .where(eq(dailyPurchaseItems.id, existing!.id));
        expect(removed!.isRemoved).toBe(true);
    });
});
