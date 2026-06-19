import { createDb } from './index';
import { snacks, orders, syncQueue } from './schema';

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
    console.error('DATABASE_URL environment variable is not defined.');
    process.exit(1);
}

// Read new_menu.json using Bun's built-in file reader
const menuJsonPath = `${import.meta.dir}/new_menu.json`;
const menuJsonFile = Bun.file(menuJsonPath);
const menuJson = await menuJsonFile.json();

const db = createDb(databaseUrl);

async function syncMenu() {
    console.log('🚀 Starting database replacement and menu sync...');
    
    // Map snake_case keys from Excel JSON to Drizzle camelCase properties
    const itemsToInsert = menuJson.map((item: any) => ({
        id: item.id,
        name: item.name,
        category: item.category,
        emoji: item.emoji,
        isVeg: item.is_veg,
        isDefault: item.is_default,
        isActive: item.is_active,
        servingSize: item.serving_size,
        shareCount: item.share_count,
        sortOrder: item.sort_order,
        createdAt: item.created_at ? new Date(item.created_at) : undefined,
    }));

    try {
        console.log('🧹 Clearing orders history...');
        await db.delete(orders);

        console.log('🧹 Clearing sync queue...');
        await db.delete(syncQueue);

        console.log('🧹 Clearing existing snacks catalog...');
        await db.delete(snacks);

        console.log(`📥 Inserting ${itemsToInsert.length} new snacks...`);
        // Insert in chunks of 50 to prevent potential query limit issues
        const chunkSize = 50;
        for (let i = 0; i < itemsToInsert.length; i += chunkSize) {
            const chunk = itemsToInsert.slice(i, i + chunkSize);
            await db.insert(snacks).values(chunk);
        }

        console.log('✅ Database menu replacement completed successfully!');
        process.exit(0);
    } catch (error) {
        console.error('❌ Error during menu sync:', error);
        process.exit(1);
    }
}

syncMenu();
