import { Hono } from 'hono';
import { snacks, appSettings, holidays, shutdownDays, users, orders } from '../db/schema';
import { eq, sql } from 'drizzle-orm';
import { authMiddleware, adminMiddleware } from '../middleware/auth';
import type { AuthContext } from '../middleware/auth';
import { isFcmConfigured } from '../lib/fcm';
import { runManualOrderReminder } from '../scheduled';

const adminRoutes = new Hono<AuthContext>();

const GENERAL_CATEGORY = 'General';
const MANUAL_ORDER_REMINDER_BODY = "Order now, it's closing.";
const MAX_NOTIFICATION_BODY_LENGTH = 180;

function normalizeWhitespace(value: string): string {
    return value.trim().replace(/\s+/g, ' ');
}

function normalizeSnackName(value: string): string {
    return normalizeWhitespace(value).toLowerCase();
}

function normalizeNotificationBody(value: unknown): string | null {
    if (value === undefined || value === null) {
        return MANUAL_ORDER_REMINDER_BODY;
    }
    if (typeof value !== 'string') {
        return null;
    }
    const normalized = normalizeWhitespace(value);
    if (!normalized) {
        return MANUAL_ORDER_REMINDER_BODY;
    }
    if (normalized.length > MAX_NOTIFICATION_BODY_LENGTH) {
        return null;
    }
    return normalized;
}

function normalizeCategoryValue(value: unknown): string | null {
    if (typeof value !== 'string') return null;
    const normalized = normalizeWhitespace(value);
    return normalized.length > 0 ? normalized : null;
}

function categoryLabel(value: string | null): string {
    return value ?? GENERAL_CATEGORY;
}

function categoryCompareKey(value: string | null): string {
    return categoryLabel(value).toLowerCase();
}

type CategoryMap = Map<string, string>;

function buildCategoryMap(existingSnacks: { category: string | null }[]): CategoryMap {
    const map: CategoryMap = new Map();
    for (const snack of existingSnacks) {
        const cat = snack.category;
        if (cat) {
            const lower = cat.toLowerCase();
            if (!map.has(lower)) {
                map.set(lower, cat);
            }
        }
    }
    return map;
}

function normalizeCategoryCase(value: string | null, categoryMap: CategoryMap): string | null {
    if (!value) return null;
    const lower = value.toLowerCase();
    return categoryMap.get(lower) ?? value;
}

function duplicateSnackError(name: string, category: string | null): string {
    return `Snack "${normalizeWhitespace(name)}" already exists in category "${categoryLabel(category)}"`;
}

function normalizeShareCount(value: unknown): number {
    const parsed = Number(value);
    if (!Number.isInteger(parsed) || parsed < 1) {
        throw new Error('shareCount must be an integer greater than or equal to 1');
    }
    return parsed;
}

export function normalizePriceRupees(value: unknown): number {
    const parsed = Number(value);
    if (!Number.isInteger(parsed) || parsed < 0) {
        throw new Error('priceRupees must be a whole number greater than or equal to 0');
    }
    return parsed;
}

function isCatalogValidationError(err: unknown): err is Error {
    return err instanceof Error && (
        err.message.includes('shareCount') || err.message.includes('priceRupees')
    );
}

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
        const {
            name,
            category,
            emoji,
            isVeg,
            isDefault,
            isActive,
            servingSize,
            sortOrder,
            shareCount,
            priceRupees,
        } = await c.req.json();
        const normalizedName = typeof name === 'string' ? normalizeWhitespace(name) : '';
        const normalizedCategory = normalizeCategoryValue(category);
        const normalizedShareCount = shareCount === undefined ? 1 : normalizeShareCount(shareCount);
        const normalizedPriceRupees = priceRupees === undefined ? 0 : normalizePriceRupees(priceRupees);

        if (!normalizedName) {
            return c.json({ error: 'name is required' }, 400);
        }

        const existingSnacks = await db.select().from(snacks);
        const categoryMap = buildCategoryMap(existingSnacks);
        const finalCategory = normalizeCategoryCase(normalizedCategory, categoryMap);

        const duplicate = existingSnacks.find((snack) =>
            normalizeSnackName(snack.name) === normalizeSnackName(normalizedName) &&
            categoryCompareKey(snack.category ?? null) === categoryCompareKey(finalCategory)
        );
        if (duplicate) {
            return c.json({ error: duplicateSnackError(normalizedName, finalCategory) }, 409);
        }

        if (isDefault) {
            await db.update(snacks).set({ isDefault: false }).where(eq(snacks.isDefault, true));
        }

        const [newSnack] = await db.insert(snacks).values({
            name: normalizedName,
            category: finalCategory,
            emoji,
            isVeg,
            isDefault,
            isActive,
            servingSize,
            shareCount: normalizedShareCount,
            priceRupees: normalizedPriceRupees,
            sortOrder
        }).returning();

        return c.json({ snack: newSnack }, 201);
    } catch (err: any) {
        if (isCatalogValidationError(err)) {
            return c.json({ error: err.message }, 400);
        }
        return c.json({ error: err.message }, 500);
    }
});

