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
    type PurchaseItemInput,
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

function withConcurrentUpdateBeforeWrite(
    db: Database,
    shouldIntercept: (values: Record<string, unknown>) => boolean,
    concurrentUpdate: () => Promise<unknown>,
): Database {
    let intercepted = false;
    return new Proxy(db as object, {
        get(target, property, receiver) {
            if (property !== 'update') {
                const value = Reflect.get(target, property, receiver);
                return typeof value === 'function' ? value.bind(target) : value;
            }
            return (table: unknown) => {
                const updateBuilder = (db as any).update(table);
                if (table !== dailyPurchaseItems) return updateBuilder;
                return new Proxy(updateBuilder, {
                    get(updateTarget, updateProperty) {
                        if (updateProperty !== 'set') {
                            const value = Reflect.get(updateTarget, updateProperty);
                            return typeof value === 'function' ? value.bind(updateTarget) : value;
                        }
                        return (values: Record<string, unknown>) => {
                            const setBuilder = updateTarget.set(values);
                            if (intercepted || !shouldIntercept(values)) return setBuilder;
                            return new Proxy(setBuilder, {
                                get(setTarget, setProperty) {
                                    if (setProperty !== 'where') {
                                        const value = Reflect.get(setTarget, setProperty);
                                        return typeof value === 'function'
                                            ? value.bind(setTarget)
                                            : value;
                                    }
                                    return async (condition: unknown) => {
                                        intercepted = true;
                                        await concurrentUpdate();
                                        return setTarget.where(condition);
                                    };
                                },
                            });
                        };
                    },
                });
            };
        },
    }) as Database;
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

    test('reactivates an automatic tombstone when its source order returns', async () => {
        const db = createTestDb();
        await insertOrders(db, 1);
        await getBudgetDay(db, '2026-08-12', OFFICE_TODAY);
        const [sourceOrder] = await db.select().from(orders);
        await db.delete(orders).where(eq(orders.date, '2026-08-12'));
        expect((await getBudgetDay(db, '2026-08-12', OFFICE_TODAY)).items).toEqual([]);

        await db.insert(orders).values({
            userId: sourceOrder!.userId,
            date: sourceOrder!.date,
            snackId: sourceOrder!.snackId,
            snackNameSnapshot: sourceOrder!.snackNameSnapshot,
            snackEmojiSnapshot: sourceOrder!.snackEmojiSnapshot,
            snackPriceRupeesSnapshot: sourceOrder!.snackPriceRupeesSnapshot,
            snackShareCountSnapshot: sourceOrder!.snackShareCountSnapshot,
            snackCategorySnapshot: sourceOrder!.snackCategorySnapshot,
        });

        const restored = await getBudgetDay(db, '2026-08-12', OFFICE_TODAY);
        expect(restored.items).toHaveLength(1);
        expect(restored.items[0]).toMatchObject({ name: 'Samosa', quantity: 1 });
    });

    test('admin removal is permanent and records an edited tombstone', async () => {
        const db = createTestDb();
        await insertOrders(db, 1);
        const generated = (await getBudgetDay(db, '2026-08-12', OFFICE_TODAY)).items[0]!;

        await removePurchaseItem(db, '2026-08-12', generated.id, OFFICE_TODAY);
        const afterSync = await getBudgetDay(db, '2026-08-12', OFFICE_TODAY);
        const [stored] = await db.select().from(dailyPurchaseItems)
            .where(eq(dailyPurchaseItems.id, generated.id));

        expect(afterSync.items).toEqual([]);
        expect(stored).toMatchObject({ isEdited: true, isRemoved: true });
    });

    test('quantity refresh does not overwrite a concurrent admin edit', async () => {
        const db = createTestDb();
        await insertOrders(db, 1);
        const generated = (await getBudgetDay(db, '2026-08-12', OFFICE_TODAY)).items[0]!;
        const [sourceOrder] = await db.select().from(orders);
        await db.insert(orders).values([
            {
                userId: sourceOrder!.userId,
                date: sourceOrder!.date,
                snackId: sourceOrder!.snackId,
                snackNameSnapshot: sourceOrder!.snackNameSnapshot,
                snackPriceRupeesSnapshot: sourceOrder!.snackPriceRupeesSnapshot,
                snackShareCountSnapshot: sourceOrder!.snackShareCountSnapshot,
                snackCategorySnapshot: sourceOrder!.snackCategorySnapshot,
            },
            {
                userId: sourceOrder!.userId,
                date: sourceOrder!.date,
                snackId: sourceOrder!.snackId,
                snackNameSnapshot: sourceOrder!.snackNameSnapshot,
                snackPriceRupeesSnapshot: sourceOrder!.snackPriceRupeesSnapshot,
                snackShareCountSnapshot: sourceOrder!.snackShareCountSnapshot,
                snackCategorySnapshot: sourceOrder!.snackCategorySnapshot,
            },
        ]);
        const racingDb = withConcurrentUpdateBeforeWrite(
            db,
            (values) => Object.prototype.hasOwnProperty.call(values, 'quantity'),
            () => db.update(dailyPurchaseItems)
                .set({ quantity: 9, isEdited: true })
                .where(eq(dailyPurchaseItems.id, generated.id)),
        );

        const day = await getBudgetDay(racingDb, '2026-08-12', OFFICE_TODAY);

        expect(day.items[0]).toMatchObject({ quantity: 9, isEdited: true });
    });

    test('auto-tombstone does not hide a concurrent admin edit', async () => {
        const db = createTestDb();
        await insertOrders(db, 1);
        const generated = (await getBudgetDay(db, '2026-08-12', OFFICE_TODAY)).items[0]!;
        await db.delete(orders).where(eq(orders.date, '2026-08-12'));
        const racingDb = withConcurrentUpdateBeforeWrite(
            db,
            (values) => values.isRemoved === true,
            () => db.update(dailyPurchaseItems)
                .set({ name: 'Admin substitute', isEdited: true })
                .where(eq(dailyPurchaseItems.id, generated.id)),
        );

        const day = await getBudgetDay(racingDb, '2026-08-12', OFFICE_TODAY);

        expect(day.items[0]).toMatchObject({
            name: 'Admin substitute',
            isEdited: true,
        });
    });

    test('preserves a materialized zero price after the catalog price changes', async () => {
        const db = createTestDb();
        const snack = await insertOrders(db, 1, { snackPriceRupeesSnapshot: null });
        await db.update(snacks).set({ priceRupees: 0 }).where(eq(snacks.id, snack.id));
        const unpriced = await getBudgetDay(db, '2026-08-12', OFFICE_TODAY);
        expect(unpriced.items[0]!.unitPriceRupees).toBe(0);

        await db.update(snacks).set({ priceRupees: 55 }).where(eq(snacks.id, snack.id));
        const unchanged = await getBudgetDay(db, '2026-08-12', OFFICE_TODAY);

        expect(unchanged.items[0]!.unitPriceRupees).toBe(0);
    });

    test('does not fill a zero fallback price on an edited line', async () => {
        const db = createTestDb();
        const snack = await insertOrders(db, 1, { snackPriceRupeesSnapshot: null });
        await db.update(snacks).set({ priceRupees: 0 }).where(eq(snacks.id, snack.id));
        const generated = (await getBudgetDay(db, '2026-08-12', OFFICE_TODAY)).items[0]!;
        await updatePurchaseItem(db, '2026-08-12', generated.id, {
            unitPriceRupees: 0,
        }, OFFICE_TODAY);

        await db.update(snacks).set({ priceRupees: 55 }).where(eq(snacks.id, snack.id));
        const day = await getBudgetDay(db, '2026-08-12', OFFICE_TODAY);

        expect(day.items[0]).toMatchObject({ unitPriceRupees: 0, isEdited: true });
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
            {
                date: '2026-08-12',
                totals: { total: 80, snacks: 80, drinks: 0 },
                items: [expect.objectContaining({
                    date: '2026-08-12',
                    name: 'Samosa',
                    itemType: 'snack',
                    quantity: 2,
                    unitPriceRupees: 40,
                    lineTotalRupees: 80,
                    isManual: false,
                })],
            },
            {
                date: '2026-08-13',
                totals: { total: 30, snacks: 0, drinks: 30 },
                items: [expect.objectContaining({
                    date: '2026-08-13',
                    name: 'Tea',
                    itemType: 'drink',
                    quantity: 2,
                    unitPriceRupees: 15,
                    lineTotalRupees: 30,
                    isManual: true,
                })],
            },
            { date: '2026-08-14', totals: { total: 0, snacks: 0, drinks: 0 }, items: [] },
        ]);
        expect(range.items).toEqual([
            { name: 'Samosa', itemType: 'snack', quantity: 2, totalRupees: 80 },
            { name: 'Tea', itemType: 'drink', quantity: 2, totalRupees: 30 },
        ]);
    });
});

