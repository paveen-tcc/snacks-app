import { Hono } from 'hono';
import { db } from '../db';
import { snacks, appSettings, holidays, shutdownDays, users } from '../db/schema';
import { eq } from 'drizzle-orm';
import { authMiddleware, adminMiddleware } from '../middleware/auth';
import type { AuthContext } from '../middleware/auth';

const adminRoutes = new Hono<AuthContext>();

// All admin routes require authentication AND admin privileges
adminRoutes.use('*', authMiddleware, adminMiddleware);

// --- Snacks Management ---

adminRoutes.post('/snacks', async (c) => {
    try {
        const { name, emoji, description, isVeg, isDefault, isActive, servingSize, sortOrder } = await c.req.json();

        // If setting as default, unset other defaults first (only one default allowed)
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
        const settings = await db.select().from(appSettings);
        // Convert array of {key, value} to a simple object map
        const settingsMap = settings.reduce((acc, curr) => ({ ...acc, [curr.key]: curr.value }), {});
        return c.json({ settings: settingsMap }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

adminRoutes.put('/settings', async (c) => {
    try {
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

// --- User Management ---

adminRoutes.post('/users/:id/admin', async (c) => {
    try {
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

export default adminRoutes;