adminRoutes.post('/snacks/bulk', async (c) => {
    try {
        const db = c.get('db');
        const body = await c.req.json();
        const incomingSnacks = Array.isArray(body?.snacks) ? body.snacks : [];
        type NormalizedSnack = {
            name: string;
            category: string | null;
            emoji: string;
            isVeg: boolean;
            isDefault: boolean;
            isActive: boolean;
            servingSize: string;
            shareCount: number;
            priceRupees: number;
            sortOrder: number | null;
            index: number;
        };

        const normalizedSnacks: NormalizedSnack[] = incomingSnacks
            .map((snack: any, index: number) => ({
                name: typeof snack?.name === 'string' ? normalizeWhitespace(snack.name) : '',
                category: normalizeCategoryValue(snack?.category),
                emoji: typeof snack?.emoji === 'string' ? snack.emoji.trim() : '',
                isVeg: typeof snack?.isVeg === 'boolean' ? snack.isVeg : true,
                isDefault: snack?.isDefault === true,
                isActive: typeof snack?.isActive === 'boolean' ? snack.isActive : true,
                servingSize: typeof snack?.servingSize === 'string' ? snack.servingSize.trim() : '',
                shareCount: snack?.shareCount === undefined ? 1 : normalizeShareCount(snack.shareCount),
                priceRupees: snack?.priceRupees === undefined ? 0 : normalizePriceRupees(snack.priceRupees),
                sortOrder: Number.isFinite(Number(snack?.sortOrder)) ? Number(snack.sortOrder) : null,
                index,
            }))
            .filter((snack: NormalizedSnack) => snack.name.length > 0);

        if (normalizedSnacks.length === 0) {
            return c.json({ error: 'snacks is required' }, 400);
        }

        const seenKeys = new Set<string>();
        for (const snack of normalizedSnacks) {
            const key = `${normalizeSnackName(snack.name)}::${categoryCompareKey(snack.category)}`;
            if (seenKeys.has(key)) {
                return c.json({ error: duplicateSnackError(snack.name, snack.category) }, 409);
            }
            seenKeys.add(key);
        }

        const existingSnacks = await db.select().from(snacks);
        const categoryMap = buildCategoryMap(existingSnacks);

        // Normalize categories case for all incoming snacks
        for (const snack of normalizedSnacks) {
            snack.category = normalizeCategoryCase(snack.category, categoryMap);
        }

        for (const snack of normalizedSnacks) {
            const duplicate = existingSnacks.find((existingSnack) =>
                normalizeSnackName(existingSnack.name) === normalizeSnackName(snack.name) &&
                categoryCompareKey(existingSnack.category ?? null) === categoryCompareKey(snack.category)
            );
            if (duplicate) {
                return c.json({ error: duplicateSnackError(snack.name, snack.category) }, 409);
            }
        }

        const [sortInfo] = await db
            .select({
                maxSortOrder: sql<number>`coalesce(max(${snacks.sortOrder}), -1)`.mapWith(Number),
            })
            .from(snacks);

        const firstDefaultIndex = normalizedSnacks.findIndex((snack: NormalizedSnack) => snack.isDefault);
        if (firstDefaultIndex >= 0) {
            await db.update(snacks).set({ isDefault: false }).where(eq(snacks.isDefault, true));
        }

        const baseSortOrder = (sortInfo?.maxSortOrder ?? -1) + 1;
        const createdSnacks = await db.insert(snacks).values(
            normalizedSnacks.map((snack: NormalizedSnack, index: number) => ({
                name: snack.name,
                category: snack.category,
                emoji: snack.emoji || null,
                isVeg: snack.isVeg,
                isDefault: firstDefaultIndex >= 0 ? snack.index === firstDefaultIndex : false,
                isActive: snack.isActive,
                servingSize: snack.servingSize || null,
                shareCount: snack.shareCount,
                priceRupees: snack.priceRupees,
                sortOrder: snack.sortOrder ?? (baseSortOrder + index),
            }))
        ).returning();

        return c.json({ snacks: createdSnacks }, 201);
    } catch (err: any) {
        if (isCatalogValidationError(err)) {
            return c.json({ error: err.message }, 400);
        }
        return c.json({ error: err.message }, 500);
    }
});

