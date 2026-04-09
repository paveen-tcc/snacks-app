import { createDb } from './index';
import { snacks, hotDrinks, appSettings } from './schema';
import { eq } from 'drizzle-orm';
import { menuSnackCatalog } from './menu_catalog';

const databaseUrl = process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/snacks_app';
const db = createDb(databaseUrl);

async function seed() {
    console.log('Seeding initial data...');

    const normalizeWhitespace = (value: string) => value.trim().replace(/\s+/g, ' ');
    const normalizeName = (value: string) => normalizeWhitespace(value).toLowerCase();
    const normalizeCategory = (value: string | null | undefined) => {
        if (value == null) return 'general';
        const normalized = normalizeWhitespace(value);
        return normalized.length === 0 ? 'general' : normalized.toLowerCase();
    };

    // 1. App Settings
    await db.insert(appSettings).values([
        {
            key: 'cutoff_time',
            value: '12:00',
            advanceOrderMode: false,
            advanceWindowStart: '06:00',
            advanceWindowEnd: '22:00',
        },
        {
            key: 'whatsapp_number',
            value: '919876543210',
            advanceOrderMode: false,
            advanceWindowStart: '06:00',
            advanceWindowEnd: '22:00',
        },
        {
            key: 'whatsapp_is_group',
            value: 'false',
            advanceOrderMode: false,
            advanceWindowStart: '06:00',
            advanceWindowEnd: '22:00',
        },
        {
            key: 'holiday_country',
            value: 'IN',
            advanceOrderMode: false,
            advanceWindowStart: '06:00',
            advanceWindowEnd: '22:00',
        },
    ]).onConflictDoNothing();

    // 2. Hot Drinks Options
    await db.insert(hotDrinks).values([
        { name: 'Tea', emoji: '☕', isActive: true },
        { name: 'Coffee', emoji: '☕', isActive: true },
        { name: 'Boost', emoji: '🍫', isActive: true },
    ]).onConflictDoNothing();

    // 3. Menu Snacks Catalog
    const existingSnacks = await db.select().from(snacks);
    let insertedCount = 0;
    let updatedCount = 0;

    for (const item of menuSnackCatalog) {
        const existingSnack = existingSnacks.find((snack) =>
            normalizeName(snack.name) === normalizeName(item.name) &&
            normalizeCategory(snack.category ?? null) === normalizeCategory(item.category)
        );

        const payload = {
            name: item.name,
            category: item.category,
            emoji: item.emoji,
            description: item.description,
            isVeg: item.isVeg,
            isActive: true,
            servingSize: item.servingSize,
            sortOrder: item.sortOrder,
        };

        if (existingSnack) {
            await db.update(snacks)
                .set(payload)
                .where(eq(snacks.id, existingSnack.id));
            updatedCount++;
            continue;
        }

        await db.insert(snacks).values({
            ...payload,
            isDefault: false,
        });
        insertedCount++;
    }

    console.log(`Menu catalog synced: ${insertedCount} inserted, ${updatedCount} updated`);

    console.log('Seeding complete!');
    process.exit(0);
}

seed().catch((err) => {
    console.error('Seed failed:', err);
    process.exit(1);
});
