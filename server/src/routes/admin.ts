import { Hono } from 'hono';
import { snacks, appSettings, holidays, shutdownDays, users, orders, hotDrinks, drinkVotes } from '../db/schema';
import { eq, sql } from 'drizzle-orm';
import { authMiddleware, adminMiddleware } from '../middleware/auth';
import type { AuthContext } from '../middleware/auth';

const adminRoutes = new Hono<AuthContext>();

// All admin routes require authentication AND admin privileges
adminRoutes.use('*', authMiddleware, adminMiddleware);

// --- Snacks Management ---

adminRoutes.get('/snacks', async (c) => {
    try {
        const db = c.get('db');
        const allSnacks = await db.select().from(snacks).orderBy(snacks.sortOrder);
        return c.json({ snacks: allSnacks }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

adminRoutes.post('/snacks', async (c) => {
    try {
        const db = c.get('db');
        const { name, emoji, description, isVeg, isDefault, isActive, servingSize, sortOrder } = await c.req.json();

        if (isDefault) {
            await db.update(snacks).set({ isDefault: false }).where(eq(snacks.isDefault, true));
        }

        const [newSnack] = await db.insert(snacks).values({
            name, emoji, description, isVeg, isDefault, isActive, servingSize, sortOrder
        }).returning();

        return c.json({ snack: newSnack }, 201);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

adminRoutes.put('/snacks/:id', async (c) => {
    try {
        const db = c.get('db');
        const id = c.req.param('id');
        const updateData = await c.req.json();

        if (updateData.isDefault) {
            await db.update(snacks).set({ isDefault: false }).where(eq(snacks.isDefault, true));
        }

        const [updatedSnack] = await db.update(snacks)
            .set(updateData)
            .where(eq(snacks.id, id))
            .returning();

        return c.json({ snack: updatedSnack }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

// --- App Settings Management ---

adminRoutes.get('/settings', async (c) => {
    try {
        const db = c.get('db');
        const settings = await db.select().from(appSettings);
        const settingsMap = settings.reduce((acc, curr) => ({ ...acc, [curr.key]: curr.value }), {});
        return c.json({ settings: settingsMap }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

adminRoutes.put('/settings', async (c) => {
    try {
        const db = c.get('db');
        const { key, value } = await c.req.json();

        if (!key || value === undefined) {
            return c.json({ error: 'key and value are required' }, 400);
        }

        const [setting] = await db.insert(appSettings)
            .values({ key, value: String(value) })
            .onConflictDoUpdate({
                target: appSettings.key,
                set: { value: String(value) }
            })
            .returning();

        return c.json({ setting }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

// --- Summary ---

adminRoutes.get('/summary', async (c) => {
    try {
        const db = c.get('db');
        const today = new Date().toISOString().split('T')[0];

        const orderCounts = await db
            .select({
                snackId: orders.snackId,
                snackName: snacks.name,
                snackEmoji: snacks.emoji,
                count: sql<number>`count(*)`.mapWith(Number),
            })
            .from(orders)
            .innerJoin(snacks, eq(orders.snackId, snacks.id))
            .where(sql`${orders.date} = ${today}`)
            .groupBy(orders.snackId, snacks.name, snacks.emoji);

        const drinkCounts = await db
            .select({
                drinkId: drinkVotes.drinkId,
                drinkName: hotDrinks.name,
                drinkEmoji: hotDrinks.emoji,
                count: sql<number>`count(*)`.mapWith(Number),
            })
            .from(drinkVotes)
            .innerJoin(hotDrinks, eq(drinkVotes.drinkId, hotDrinks.id))
            .where(sql`${drinkVotes.date} = ${today}`)
            .groupBy(drinkVotes.drinkId, hotDrinks.name, hotDrinks.emoji);

        const totalOrders = orderCounts.reduce((sum, item) => sum + item.count, 0);

        return c.json({ date: today, orders: orderCounts, drinks: drinkCounts, totalOrders }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

// --- User Management ---

adminRoutes.post('/users/:id/admin', async (c) => {
    try {
        const db = c.get('db');
        const id = c.req.param('id');
        const { isAdmin } = await c.req.json();

        const [updatedUser] = await db.update(users)
            .set({ isAdmin })
            .where(eq(users.id, id))
            .returning();

        return c.json({ user: updatedUser }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

adminRoutes.get('/users', async (c) => {
    try {
        const db = c.get('db');
        const allUsers = await db
            .select({ id: users.id, username: users.username, email: users.email, isAdmin: users.isAdmin, createdAt: users.createdAt })
            .from(users)
            .orderBy(users.createdAt);
        return c.json({ users: allUsers }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

// --- Holidays Management ---

adminRoutes.get('/holidays', async (c) => {
    try {
        const db = c.get('db');
        const allHolidays = await db.select().from(holidays).orderBy(holidays.date);
        return c.json({ holidays: allHolidays }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

adminRoutes.post('/holidays', async (c) => {
    try {
        const db = c.get('db');
        const user = c.get('user');
        const { date, name } = await c.req.json();
        if (!date) return c.json({ error: 'date is required' }, 400);

        const [holiday] = await db.insert(holidays)
            .values({ date, name, source: 'manual', createdBy: user.userId })
            .returning();
        return c.json({ holiday }, 201);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

adminRoutes.delete('/holidays/:id', async (c) => {
    try {
        const db = c.get('db');
        const id = c.req.param('id');
        await db.delete(holidays).where(eq(holidays.id, id));
        return c.json({ success: true }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

export default adminRoutes;
