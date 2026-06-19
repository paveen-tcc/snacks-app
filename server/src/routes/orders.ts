import { Hono } from 'hono';
import { orders, snacks, holidays, shutdownDays } from '../db/schema';
import { eq, and, sql, inArray } from 'drizzle-orm';
import { authMiddleware } from '../middleware/auth';
import type { AuthContext } from '../middleware/auth';
import {
    getOrderWindow,
    effectiveOrderDate,
    officeDateString,
    orderingClosedReason,
} from '../lib/orderWindow';

const orderRoutes = new Hono<AuthContext>();

// All order routes are protected
orderRoutes.use('*', authMiddleware);

// Check if today is a shutdown/holiday day
orderRoutes.get('/status', async (c) => {
    try {
        const db = c.get('db');
        const window = await getOrderWindow(db);
        const today = officeDateString(window.offsetMinutes, 0);

        const [holiday] = await db
            .select()
            .from(holidays)
            .where(sql`${holidays.date} = ${today}`)
            .limit(1);

        const [shutdown] = await db
            .select()
            .from(shutdownDays)
            .where(sql`${shutdownDays.date} = ${today}`)
            .limit(1);

        if (holiday) {
            return c.json({ isOpen: false, reason: holiday.name ?? 'Holiday', type: 'holiday' }, 200);
        }
        if (shutdown) {
            return c.json({ isOpen: false, reason: shutdown.reason ?? 'Shutdown day', type: 'shutdown' }, 200);
        }

        return c.json({ isOpen: true }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

// Get today's order for the user
orderRoutes.get('/today', async (c) => {
    try {
        const db = c.get('db');
        const user = c.get('user');
        const today = effectiveOrderDate(await getOrderWindow(db));

        const todaysOrders = await db
            .select()
            .from(orders)
            .where(and(eq(orders.userId, user.userId), sql`${orders.date} = ${today}`))
            .orderBy(orders.orderedAt);

        return c.json({
            order: todaysOrders[0] ?? null,
            orders: todaysOrders,
        }, 200);
    } catch (err: any) {
        console.log(err);
        return c.json({ error: err.message }, 500);
    }
});

// Place or update today's order
orderRoutes.post('/', async (c) => {
    try {
        const db = c.get('db');
        const user = c.get('user');
        const { snackId, snackIds, sugarFreeSnackIds } = await c.req.json();

        // Authoritative window check — the client cutoff is advisory only and
        // can be bypassed by changing the device clock, so the server decides.
        const window = await getOrderWindow(db);
        const closedReason = await orderingClosedReason(db, window);
        if (closedReason) {
            return c.json({ error: closedReason }, 403);
        }

        const orderDate = effectiveOrderDate(window);
        const rawSnackIds = (Array.isArray(snackIds) ? snackIds : [snackId])
            .filter((value): value is string => typeof value === 'string' && value.trim().length > 0);

        if (rawSnackIds.length === 0) {
            return c.json({ error: 'snackIds is required' }, 400);
        }

        // Sugar-free snack IDs (optional) — append "(Sugar Free)" to name snapshot
        const sugarFreeSet = new Set<string>(
            Array.isArray(sugarFreeSnackIds) ? sugarFreeSnackIds.filter(
                (v): v is string => typeof v === 'string'
            ) : []
        );

        await db.delete(orders)
            .where(and(eq(orders.userId, user.userId), sql`${orders.date} = ${orderDate}`));

        const uniqueSnackIds = Array.from(new Set(rawSnackIds));
        const selectedSnacks = await db.select({
            id: snacks.id,
            name: snacks.name,
            emoji: snacks.emoji,
        })
            .from(snacks)
            .where(inArray(snacks.id, uniqueSnackIds));

        if (selectedSnacks.length !== uniqueSnackIds.length) {
            return c.json({ error: 'One or more selected snacks were not found' }, 400);
        }

        const snackMap = new Map(selectedSnacks.map((snack) => [snack.id, snack]));

        const savedOrders = await db.insert(orders)
            .values(rawSnackIds.map((selectedSnackId) => {
                const snack = snackMap.get(selectedSnackId);
                if (!snack) {
                    throw new Error(`Missing snack for ${selectedSnackId}`);
                }
                const isSugarFree = sugarFreeSet.has(selectedSnackId);
                const snapshotName = isSugarFree
                    ? `${snack.name} (Sugar Free)`
                    : snack.name;
                return {
                    userId: user.userId,
                    date: orderDate,
                    snackId: selectedSnackId,
                    snackNameSnapshot: snapshotName,
                    snackEmojiSnapshot: snack.emoji,
                    updatedAt: new Date(),
                };
            }))
            .returning();

        return c.json({
            order: savedOrders[0] ?? null,
            orders: savedOrders,
        }, 200);
    } catch (err: any) {
        console.log(err);
        return c.json({ error: err.message }, 500);
    }
});

// Clear today's snack order
orderRoutes.delete('/', async (c) => {
    try {
        const db = c.get('db');
        const user = c.get('user');

        // Clearing an order is also a mutation to the locked-in list, so the
        // same window check applies (can't be undone after the cutoff).
        const window = await getOrderWindow(db);
        const closedReason = await orderingClosedReason(db, window);
        if (closedReason) {
            return c.json({ error: closedReason }, 403);
        }

        const orderDate = effectiveOrderDate(window);

        await db.delete(orders)
            .where(and(eq(orders.userId, user.userId), sql`${orders.date} = ${orderDate}`));

        return c.json({ order: null, orders: [] }, 200);
    } catch (err: any) {
        console.log(err);
        return c.json({ error: err.message }, 500);
    }
});

// Get order history (past 7 days)
orderRoutes.get('/history', async (c) => {
    try {
        const db = c.get('db');
        const user = c.get('user');
        const today = new Date();
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(today.getDate() - 7);

        const todayStr = today.toISOString().split('T')[0];
        const pastStr = sevenDaysAgo.toISOString().split('T')[0];

        const history = await db
            .select({
                id: orders.id,
                userId: orders.userId,
                date: orders.date,
                snackId: orders.snackId,
                snackName: sql<string>`coalesce(${orders.snackNameSnapshot}, ${snacks.name}, 'Unknown')`,
                snackEmoji: sql<string>`coalesce(${orders.snackEmojiSnapshot}, ${snacks.emoji}, '🍽️')`,
                isDefaultAssigned: orders.isDefaultAssigned,
                orderedAt: orders.orderedAt,
                updatedAt: orders.updatedAt,
            })
            .from(orders)
            .leftJoin(snacks, eq(orders.snackId, snacks.id))
            .where(
                and(
                    and(
                        eq(orders.userId, user.userId),
                        sql`${orders.date} >= ${pastStr}`,
                        sql`${orders.date} <= ${todayStr}`
                    ))
            )
            .orderBy(sql`${orders.date} desc`, orders.orderedAt);

        return c.json({ history }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

export default orderRoutes;
