import { Hono } from 'hono';
import { orders, holidays, shutdownDays, snacks } from '../db/schema';
import { eq, and, sql } from 'drizzle-orm';
import { authMiddleware } from '../middleware/auth';
import type { AuthContext } from '../middleware/auth';

const orderRoutes = new Hono<AuthContext>();

// All order routes are protected
orderRoutes.use('*', authMiddleware);

// Check if today is a shutdown/holiday day
orderRoutes.get('/status', async (c) => {
    try {
        const db = c.get('db');
        const today = new Date().toISOString().split('T')[0];

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
        const today = new Date().toISOString().split('T')[0];

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
        const { snackId, snackIds, date } = await c.req.json();
        const orderDate = date || new Date().toISOString().split('T')[0];
        const normalizedSnackIds = Array.from(new Set(
            (Array.isArray(snackIds) ? snackIds : [snackId])
                .filter((value): value is string => typeof value === 'string' && value.trim().length > 0)
        ));

        if (normalizedSnackIds.length === 0) {
            return c.json({ error: 'snackIds is required' }, 400);
        }

        await db.delete(orders)
            .where(and(eq(orders.userId, user.userId), sql`${orders.date} = ${orderDate}`));

        const selectedSnacks = await db.select({
            id: snacks.id,
            name: snacks.name,
            emoji: snacks.emoji,
        })
            .from(snacks)
            .where(sql`${snacks.id} = any(${normalizedSnackIds})`);

        if (selectedSnacks.length !== normalizedSnackIds.length) {
            return c.json({ error: 'One or more selected snacks were not found' }, 400);
        }

        const snackMap = new Map(selectedSnacks.map((snack) => [snack.id, snack]));

        const savedOrders = await db.insert(orders)
            .values(normalizedSnackIds.map((selectedSnackId) => {
                const snack = snackMap.get(selectedSnackId);
                if (!snack) {
                    throw new Error(`Missing snack for ${selectedSnackId}`);
                }
                return {
                    userId: user.userId,
                    date: orderDate,
                    snackId: selectedSnackId,
                    snackNameSnapshot: snack.name,
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
                snackName: sql<string>`coalesce(${snacks.name}, ${orders.snackNameSnapshot}, 'Unknown')`,
                snackEmoji: sql<string>`coalesce(${snacks.emoji}, ${orders.snackEmojiSnapshot}, '🍽️')`,
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
