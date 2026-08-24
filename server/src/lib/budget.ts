import { and, eq, gte, isNotNull, lte } from 'drizzle-orm';
import type { Database } from '../db';
import { dailyPurchaseItems, orders, snacks, users } from '../db/schema';

export type BudgetItemType = 'snack' | 'drink';

export type BudgetTotals = {
    total: number;
    snacks: number;
    drinks: number;
};

export type BudgetLine = {
    id: string;
    date: string;
    name: string;
    itemType: BudgetItemType;
    quantity: number;
    unitPriceRupees: number;
    lineTotalRupees: number;
    isEdited: boolean;
    isManual: boolean;
};

export type UserBudgetItem = {
    snackId: string;
    name: string;
    emoji: string | null;
    category: string | null;
    itemType: BudgetItemType;
    quantity: number;
    unitPriceRupees: number;
    totalRupees: number;
};

export type UserDailySpend = {
    date: string;
    totalRupees: number;
    itemCount: number;
};

export type UserSpending = {
    userId: string;
    username: string;
    email: string;
    totalSpendRupees: number;
    totalOrdersCount: number;
    snackSpendRupees: number;
    drinkSpendRupees: number;
    items: UserBudgetItem[];
    dailySpend: UserDailySpend[];
};

export type BudgetDayResponse = {
    date: string;
    totals: BudgetTotals;
    items: BudgetLine[];
    userSpendings: UserSpending[];
};

export type BudgetRangeResponse = {
    start: string;
    end: string;
    totals: BudgetTotals;
    days: Array<{ date: string; totals: BudgetTotals; items: BudgetLine[] }>;
    items: Array<{
        name: string;
        itemType: BudgetItemType;
        quantity: number;
        totalRupees: number;
    }>;
    userSpendings: UserSpending[];
};

export type PurchaseItemInput = {
    name: unknown;
    itemType: unknown;
    quantity: unknown;
    unitPriceRupees: unknown;
};

export type PurchaseItemUpdate = Partial<PurchaseItemInput>;

export class BudgetValidationError extends Error {}
export class BudgetNotFoundError extends Error {}

export const BUDGET_REPORTING_START_DATE = '2026-08-01';

const DAY_MS = 86_400_000;
const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;

function parseDate(value: string): Date {
    if (!DATE_PATTERN.test(value)) {
        throw new BudgetValidationError('invalid date');
    }
    const parsed = new Date(`${value}T00:00:00.000Z`);
    if (Number.isNaN(parsed.getTime()) || parsed.toISOString().slice(0, 10) !== value) {
        throw new BudgetValidationError('invalid date');
    }
    return parsed;
}

function validateReportingDate(date: string, officeToday: string, label = 'date'): Date {
    const parsed = parseDate(date);
    parseDate(officeToday);
    if (date < BUDGET_REPORTING_START_DATE) {
        throw new BudgetValidationError(
            `${label} must be on or after ${BUDGET_REPORTING_START_DATE}`,
        );
    }
    return parsed;
}

function validateRange(start: string, end: string, officeToday: string) {
    const parsedStart = validateReportingDate(start, officeToday, 'start');
    const parsedEnd = validateReportingDate(end, officeToday, 'end');
    if (parsedStart.getTime() > parsedEnd.getTime()) {
        throw new BudgetValidationError('start must be on or before end');
    }
    const dayCount = Math.round((parsedEnd.getTime() - parsedStart.getTime()) / DAY_MS) + 1;
    if (dayCount > 366) {
        throw new BudgetValidationError('date range cannot exceed 366 days');
    }
    return { parsedStart, parsedEnd };
}

function normalizeName(value: unknown): string {
    if (typeof value !== 'string') {
        throw new BudgetValidationError('name is required');
    }
    const normalized = value.trim().replace(/\s+/g, ' ');
    if (!normalized) {
        throw new BudgetValidationError('name is required');
    }
    return normalized;
}

function normalizeItemType(value: unknown): BudgetItemType {
    if (value !== 'snack' && value !== 'drink') {
        throw new BudgetValidationError('itemType must be snack or drink');
    }
    return value;
}

function normalizeQuantity(value: unknown): number {
    if (typeof value !== 'number' || !Number.isSafeInteger(value) || value < 1) {
        throw new BudgetValidationError('quantity must be an integer greater than or equal to 1');
    }
    return value;
}

