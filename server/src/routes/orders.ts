import { Hono } from 'hono';
import { db } from '../db';
import { orders } from '../db/schema';
import { eq, and, gte, lte, sql } from 'drizzle-orm';
import { authMiddleware } from '../middleware/auth';
import type { AuthContext } from '../middleware/auth';

const orderRoutes = new Hono<AuthContext>();

// All order routes are protected
orderRoutes.use('*', authMiddleware);

// Get today's order for the user
orderRoutes.get('/today', async (c) => {
    try {
        const user = c.get('user');
        const today = new Date().toISOString().split('T')[0];

        const [order] = await db
            .select()
            .from(orders)
            .where(and(eq(orders.userId, user.userId), sql`${orders.date} = ${today}`))
            .limit(1);

        if (!order) {
            return c.json({ order: null }, 200);
        }

        return c.json({ order }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

// Place or update today's order
orderRoutes.post('/', async (c) => {
    try {
        const user = c.get('user');
        const { snackId, date } = await c.req.json();
        const orderDate = date || new Date().toISOString().split('T')[0];

        if (!snackId) {
            return c.json({ error: 'snackId is required' }, 400);
        }

        // Upsert logic (insert or update if date exists for user)
        // For Drizzle postgres, we can use onConflictDoUpdate
        const [savedOrder] = await db.insert(orders)
            .values({
                userId: user.userId,
                date: orderDate,
                snackId,
            })
            .onConflictDoUpdate({
                target: [orders.userId, orders.date],
                set: { snackId, updatedAt: new Date() }
            })
            .returning();

        return c.json({ order: savedOrder }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

// Get order history (past 7 days)
orderRoutes.get('/history', async (c) => {
    try {
        const user = c.get('user');
        const today = new Date();
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(today.getDate() - 7);

        const todayStr = today.toISOString().split('T')[0];
        const pastStr = sevenDaysAgo.toISOString().split('T')[0];

        // We must pass dateStr otherwise type gets mad
        const history = await db
            .select()
            .from(orders)
            .where(
                and(
                    and(
                        eq(orders.userId, user.userId),
                        sql`${orders.date} >= ${pastStr}`,
                        sql`${orders.date} <= ${todayStr}`
                    ))
            );

        return c.json({ history }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

export default orderRoutes;