adminRoutes.put('/snacks/:id', async (c) => {
    try {
        const db = c.get('db');
        const id = c.req.param('id');
        const updateData = await c.req.json();
        const existingSnacks = await db.select().from(snacks);
        const currentSnack = existingSnacks.find((snack) => snack.id === id);
        if (!currentSnack) {
            return c.json({ error: 'Snack not found' }, 404);
        }

        const nextName = typeof updateData.name === 'string'
            ? normalizeWhitespace(updateData.name)
            : currentSnack.name;
        const categoryMap = buildCategoryMap(existingSnacks);
        const rawNextCategory = Object.prototype.hasOwnProperty.call(updateData, 'category')
            ? normalizeCategoryValue(updateData.category)
            : (currentSnack.category ?? null);
        const nextCategory = normalizeCategoryCase(rawNextCategory, categoryMap);

        const duplicate = existingSnacks.find((snack) =>
            snack.id !== id &&
            normalizeSnackName(snack.name) === normalizeSnackName(nextName) &&
            categoryCompareKey(snack.category ?? null) === categoryCompareKey(nextCategory)
        );
        if (duplicate) {
            return c.json({ error: duplicateSnackError(nextName, nextCategory) }, 409);
        }

        if (updateData.isDefault) {
            await db.update(snacks).set({ isDefault: false }).where(eq(snacks.isDefault, true));
        }

        if (typeof updateData.name === 'string') {
            updateData.name = normalizeWhitespace(updateData.name);
        }
        if (Object.prototype.hasOwnProperty.call(updateData, 'category')) {
            updateData.category = nextCategory;
        }
        if (Object.prototype.hasOwnProperty.call(updateData, 'shareCount')) {
            updateData.shareCount = normalizeShareCount(updateData.shareCount);
        }
        if (Object.prototype.hasOwnProperty.call(updateData, 'priceRupees')) {
            updateData.priceRupees = normalizePriceRupees(updateData.priceRupees);
        }

        const [updatedSnack] = await db.update(snacks)
            .set(updateData)
            .where(eq(snacks.id, id))
            .returning();

        return c.json({ snack: updatedSnack }, 200);
    } catch (err: any) {
        if (isCatalogValidationError(err)) {
            return c.json({ error: err.message }, 400);
        }
        return c.json({ error: err.message }, 500);
    }
});