function normalizeUnitPrice(value: unknown): number {
    if (typeof value !== 'number' || !Number.isSafeInteger(value) || value < 0) {
        throw new BudgetValidationError(
            'unitPriceRupees must be a whole number greater than or equal to 0',
        );
    }
    return value;
}

function normalizeItem(input: PurchaseItemInput) {
    return {
        name: normalizeName(input.name),
        itemType: normalizeItemType(input.itemType),
        quantity: normalizeQuantity(input.quantity),
        unitPriceRupees: normalizeUnitPrice(input.unitPriceRupees),
    };
}

function toBudgetLine(row: typeof dailyPurchaseItems.$inferSelect): BudgetLine {
    return {
        id: row.id,
        date: row.date,
        name: row.name,
        itemType: row.itemType,
        quantity: row.quantity,
        unitPriceRupees: row.unitPriceRupees,
        lineTotalRupees: row.quantity * row.unitPriceRupees,
        isEdited: row.isEdited,
        isManual: row.sourceKey === null,
    };
}

function emptyTotals(): BudgetTotals {
    return { total: 0, snacks: 0, drinks: 0 };
}

function addLineToTotals(totals: BudgetTotals, line: BudgetLine) {
    totals.total += line.lineTotalRupees;
    if (line.itemType === 'drink') {
        totals.drinks += line.lineTotalRupees;
    } else {
        totals.snacks += line.lineTotalRupees;
    }
}

type SourceGroup = {
    sourceKey: string;
    sourceSnackId: string;
    name: string;
    selectedCount: number;
    snapshotPrice: number | null;
    snapshotShareCount: number | null;
    snapshotCategory: string | null;
    fallbackPrice: number;
    fallbackShareCount: number;
    fallbackCategory: string | null;
};

export async function synchronizeDate(db: Database, date: string) {
    const orderRows = await db.select({
        snackId: orders.snackId,
        snackNameSnapshot: orders.snackNameSnapshot,
        snackPriceRupeesSnapshot: orders.snackPriceRupeesSnapshot,
        snackShareCountSnapshot: orders.snackShareCountSnapshot,
        snackCategorySnapshot: orders.snackCategorySnapshot,
        catalogName: snacks.name,
        catalogPriceRupees: snacks.priceRupees,
        catalogShareCount: snacks.shareCount,
        catalogCategory: snacks.category,
    })
        .from(orders)
        .leftJoin(snacks, eq(orders.snackId, snacks.id))
        .where(eq(orders.date, date));

    const groups = new Map<string, SourceGroup>();
    for (const row of orderRows) {
        const name = normalizeName(row.snackNameSnapshot ?? row.catalogName ?? 'Unknown');
        const sourceKey = `${row.snackId}::${name}`;
        let group = groups.get(sourceKey);
        if (!group) {
            group = {
                sourceKey,
                sourceSnackId: row.snackId,
                name,
                selectedCount: 0,
                snapshotPrice: null,
                snapshotShareCount: null,
                snapshotCategory: null,
                fallbackPrice: row.catalogPriceRupees ?? 0,
                fallbackShareCount: row.catalogShareCount ?? 1,
                fallbackCategory: row.catalogCategory,
            };
            groups.set(sourceKey, group);
        }
        group.selectedCount += 1;
        group.snapshotPrice ??= row.snackPriceRupeesSnapshot;
        group.snapshotShareCount ??= row.snackShareCountSnapshot;
        group.snapshotCategory ??= row.snackCategorySnapshot;
    }

    const existingRows = await db.select().from(dailyPurchaseItems)
        .where(eq(dailyPurchaseItems.date, date));
    const existingBySource = new Map(
        existingRows
            .filter((row) => row.sourceKey !== null)
            .map((row) => [row.sourceKey!, row]),
    );

    for (const group of groups.values()) {
        const existing = existingBySource.get(group.sourceKey);
        const shareCount = group.snapshotShareCount ?? group.fallbackShareCount;
        const quantity = Math.ceil(group.selectedCount / Math.max(shareCount, 1));
        if (!existing) {
            const category = group.snapshotCategory ?? group.fallbackCategory;
            const itemType: BudgetItemType = category?.trim().toLowerCase() === 'drinks'
                ? 'drink'
                : 'snack';
            await db.insert(dailyPurchaseItems).values({
                date,
                sourceKey: group.sourceKey,
                sourceSnackId: group.sourceSnackId,
                name: group.name,
                itemType,
                quantity,
                unitPriceRupees: group.snapshotPrice ?? group.fallbackPrice,
            }).onConflictDoNothing({
                target: [dailyPurchaseItems.date, dailyPurchaseItems.sourceKey],
            });
        } else if (!existing.isEdited && existing.isRemoved) {
            await db.update(dailyPurchaseItems)
                .set({
                    quantity,
                    isRemoved: false,
                    updatedAt: new Date(),
                })
                .where(and(
                    eq(dailyPurchaseItems.id, existing.id),
                    eq(dailyPurchaseItems.isEdited, false),
                    eq(dailyPurchaseItems.isRemoved, true),
                ));
        } else if (!existing.isEdited && !existing.isRemoved) {
            const updates: Partial<typeof dailyPurchaseItems.$inferInsert> = {};
            if (existing.quantity !== quantity) updates.quantity = quantity;
            if (Object.keys(updates).length > 0) {
                await db.update(dailyPurchaseItems)
                    .set({ ...updates, updatedAt: new Date() })
                    .where(and(
                        eq(dailyPurchaseItems.id, existing.id),
                        eq(dailyPurchaseItems.isEdited, false),
                        eq(dailyPurchaseItems.isRemoved, false),
                    ));
            }
        }
    }

    const activeSources = new Set(groups.keys());
    for (const row of existingRows) {
        if (
            row.sourceKey !== null &&
            !activeSources.has(row.sourceKey) &&
            !row.isEdited &&
            !row.isRemoved
        ) {
            await db.update(dailyPurchaseItems)
                .set({ isRemoved: true, updatedAt: new Date() })
                .where(and(
                    eq(dailyPurchaseItems.id, row.id),
                    eq(dailyPurchaseItems.isEdited, false),
                    eq(dailyPurchaseItems.isRemoved, false),
                ));
        }
    }
}

