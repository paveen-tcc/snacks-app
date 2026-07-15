import { createDb } from './db';
import { appSettings, holidays, shutdownDays, orders, pushTokens } from './db/schema';
import { eq, sql, inArray } from 'drizzle-orm';
import {
    getOrderWindow,
    officeMinutesOfDay,
    windowCloseMinutes,
    effectiveOrderDate,
    formatClockMinutes,
} from './lib/orderWindow';
import { sendPushToTokens, isFcmConfigured } from './lib/fcm';
import type { Bindings } from './index';

// app_settings keys used by the reminder job.
const LAST_REMINDER_KEY = 'last_reminder_date';
const LEAD_MINUTES_KEY = 'reminder_lead_minutes';
const DEFAULT_LEAD_MINUTES = 20;
const REMINDER_TITLE = 'Snack order closing soon 🍪';
const MANUAL_REMINDER_BODY = "Order now, it's closing.";
// Fire anywhere in this window after the target minute so a skipped/delayed
// cron tick still delivers; the once-per-day dedup flag prevents repeats.
const GRACE_MINUTES = 5;

type ReminderDb = ReturnType<typeof createDb>;

export type OrderReminderResult = {
    orderDate: string;
    targeted: number;
    sent: number;
    failed: number;
    pruned: number;
    skippedReason?: string;
};

async function getSetting(db: ReminderDb, key: string): Promise<string | null> {
    const [row] = await db.select({ value: appSettings.value })
        .from(appSettings)
        .where(eq(appSettings.key, key))
        .limit(1);
    return row?.value ?? null;
}

async function putSetting(db: ReminderDb, key: string, value: string): Promise<void> {
    await db.insert(appSettings)
        .values({ key, value })
        .onConflictDoUpdate({ target: appSettings.key, set: { value } });
}

async function closedDayReason(db: ReminderDb, effectiveDate: string): Promise<string | null> {
    const [holiday] = await db.select().from(holidays)
        .where(sql`${holidays.date} = ${effectiveDate}`).limit(1);
    if (holiday) return holiday.name ?? 'Holiday';

    const [shutdown] = await db.select().from(shutdownDays)
        .where(sql`${shutdownDays.date} = ${effectiveDate}`).limit(1);
    if (shutdown) return shutdown.reason ?? 'Shutdown day';

    return null;
}

async function targetTokensForOpenOrders(
    db: ReminderDb,
    effectiveDate: string,
): Promise<string[]> {
    // Who has already ordered for the day?
    const orderedRows = await db
        .selectDistinct({ userId: orders.userId })
        .from(orders)
        .where(sql`${orders.date} = ${effectiveDate}`);
    const orderedIds = new Set(orderedRows.map((r) => r.userId));

    // Target = registered devices whose user hasn't ordered.
    const tokenRows = await db
        .select({ token: pushTokens.token, userId: pushTokens.userId })
        .from(pushTokens);
    return tokenRows
        .filter((r) => !orderedIds.has(r.userId))
        .map((r) => r.token);
}

async function sendOrderReminder(
    env: Bindings,
    db: ReminderDb,
    effectiveDate: string,
    targetTokens: string[],
    body: string,
): Promise<OrderReminderResult> {
    if (targetTokens.length === 0) {
        return {
            orderDate: effectiveDate,
            targeted: 0,
            sent: 0,
            failed: 0,
            pruned: 0,
        };
    }

    const results = await sendPushToTokens(env.FCM_SERVICE_ACCOUNT, targetTokens, {
        title: REMINDER_TITLE,
        body,
    });

    // Prune tokens FCM reports as permanently invalid (uninstalled / stale).
    const dead = results
        .filter((r) => r.status === 404 || r.status === 400)
        .map((r) => r.token);
    if (dead.length > 0) {
        await db.delete(pushTokens).where(inArray(pushTokens.token, dead));
    }

    const sent = results.filter((r) => r.ok).length;
    return {
        orderDate: effectiveDate,
        targeted: targetTokens.length,
        sent,
        failed: targetTokens.length - sent,
        pruned: dead.length,
    };
}

/**
 * Admin-triggered reminder. This deliberately skips the cron time-window and
 * once-per-day dedupe so an admin can send an ad-hoc reminder without changing
 * the scheduled reminder state. It still uses the same order-date, holiday,
 * shutdown, "not yet ordered" and stale-token pruning logic as the cron.
 */
export async function runManualOrderReminder(
    env: Bindings,
    db: ReminderDb,
    body = MANUAL_REMINDER_BODY,
): Promise<OrderReminderResult> {
    const window = await getOrderWindow(db);
    const effectiveDate = effectiveOrderDate(window);

    const reason = await closedDayReason(db, effectiveDate);
    if (reason) {
        return {
            orderDate: effectiveDate,
            targeted: 0,
            sent: 0,
            failed: 0,
            pruned: 0,
            skippedReason: reason,
        };
    }

    const targetTokens = await targetTokensForOpenOrders(db, effectiveDate);
    return sendOrderReminder(env, db, effectiveDate, targetTokens, body);
}

/**
 * Daily "order closing soon" reminder. Invoked by the cron trigger every
 * minute; it only does real work during the single minute that is
 * `reminder_lead_minutes` (default 20) before the order window closes, then
 * pushes to every registered device whose user has NOT ordered for the day.
 *
 * Time is evaluated in office-local time (see lib/orderWindow), so the reminder
 * tracks the admin-configured cutoff and can't be skewed by client clocks.
 */
export async function runOrderReminder(env: Bindings): Promise<void> {
    if (!isFcmConfigured(env.FCM_SERVICE_ACCOUNT)) {
        // Nothing to do until the service account secret is set.
        return;
    }

    const db = createDb(env.DB);
    const window = await getOrderWindow(db);

    const nowMinutes = officeMinutesOfDay(window.offsetMinutes);
    const closeMinutes = windowCloseMinutes(window);

    const leadRaw = await getSetting(db, LEAD_MINUTES_KEY);
    const leadParsed = leadRaw === null ? NaN : Number(leadRaw);
    const lead = Number.isFinite(leadParsed) && leadParsed > 0 ? leadParsed : DEFAULT_LEAD_MINUTES;

    const reminderMinute = closeMinutes - lead;

    // Cron fires every minute; act within a short grace window after the target
    // minute. The once-per-day flag below collapses this to a single send.
    if (nowMinutes < reminderMinute || nowMinutes >= reminderMinute + GRACE_MINUTES) {
        return;
    }

    const effectiveDate = effectiveOrderDate(window);

    // Don't nag on a closed day.
    const reason = await closedDayReason(db, effectiveDate);
    if (reason) return;

    // Idempotency: at most one reminder per order date.
    const lastSent = await getSetting(db, LAST_REMINDER_KEY);
    if (lastSent === effectiveDate) return;

    const targetTokens = await targetTokensForOpenOrders(db, effectiveDate);

    if (targetTokens.length === 0) {
        await putSetting(db, LAST_REMINDER_KEY, effectiveDate);
        return;
    }

    const closeLabel = formatClockMinutes(closeMinutes);
    const result = await sendOrderReminder(
        env,
        db,
        effectiveDate,
        targetTokens,
        `Ordering closes at ${closeLabel}. Tap to pick your snacks before you miss out!`,
    );

    // Mark sent only after the FCM call returns. If auth/token exchange throws,
    // the cron can retry during the grace window instead of suppressing the day.
    await putSetting(db, LAST_REMINDER_KEY, effectiveDate);

    console.log(`order reminder: ${result.sent}/${result.targeted} delivered for ${effectiveDate}`);
}