adminRoutes.delete('/snacks/:id', async (c) => {
    try {
        const db = c.get('db');
        const id = c.req.param('id');
        const [deletedSnack] = await db.delete(snacks)
            .where(eq(snacks.id, id))
            .returning();

        if (!deletedSnack) {
            return c.json({ error: 'Snack not found' }, 404);
        }

        return c.json({ snack: deletedSnack }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

// --- App Settings Management ---

adminRoutes.get('/settings', async (c) => {
    try {
        const db = c.get('db');
        const settings = await db.select().from(appSettings);
        const [settingsRow] = await db.select({
            advanceOrderMode: appSettings.advanceOrderMode,
            advanceWindowStart: appSettings.advanceWindowStart,
            advanceWindowEnd: appSettings.advanceWindowEnd,
        })
            .from(appSettings)
            .where(eq(appSettings.key, 'cutoff_time'))
            .limit(1);
        const settingsMap = settings.reduce<Record<string, string | boolean>>(
            (acc, curr) => ({ ...acc, [curr.key]: curr.value }),
            {}
        );
        settingsMap.advance_order_mode = settingsRow?.advanceOrderMode ?? false;
        settingsMap.advance_window_start = settingsRow?.advanceWindowStart ?? '06:00';
        settingsMap.advance_window_end = settingsRow?.advanceWindowEnd ?? '22:00';
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

        if (key === 'advance_order_mode' || key === 'advance_window_start' || key === 'advance_window_end') {
            const existingSettings = await db.select()
                .from(appSettings)
                .where(eq(appSettings.key, 'cutoff_time'))
                .limit(1);
            const columnUpdate = key === 'advance_order_mode'
                ? { advanceOrderMode: value === true || value === 'true' }
                : key === 'advance_window_start'
                    ? { advanceWindowStart: String(value) }
                    : { advanceWindowEnd: String(value) };

            if (existingSettings.length === 0) {
                const [setting] = await db.insert(appSettings)
                    .values({
                        key: 'cutoff_time',
                        value: '12:00',
                        ...columnUpdate,
                    })
                    .returning();
                return c.json({ setting }, 200);
            }

            const [setting] = await db.update(appSettings)
                .set(columnUpdate)
                .where(eq(appSettings.key, 'cutoff_time'))
                .returning();

            return c.json({ setting }, 200);
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

// --- Manual Notifications ---

adminRoutes.post('/order-reminder', async (c) => {
    try {
        if (!isFcmConfigured(c.env.FCM_SERVICE_ACCOUNT)) {
            return c.json({ error: 'FCM_SERVICE_ACCOUNT is not configured' }, 503);
        }

        const body = await c.req.json().catch(() => ({}));
        const reminderBody = normalizeNotificationBody(body?.body);
        if (!reminderBody) {
            return c.json({ error: `body must be a string up to ${MAX_NOTIFICATION_BODY_LENGTH} characters` }, 400);
        }

        const result = await runManualOrderReminder(c.env, c.get('db'), reminderBody);
        return c.json({ success: !result.skippedReason, ...result }, 200);
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
                snackNameSnapshot: orders.snackNameSnapshot,
                snackName: sql<string>`coalesce(${orders.snackNameSnapshot}, ${snacks.name}, 'Unknown')`,
                snackEmoji: sql<string>`coalesce(${snacks.emoji}, ${orders.snackEmojiSnapshot}, '🍽️')`,
                snackCategory: snacks.category,
                selectedCount: sql<number>`count(*)`.mapWith(Number),
                shareCount: sql<number>`coalesce(max(${snacks.shareCount}), 1)`.mapWith(Number),
            })
            .from(orders)
            .leftJoin(snacks, eq(orders.snackId, snacks.id))
            .where(sql`${orders.date} = ${today}`)
            .groupBy(
                orders.snackId,
                orders.snackNameSnapshot,
                sql`coalesce(${orders.snackNameSnapshot}, ${snacks.name}, 'Unknown')`,
                sql`coalesce(${snacks.emoji}, ${orders.snackEmojiSnapshot}, '🍽️')`,
                snacks.category
            );

        const todayOrders = await db
            .select({
                snackId: orders.snackId,
                snackNameSnapshot: orders.snackNameSnapshot,
                userId: orders.userId,
                username: users.username,
            })
            .from(orders)
            .innerJoin(users, eq(orders.userId, users.id))
            .where(sql`${orders.date} = ${today}`);

        const allUsers = await db
            .select({ id: users.id, username: users.username })
            .from(users);

        const orderedUserIds = new Set(todayOrders.map((o) => o.userId));
        const notOrdered = allUsers
            .filter((u) => !orderedUserIds.has(u.id))
            .map((u) => u.username)
            .sort((a, b) => a.localeCompare(b));

        const foodItems: any[] = [];
        const drinkItems: any[] = [];
        let totalOrders = 0;

        for (const item of orderCounts) {
            const count = Math.ceil(item.selectedCount / Math.max(item.shareCount, 1));
            // Match by both snackId AND snapshot name to correctly separate
            // sugar-free vs regular drinks with the same snackId.
            const usersList = todayOrders
                .filter((o) => o.snackId === item.snackId &&
                    o.snackNameSnapshot === item.snackNameSnapshot)
                .map((o) => o.username);

            if (item.snackCategory && item.snackCategory.toLowerCase() === 'drinks') {
                drinkItems.push({
                    drinkId: item.snackId,
                    drinkName: item.snackName,
                    drinkEmoji: item.snackEmoji,
                    count,
                    votedBy: usersList,
                });
            } else {
                foodItems.push({
                    snackId: item.snackId,
                    snackName: item.snackName,
                    snackEmoji: item.snackEmoji,
                    count,
                    orderedBy: usersList,
                });
                totalOrders += count;
            }
        }

        return c.json({ date: today, orders: foodItems, drinks: drinkItems, totalOrders, notOrdered }, 200);
    } catch (err: any) {
        if (err instanceof Error && err.message.includes('shareCount')) {
            return c.json({ error: err.message }, 400);
        }
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