async function readVisibleLines(db: Database, date: string): Promise<BudgetLine[]> {
    const rows = await db.select().from(dailyPurchaseItems)
        .where(and(
            eq(dailyPurchaseItems.date, date),
            eq(dailyPurchaseItems.isRemoved, false),
        ))
        .orderBy(dailyPurchaseItems.name, dailyPurchaseItems.id);
    return rows.map(toBudgetLine);
}

export async function getUserSpendings(
    db: Database,
    start: string,
    end: string,
): Promise<UserSpending[]> {
    const orderRows = await db
        .select({
            orderId: orders.id,
            userId: orders.userId,
            username: users.username,
            email: users.email,
            date: orders.date,
            snackId: orders.snackId,
            snackNameSnapshot: orders.snackNameSnapshot,
            snackEmojiSnapshot: orders.snackEmojiSnapshot,
            snackPriceRupeesSnapshot: orders.snackPriceRupeesSnapshot,
            snackShareCountSnapshot: orders.snackShareCountSnapshot,
            snackCategorySnapshot: orders.snackCategorySnapshot,
            catalogName: snacks.name,
            catalogEmoji: snacks.emoji,
            catalogPriceRupees: snacks.priceRupees,
            catalogShareCount: snacks.shareCount,
            catalogCategory: snacks.category,
        })
        .from(orders)
        .innerJoin(users, eq(orders.userId, users.id))
        .leftJoin(snacks, eq(orders.snackId, snacks.id))
        .where(and(gte(orders.date, start), lte(orders.date, end)));

    type UserAccumulator = {
        userId: string;
        username: string;
        email: string;
        totalSpendRupees: number;
        totalOrdersCount: number;
        snackSpendRupees: number;
        drinkSpendRupees: number;
        itemMap: Map<string, UserBudgetItem>;
        dailyMap: Map<string, UserDailySpend>;
    };

    const userMap = new Map<string, UserAccumulator>();

    for (const row of orderRows) {
        let userAcc = userMap.get(row.userId);
        if (!userAcc) {
            userAcc = {
                userId: row.userId,
                username: row.username,
                email: row.email,
                totalSpendRupees: 0,
                totalOrdersCount: 0,
                snackSpendRupees: 0,
                drinkSpendRupees: 0,
                itemMap: new Map(),
                dailyMap: new Map(),
            };
            userMap.set(row.userId, userAcc);
        }

        const name = normalizeName(row.snackNameSnapshot ?? row.catalogName ?? 'Unknown');
        const emoji = row.snackEmojiSnapshot ?? row.catalogEmoji ?? null;
        const category = row.snackCategorySnapshot ?? row.catalogCategory ?? null;
        const itemType: BudgetItemType = category?.trim().toLowerCase() === 'drinks'
            ? 'drink'
            : 'snack';
        const price = row.snackPriceRupeesSnapshot ?? row.catalogPriceRupees ?? 0;
        const shareCount = row.snackShareCountSnapshot ?? row.catalogShareCount ?? 1;
        const unitCost = Math.round(price / Math.max(shareCount, 1));

        userAcc.totalOrdersCount += 1;
        userAcc.totalSpendRupees += unitCost;
        if (itemType === 'drink') {
            userAcc.drinkSpendRupees += unitCost;
        } else {
            userAcc.snackSpendRupees += unitCost;
        }

        const itemKey = `${row.snackId}::${name}`;
        let item = userAcc.itemMap.get(itemKey);
        if (!item) {
            item = {
                snackId: row.snackId,
                name,
                emoji,
                category,
                itemType,
                quantity: 0,
                unitPriceRupees: unitCost,
                totalRupees: 0,
            };
            userAcc.itemMap.set(itemKey, item);
        }
        item.quantity += 1;
        item.totalRupees += unitCost;

        let daily = userAcc.dailyMap.get(row.date);
        if (!daily) {
            daily = {
                date: row.date,
                totalRupees: 0,
                itemCount: 0,
            };
            userAcc.dailyMap.set(row.date, daily);
        }
        daily.totalRupees += unitCost;
        daily.itemCount += 1;
    }

    const result: UserSpending[] = Array.from(userMap.values()).map((u) => ({
        userId: u.userId,
        username: u.username,
        email: u.email,
        totalSpendRupees: u.totalSpendRupees,
        totalOrdersCount: u.totalOrdersCount,
        snackSpendRupees: u.snackSpendRupees,
        drinkSpendRupees: u.drinkSpendRupees,
        items: Array.from(u.itemMap.values()).sort((a, b) =>
            b.totalRupees - a.totalRupees || a.name.localeCompare(b.name),
        ),
        dailySpend: Array.from(u.dailyMap.values()).sort((a, b) =>
            a.date.localeCompare(b.date),
        ),
    }));

    result.sort((a, b) =>
        b.totalSpendRupees - a.totalSpendRupees ||
        b.totalOrdersCount - a.totalOrdersCount ||
        a.username.localeCompare(b.username),
    );

    return result;
}