describe('budget validation', () => {
    test('August creation, day, and range remain available after month rollover', async () => {
        const db = createTestDb();
        const septemberToday = '2026-09-05';
        await createPurchaseItem(db, '2026-08-12', {
            name: 'Tea', itemType: 'drink', quantity: 2, unitPriceRupees: 15,
        }, septemberToday);

        const day = await getBudgetDay(db, '2026-08-12', septemberToday);
        const range = await getBudgetRange(
            db,
            '2026-08-01',
            '2026-08-31',
            septemberToday,
        );

        expect(day.totals).toEqual({ total: 30, snacks: 0, drinks: 30 });
        expect(range.totals).toEqual({ total: 30, snacks: 0, drinks: 30 });
        expect(range.days).toHaveLength(31);
    });

    test('dates before the budget reporting start are rejected', async () => {
        const db = createTestDb();
        await expect(getBudgetDay(db, '2026-07-31', OFFICE_TODAY)).rejects.toThrow(
            'date must be on or after 2026-08-01',
        );
        await expect(getBudgetRange(
            db,
            '2026-07-31',
            '2026-08-01',
            OFFICE_TODAY,
        )).rejects.toThrow('start must be on or after 2026-08-01');
        await expect(createPurchaseItem(db, '2026-07-31', {
            name: 'Tea', itemType: 'drink', quantity: 1, unitPriceRupees: 15,
        }, OFFICE_TODAY)).rejects.toThrow('date must be on or after 2026-08-01');
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

    test.each([
        '1',
        true,
        null,
        Number.NaN,
        Number.POSITIVE_INFINITY,
        Number.MAX_SAFE_INTEGER + 1,
        0,
        -1,
        1.5,
    ])('rejects non-JSON-integer quantity %p', async (quantity) => {
        const db = createTestDb();
        await expect(createPurchaseItem(db, '2026-08-12', {
            name: 'Tea',
            itemType: 'drink',
            quantity,
            unitPriceRupees: 1,
        } satisfies PurchaseItemInput, OFFICE_TODAY)).rejects.toThrow(
            'quantity must be an integer greater than or equal to 1',
        );
    });

    test.each([
        '1',
        true,
        null,
        Number.NaN,
        Number.POSITIVE_INFINITY,
        Number.MAX_SAFE_INTEGER + 1,
        -1,
        1.5,
    ])('rejects non-JSON-integer unit price %p', async (unitPriceRupees) => {
        const db = createTestDb();
        await expect(createPurchaseItem(db, '2026-08-12', {
            name: 'Tea',
            itemType: 'drink',
            quantity: 1,
            unitPriceRupees,
        } satisfies PurchaseItemInput, OFFICE_TODAY)).rejects.toThrow(
            'unitPriceRupees must be a whole number greater than or equal to 0',
        );
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

describe('user budget spendings', () => {
    test('aggregates per-person spendings with correct snack/drink split and item breakdown', async () => {
        const db = createTestDb();
        const [alice] = await db.insert(users).values({
            username: 'alice',
            email: 'alice@example.com',
        }).returning();
        const [bob] = await db.insert(users).values({
            username: 'bob',
            email: 'bob@example.com',
        }).returning();

        const [pizza] = await db.insert(snacks).values({
            name: 'Smiley Veg Pizza',
            category: 'Pizza',
            shareCount: 1,
            priceRupees: 85,
        }).returning();
        const [chai] = await db.insert(snacks).values({
            name: 'Masala Tea',
            category: 'Drinks',
            shareCount: 1,
            priceRupees: 15,
        }).returning();

        // Alice orders pizza and chai on 2026-08-12
        await db.insert(orders).values([
            {
                userId: alice!.id,
                date: '2026-08-12',
                snackId: pizza!.id,
                snackNameSnapshot: 'Smiley Veg Pizza',
                snackPriceRupeesSnapshot: 85,
                snackShareCountSnapshot: 1,
                snackCategorySnapshot: 'Pizza',
            },
            {
                userId: alice!.id,
                date: '2026-08-12',
                snackId: chai!.id,
                snackNameSnapshot: 'Masala Tea',
                snackPriceRupeesSnapshot: 15,
                snackShareCountSnapshot: 1,
                snackCategorySnapshot: 'Drinks',
            },
        ]);

        // Bob orders 2 chais on 2026-08-12
        await db.insert(orders).values([
            {
                userId: bob!.id,
                date: '2026-08-12',
                snackId: chai!.id,
                snackNameSnapshot: 'Masala Tea',
                snackPriceRupeesSnapshot: 15,
                snackShareCountSnapshot: 1,
                snackCategorySnapshot: 'Drinks',
            },
            {
                userId: bob!.id,
                date: '2026-08-12',
                snackId: chai!.id,
                snackNameSnapshot: 'Masala Tea',
                snackPriceRupeesSnapshot: 15,
                snackShareCountSnapshot: 1,
                snackCategorySnapshot: 'Drinks',
            },
        ]);

        const day = await getBudgetDay(db, '2026-08-12', OFFICE_TODAY);
        expect(day.userSpendings).toHaveLength(2);

        // Alice should be first (₹100 > ₹30)
        expect(day.userSpendings[0]).toMatchObject({
            userId: alice!.id,
            username: 'alice',
            email: 'alice@example.com',
            totalSpendRupees: 100,
            totalOrdersCount: 2,
            snackSpendRupees: 85,
            drinkSpendRupees: 15,
        });
        expect(day.userSpendings[0]!.items).toEqual([
            {
                snackId: pizza!.id,
                name: 'Smiley Veg Pizza',
                emoji: null,
                category: 'Pizza',
                itemType: 'snack',
                quantity: 1,
                unitPriceRupees: 85,
                totalRupees: 85,
            },
            {
                snackId: chai!.id,
                name: 'Masala Tea',
                emoji: null,
                category: 'Drinks',
                itemType: 'drink',
                quantity: 1,
                unitPriceRupees: 15,
                totalRupees: 15,
            },
        ]);

        // Bob should be second (₹30)
        expect(day.userSpendings[1]).toMatchObject({
            userId: bob!.id,
            username: 'bob',
            email: 'bob@example.com',
            totalSpendRupees: 30,
            totalOrdersCount: 2,
            snackSpendRupees: 0,
            drinkSpendRupees: 30,
        });
        expect(day.userSpendings[1]!.items).toEqual([
            {
                snackId: chai!.id,
                name: 'Masala Tea',
                emoji: null,
                category: 'Drinks',
                itemType: 'drink',
                quantity: 2,
                unitPriceRupees: 15,
                totalRupees: 30,
            },
        ]);
    });

    test('range aggregation includes multi-day daily spend breakdown per person', async () => {
        const db = createTestDb();
        const [alice] = await db.insert(users).values({
            username: 'alice',
            email: 'alice@example.com',
        }).returning();
        const [snack] = await db.insert(snacks).values({
            name: 'Puff',
            category: 'Snacks',
            shareCount: 1,
            priceRupees: 25,
        }).returning();

        // Alice orders on Aug 10 and Aug 11
        await db.insert(orders).values([
            {
                userId: alice!.id,
                date: '2026-08-10',
                snackId: snack!.id,
                snackNameSnapshot: 'Puff',
                snackPriceRupeesSnapshot: 25,
                snackShareCountSnapshot: 1,
                snackCategorySnapshot: 'Snacks',
            },
            {
                userId: alice!.id,
                date: '2026-08-11',
                snackId: snack!.id,
                snackNameSnapshot: 'Puff',
                snackPriceRupeesSnapshot: 25,
                snackShareCountSnapshot: 1,
                snackCategorySnapshot: 'Snacks',
            },
            {
                userId: alice!.id,
                date: '2026-08-11',
                snackId: snack!.id,
                snackNameSnapshot: 'Puff',
                snackPriceRupeesSnapshot: 25,
                snackShareCountSnapshot: 1,
                snackCategorySnapshot: 'Snacks',
            },
        ]);

        const range = await getBudgetRange(db, '2026-08-10', '2026-08-12', OFFICE_TODAY);
        expect(range.userSpendings).toHaveLength(1);
        expect(range.userSpendings[0]!.totalSpendRupees).toBe(75);
        expect(range.userSpendings[0]!.dailySpend).toEqual([
            { date: '2026-08-10', totalRupees: 25, itemCount: 1 },
            { date: '2026-08-11', totalRupees: 50, itemCount: 2 },
        ]);
    });
});
