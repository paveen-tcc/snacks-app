import { describe, expect, test } from 'bun:test';
import { Database as SqliteDatabase } from 'bun:sqlite';
import { drizzle } from 'drizzle-orm/bun-sqlite';
import { eq } from 'drizzle-orm';
import { Hono } from 'hono';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import type { Database } from '../db';
import * as schema from '../db/schema';
import { appSettings, orders, snacks, users } from '../db/schema';
import type { AppEnv } from '../index';
import { effectiveOrderDate, getOrderWindow } from '../lib/orderWindow';
import { signToken } from '../utils/jwt';
import orderRoutes from './orders';

const MIGRATIONS_DIR = join(import.meta.dir, '../../drizzle');
const JWT_SECRET = 'order-route-test-secret';
const EMPLOYEE_ORDER_KEYS = [
    'date',
    'id',
    'isDefaultAssigned',
    'orderedAt',
    'snackEmojiSnapshot',
    'snackId',
    'snackNameSnapshot',
    'updatedAt',
    'userId',
];

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

async function createFixture() {
    const db = createTestDb();
    await db.insert(appSettings).values([
        { key: 'cutoff_time', value: '23:59' },
        { key: 'timezone_offset_minutes', value: '0' },
    ]);
    const [user] = await db.insert(users).values({
        username: 'employee',
        email: 'employee@example.com',
    }).returning();
    const [snack] = await db.insert(snacks).values({
        name: 'Tea',
        category: 'Drinks',
        emoji: '☕',
        shareCount: 2,
        priceRupees: 18,
    }).returning();
    const app = new Hono<AppEnv>();
    app.use('*', async (c, next) => {
        c.set('db', db);
        c.set('jwtSecret', JWT_SECRET);
        await next();
    });
    app.route('/api/orders', orderRoutes);
    const token = await signToken({ userId: user!.id, isAdmin: false }, JWT_SECRET);
    const headers = {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
    };
    const date = effectiveOrderDate(await getOrderWindow(db));
    return { app, date, db, headers, snack: snack!, user: user! };
}

function expectEmployeeSafeOrder(order: Record<string, unknown>) {
    expect(Object.keys(order).sort()).toEqual(EMPLOYEE_ORDER_KEYS);
    expect(order).not.toHaveProperty('snackPriceRupeesSnapshot');
    expect(order).not.toHaveProperty('snackShareCountSnapshot');
    expect(order).not.toHaveProperty('snackCategorySnapshot');
}

describe('employee order response contract', () => {
    test('GET /today excludes every budget-only snapshot', async () => {
        const { app, date, db, headers, snack, user } = await createFixture();
        await db.insert(orders).values({
            userId: user.id,
            date,
            snackId: snack.id,
            snackNameSnapshot: snack.name,
            snackEmojiSnapshot: snack.emoji,
            snackPriceRupeesSnapshot: snack.priceRupees,
            snackShareCountSnapshot: snack.shareCount,
            snackCategorySnapshot: snack.category,
        });

        const response = await app.request('/api/orders/today', { headers });
        const body = await response.json() as {
            order: Record<string, unknown>;
            orders: Record<string, unknown>[];
        };

        expect(response.status).toBe(200);
        expectEmployeeSafeOrder(body.order);
        expect(body.orders).toHaveLength(1);
        expectEmployeeSafeOrder(body.orders[0]!);
    });

    test('POST / persists catalog snapshots but returns only employee-safe orders', async () => {
        const { app, db, headers, snack } = await createFixture();

        const response = await app.request('/api/orders', {
            method: 'POST',
            headers,
            body: JSON.stringify({ snackIds: [snack.id] }),
        });
        const body = await response.json() as {
            order: Record<string, unknown>;
            orders: Record<string, unknown>[];
        };

        expect(response.status).toBe(200);
        expectEmployeeSafeOrder(body.order);
        expect(body.orders).toHaveLength(1);
        expectEmployeeSafeOrder(body.orders[0]!);

        const [stored] = await db.select().from(orders).where(eq(orders.snackId, snack.id));
        expect(stored).toMatchObject({
            snackPriceRupeesSnapshot: 18,
            snackShareCountSnapshot: 2,
            snackCategorySnapshot: 'Drinks',
        });
    });
});
