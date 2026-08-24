import { describe, expect, test, beforeEach } from 'bun:test';
import { Database as SqliteDatabase } from 'bun:sqlite';
import { drizzle } from 'drizzle-orm/bun-sqlite';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { orders, snacks, users, dailyPurchaseItems } from '../db/schema';
import { eq, and } from 'drizzle-orm';
import type { Database } from '../db';
import * as schema from '../db/schema';
import { synchronizeDate } from '../lib/budget';

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

describe('Admin Summary Reassign & User Order', () => {
    let db: Database;

    beforeEach(() => {
        db = createTestDb();
    });

    test('reassigning a snack updates orders and synchronizes daily purchase ledger', async () => {
        const [user1] = await db.insert(users).values({
            username: 'Alice',
            email: 'alice@example.com',
        }).returning();

        const [user2] = await db.insert(users).values({
            username: 'Bob',
            email: 'bob@example.com',
        }).returning();

        const [samosa] = await db.insert(snacks).values({
            name: 'Veg Samosa',
            category: 'Snacks',
            priceRupees: 20,
            shareCount: 1,
        }).returning();

        const [puff] = await db.insert(snacks).values({
            name: 'Veg Puff',
            category: 'Snacks',
            priceRupees: 25,
            shareCount: 1,
        }).returning();

        const date = '2026-08-23';

        // Insert initial orders for Alice & Bob
        await db.insert(orders).values([
            {
                userId: user1.id,
                date,
                snackId: samosa.id,
                snackNameSnapshot: samosa.name,
                snackPriceRupeesSnapshot: samosa.priceRupees,
                snackShareCountSnapshot: samosa.shareCount,
                snackCategorySnapshot: samosa.category,
            },
            {
                userId: user2.id,
                date,
                snackId: samosa.id,
                snackNameSnapshot: samosa.name,
                snackPriceRupeesSnapshot: samosa.priceRupees,
                snackShareCountSnapshot: samosa.shareCount,
                snackCategorySnapshot: samosa.category,
            },
        ]);

        await synchronizeDate(db, date);

        let lines = await db.select().from(dailyPurchaseItems).where(eq(dailyPurchaseItems.date, date));
        expect(lines.length).toBe(1);
        expect(lines[0].name).toBe('Veg Samosa');
        expect(lines[0].quantity).toBe(2);
        expect(lines[0].unitPriceRupees).toBe(20);

        // Reassign all Veg Samosas on this date to Veg Puff
        await db.update(orders).set({
            snackId: puff.id,
            snackNameSnapshot: puff.name,
            snackPriceRupeesSnapshot: puff.priceRupees,
            snackShareCountSnapshot: puff.shareCount,
            snackCategorySnapshot: puff.category,
            updatedAt: new Date(),
        }).where(and(eq(orders.date, date), eq(orders.snackId, samosa.id)));

        await synchronizeDate(db, date);

        lines = await db.select().from(dailyPurchaseItems).where(and(eq(dailyPurchaseItems.date, date), eq(dailyPurchaseItems.isRemoved, false)));
        expect(lines.length).toBe(1);
        expect(lines[0].name).toBe('Veg Puff');
        expect(lines[0].quantity).toBe(2);
        expect(lines[0].unitPriceRupees).toBe(25);
    });
});