export async function getBudgetDay(
    db: Database,
    date: string,
    officeToday: string,
): Promise<BudgetDayResponse> {
    validateReportingDate(date, officeToday);
    await synchronizeDate(db, date);
    const items = await readVisibleLines(db, date);
    const totals = emptyTotals();
    for (const item of items) addLineToTotals(totals, item);
    const userSpendings = await getUserSpendings(db, date, date);
    return { date, totals, items, userSpendings };
}

export async function getBudgetRange(
    db: Database,
    start: string,
    end: string,
    officeToday: string,
): Promise<BudgetRangeResponse> {
    const { parsedStart, parsedEnd } = validateRange(start, end, officeToday);
    const orderDates = await db.selectDistinct({ date: orders.date }).from(orders)
        .where(and(gte(orders.date, start), lte(orders.date, end)));
    const generatedDates = await db.selectDistinct({ date: dailyPurchaseItems.date })
        .from(dailyPurchaseItems)
        .where(and(
            gte(dailyPurchaseItems.date, start),
            lte(dailyPurchaseItems.date, end),
            isNotNull(dailyPurchaseItems.sourceKey),
        ));
    const datesToSynchronize = new Set([
        ...orderDates.map((row) => row.date),
        ...generatedDates.map((row) => row.date),
    ]);
    for (const date of datesToSynchronize) {
        await synchronizeDate(db, date);
    }

    const rows = await db.select().from(dailyPurchaseItems)
        .where(and(
            gte(dailyPurchaseItems.date, start),
            lte(dailyPurchaseItems.date, end),
            eq(dailyPurchaseItems.isRemoved, false),
        ));
    const lines = rows.map(toBudgetLine);
    const totals = emptyTotals();
    const totalsByDate = new Map<string, BudgetTotals>();
    const linesByDate = new Map<string, BudgetLine[]>();
    const itemGroups = new Map<string, BudgetRangeResponse['items'][number]>();

    for (const line of lines) {
        addLineToTotals(totals, line);
        let dayTotals = totalsByDate.get(line.date);
        if (!dayTotals) {
            dayTotals = emptyTotals();
            totalsByDate.set(line.date, dayTotals);
        }
        addLineToTotals(dayTotals, line);

        let dayLines = linesByDate.get(line.date);
        if (!dayLines) {
            dayLines = [];
            linesByDate.set(line.date, dayLines);
        }
        dayLines.push(line);

        const itemKey = `${line.itemType}::${line.name}`;
        const existing = itemGroups.get(itemKey);
        if (existing) {
            existing.quantity += line.quantity;
            existing.totalRupees += line.lineTotalRupees;
        } else {
            itemGroups.set(itemKey, {
                name: line.name,
                itemType: line.itemType,
                quantity: line.quantity,
                totalRupees: line.lineTotalRupees,
            });
        }
    }

    const days: BudgetRangeResponse['days'] = [];
    for (let time = parsedStart.getTime(); time <= parsedEnd.getTime(); time += DAY_MS) {
        const date = new Date(time).toISOString().slice(0, 10);
        days.push({
            date,
            totals: totalsByDate.get(date) ?? emptyTotals(),
            items: linesByDate.get(date) ?? [],
        });
    }
    const items = Array.from(itemGroups.values()).sort((a, b) =>
        a.name.localeCompare(b.name) || a.itemType.localeCompare(b.itemType),
    );
    const userSpendings = await getUserSpendings(db, start, end);
    return { start, end, totals, days, items, userSpendings };
}

