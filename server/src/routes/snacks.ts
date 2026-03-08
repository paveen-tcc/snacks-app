import { Hono } from 'hono';
import { snacks } from '../db/schema';
import { eq, desc } from 'drizzle-orm';
import type { AppEnv } from '../index';

const snackRoutes = new Hono<AppEnv>();

// Get all active snacks
snackRoutes.get('/', async (c) => {
    try {
        const db = c.get('db');
        const allSnacks = await db
            .select()
            .from(snacks)
            .where(eq(snacks.isActive, true))
            .orderBy(desc(snacks.sortOrder), snacks.name);

        return c.json({ snacks: allSnacks }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

export default snackRoutes;
