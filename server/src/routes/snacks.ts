import { Hono } from 'hono';
import { snacks, appSettings } from '../db/schema';
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

// Public app settings (cutoff time)
snackRoutes.get('/settings', async (c) => {
    try {
        const db = c.get('db');
        const [cutoff] = await db.select()
            .from(appSettings)
            .where(eq(appSettings.key, 'cutoff_time'))
            .limit(1);

        return c.json({ cutoffTime: cutoff?.value ?? '12:00' }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

// Public CSV template for admin bulk snack upload
snackRoutes.get('/template', async (c) => {
    const templateRows = [
        'name,emoji,description,veg_or_non_veg,serving_size,is_default,is_active,sort_order',
        'Samosa,🥟,Crispy potato filling,veg,2 Pcs,false,true,10',
        'Chicken Puff,🥐,Flaky pastry with chicken,non-veg,1 Pc,false,true,20',
    ].join('\n');

    c.header('Content-Type', 'text/csv; charset=utf-8');
    c.header('Content-Disposition', 'attachment; filename="snacks-bulk-upload-template.csv"');
    return c.body(templateRows, 200);
});

export default snackRoutes;
