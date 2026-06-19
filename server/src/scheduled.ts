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
// Fire anywhere in this window after the target minute so a skipped/delayed
// cron tick still delivers; the once-per-day dedup flag prevents repeats.
const GRACE_MINUTES = 5;

async function getSetting(db: ReturnType<typeof createDb>, key: string): Promise<string | null> {
    const [row] = await db.select({ value: appSettings.value })
        .from(appSettings)
        .where(eq(appSettings.key, key))
        .limit(1);
    return row?.value ?? null;
}

async function putSetting(db: ReturnType<typeof createDb>, key: string, value: string): Promise<void> {
    await db.insert(appSettings)
        .values({ key, value })
        .onConflictDoUpdate({ target: appSettings.key, set: { value } });
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

    const db = createDb(env.DATABASE_URL);
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
    const [holiday] = await db.select().from(holidays)
        .where(sql`${holidays.date} = ${effectiveDate}`).limit(1);
    if (holiday) return;
    const [shutdown] = await db.select().from(shutdownDays)
        .where(sql`${shutdownDays.date} = ${effectiveDate}`).limit(1);
    if (shutdown) return;

    // Idempotency: at most one reminder per order date.
    const lastSent = await getSetting(db, LAST_REMINDER_KEY);
    if (lastSent === effectiveDate) return;

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
    const targetTokens = tokenRows
        .filter((r) => !orderedIds.has(r.userId))
        .map((r) => r.token);

    // Mark sent up-front so an overlapping/slow run can't double-fire.
    await putSetting(db, LAST_REMINDER_KEY, effectiveDate);

    if (targetTokens.length === 0) return;

    const closeLabel = formatClockMinutes(closeMinutes);
    const results = await sendPushToTokens(env.FCM_SERVICE_ACCOUNT, targetTokens, {
        title: 'Snack order closing soon 🍪',
        body: `Ordering closes at ${closeLabel}. Tap to pick your snacks before you miss out!`,
    });

    // Prune tokens FCM reports as permanently invalid (uninstalled / stale).
    const dead = results
        .filter((r) => r.status === 404 || r.status === 400)
        .map((r) => r.token);
    if (dead.length > 0) {
        await db.delete(pushTokens).where(inArray(pushTokens.token, dead));
    }

    const sent = results.filter((r) => r.ok).length;
    console.log(`order reminder: ${sent}/${targetTokens.length} delivered for ${effectiveDate}`);
}
