import { createDb } from './index';
import { snacks, hotDrinks, appSettings } from './schema';

const databaseUrl = process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/snacks_app';
const db = createDb(databaseUrl);

async function seed() {
    console.log('Seeding initial data...');

    // 1. App Settings
    await db.insert(appSettings).values([
        { key: 'cutoff_time', value: '12:00' },
        { key: 'whatsapp_number', value: '919876543210' },
        { key: 'whatsapp_is_group', value: 'false' },
        { key: 'holiday_country', value: 'IN' },
    ]).onConflictDoNothing();

    // 2. Hot Drinks Options
    await db.insert(hotDrinks).values([
        { name: 'Tea', emoji: '☕', isActive: true },
        { name: 'Coffee', emoji: '☕', isActive: true },
        { name: 'Boost', emoji: '🍫', isActive: true },
    ]).onConflictDoNothing();

    // 3. Initial Snacks (Examples)
    await db.insert(snacks).values([
        { name: 'Samosa', emoji: '🥟', description: 'Crispy & spicy potato filling', isVeg: true, isDefault: true, isActive: true, servingSize: '2 Pcs', sortOrder: 1 },
        { name: 'Bjjai / Pakora', emoji: '🧅', description: 'Deep fried onion fritters', isVeg: true, isDefault: false, isActive: true, servingSize: '1 Plate', sortOrder: 2 },
        { name: 'Chicken Puff', emoji: '🥐', description: 'Flaky pastry with chicken', isVeg: false, isDefault: false, isActive: true, servingSize: '1 Pc', sortOrder: 3 },
        { name: 'Egg Puff', emoji: '🥚', description: 'Flaky pastry with egg', isVeg: false, isDefault: false, isActive: true, servingSize: '1 Pc', sortOrder: 4 },
        { name: 'Vada Pav', emoji: '🍔', description: 'Mumbai style spicy potato slider', isVeg: true, isDefault: false, isActive: true, servingSize: '1 Pc', sortOrder: 5 },
    ]).onConflictDoNothing();

    console.log('Seeding complete!');
    process.exit(0);
}

seed().catch((err) => {
    console.error('Seed failed:', err);
    process.exit(1);
});
