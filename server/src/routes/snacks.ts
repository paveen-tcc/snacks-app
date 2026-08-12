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
            .select({
                id: snacks.id,
                name: snacks.name,
                category: snacks.category,
                emoji: snacks.emoji,
                isVeg: snacks.isVeg,
                isDefault: snacks.isDefault,
                isActive: snacks.isActive,
                servingSize: snacks.servingSize,
                shareCount: snacks.shareCount,
                sortOrder: snacks.sortOrder,
                createdAt: snacks.createdAt,
            })
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
        'name,category,image_url,veg_or_non_veg,serving_size,share_count,price_rupees,is_active,sort_order',
        'Schezwan Samosa,Samosa,https://images.unsplash.com/photo-1601050690597-df056fb4ce78?auto=format&fit=crop&w=400&q=80,veg,4 Pcs,1,25,true,10',
        'Chicken Pizza,Pizza,https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=400&q=80,non-veg,1 Pizza,2,300,true,20',
        'Tea,Drinks,https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=400&q=80,veg,1 Cup,1,18,true,30',
        'Rosemilk Pudding,Pudding,https://images.unsplash.com/photo-1549007994-cb92ca87df46?auto=format&fit=crop&w=400&q=80,veg,1 Cup,1,45,true,40',
        'Pista Pudding,Pudding,https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?auto=format&fit=crop&w=400&q=80,veg,1 Cup,1,45,true,50',
        'Banana Pudding,Pudding,https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=400&q=80,veg,1 Cup,1,45,true,60',
        'Veg Samosa,Samosa,https://images.unsplash.com/photo-1601050690597-df056fb4ce78?auto=format&fit=crop&w=400&q=80,veg,4 Pcs,1,25,true,70',
        'Egg Samosa,Samosa,https://images.unsplash.com/photo-1601050690597-df056fb4ce78?auto=format&fit=crop&w=400&q=80,non-veg,4 Pcs,1,30,true,80',
    ].join('\n');

    c.header('Content-Type', 'text/csv; charset=utf-8');
    c.header('Content-Disposition', 'attachment; filename="snacks-bulk-upload-template.csv"');
    return c.body(templateRows, 200);
});

export default snackRoutes;
