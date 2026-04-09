import { Hono } from 'hono';
import { snacks, appSettings } from '../db/schema';
import { eq } from 'drizzle-orm';
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
            .orderBy(snacks.sortOrder, snacks.name);

        return c.json({ snacks: allSnacks }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

// Public app settings (cutoff time)
snackRoutes.get('/settings', async (c) => {
    try {
        const db = c.get('db');
        const settings = await db.select().from(appSettings);
        const cutoff = settings.find((setting) => setting.key === 'cutoff_time');
        const [settingsRow] = await db.select({
            advanceOrderMode: appSettings.advanceOrderMode,
            advanceWindowStart: appSettings.advanceWindowStart,
            advanceWindowEnd: appSettings.advanceWindowEnd,
        })
            .from(appSettings)
            .where(eq(appSettings.key, 'cutoff_time'))
            .limit(1);

        return c.json({
            cutoffTime: cutoff?.value ?? '12:00',
            advanceOrderMode: settingsRow?.advanceOrderMode ?? false,
            advanceWindowStart: settingsRow?.advanceWindowStart ?? '06:00',
            advanceWindowEnd: settingsRow?.advanceWindowEnd ?? '22:00',
        }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

// Public CSV template for admin bulk snack upload
snackRoutes.get('/template', async (c) => {
    const templateRows = [
        'name,category,emoji,description,veg_or_non_veg,serving_size,share_count,is_active,sort_order',
        'Schezwan Samosa,Samosa,🥟,Spicy samosa filling,veg,4 Pcs,1,true,10',
        'Pizza,Italian,🍕,Cheesy pizza slices,veg,1 box,2,true,20',
    ].join('\n');

    c.header('Content-Type', 'text/csv; charset=utf-8');
    c.header('Content-Disposition', 'attachment; filename="snacks-bulk-upload-template.csv"');
    return c.body(templateRows, 200);
});

export default snackRoutes;