export async function createPurchaseItem(
    db: Database,
    date: string,
    input: PurchaseItemInput,
    officeToday: string,
): Promise<BudgetLine> {
    validateReportingDate(date, officeToday);
    const normalized = normalizeItem(input);
    const [created] = await db.insert(dailyPurchaseItems).values({
        date,
        sourceKey: null,
        sourceSnackId: null,
        ...normalized,
        isEdited: true,
    }).returning();
    return toBudgetLine(created!);
}

export async function updatePurchaseItem(
    db: Database,
    date: string,
    id: string,
    input: PurchaseItemUpdate,
    _officeToday: string,
): Promise<BudgetLine> {
    parseDate(date);
    const [existing] = await db.select().from(dailyPurchaseItems).where(and(
        eq(dailyPurchaseItems.id, id),
        eq(dailyPurchaseItems.date, date),
        eq(dailyPurchaseItems.isRemoved, false),
    ));
    if (!existing) throw new BudgetNotFoundError('Purchase item not found');
    const has = (key: keyof PurchaseItemInput) => Object.prototype.hasOwnProperty.call(input, key);
    const normalized = normalizeItem({
        name: has('name') ? input.name : existing.name,
        itemType: has('itemType') ? input.itemType : existing.itemType,
        quantity: has('quantity') ? input.quantity : existing.quantity,
        unitPriceRupees: has('unitPriceRupees')
            ? input.unitPriceRupees
            : existing.unitPriceRupees,
    });

    const [updated] = await db.update(dailyPurchaseItems)
        .set({ ...normalized, isEdited: true, updatedAt: new Date() })
        .where(eq(dailyPurchaseItems.id, id))
        .returning();
    return toBudgetLine(updated!);
}

export async function removePurchaseItem(
    db: Database,
    date: string,
    id: string,
    _officeToday: string,
): Promise<void> {
    parseDate(date);
    const [existing] = await db.select({ id: dailyPurchaseItems.id })
        .from(dailyPurchaseItems)
        .where(and(
            eq(dailyPurchaseItems.id, id),
            eq(dailyPurchaseItems.date, date),
            eq(dailyPurchaseItems.isRemoved, false),
        ));
    if (!existing) throw new BudgetNotFoundError('Purchase item not found');
    await db.update(dailyPurchaseItems)
        .set({ isEdited: true, isRemoved: true, updatedAt: new Date() })
        .where(eq(dailyPurchaseItems.id, id));
}
