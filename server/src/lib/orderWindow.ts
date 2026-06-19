import { holidays, shutdownDays, appSettings } from '../db/schema';
import { eq, sql } from 'drizzle-orm';
import type { Database } from '../db';

// --- Order window enforcement --------------------------------------------
// Cloudflare Workers run in UTC, but the cutoff / advance-window values are
// office wall-clock strings with no stored timezone. The Flutter client used
// to evaluate them against the *device* clock — which is exactly why changing
// the phone's time let users place orders after the window had closed. We now
// evaluate the window server-side, in office-local time, so it can't be
// bypassed from the client. The same helpers drive the daily reminder cron.
//
// Default is IST (UTC+5:30 = 330 min), matching the device timezone the client
// already assumed. Override per-deployment with an app_settings row keyed
// `timezone_offset_minutes` (set via PUT /api/admin/settings) — no code change.
export const DEFAULT_OFFICE_UTC_OFFSET_MINUTES = 330;

export type OrderWindow = {
    advanceOrderMode: boolean;
    advanceWindowStart: string;
    advanceWindowEnd: string;
    cutoffTime: string;
    offsetMinutes: number;
};

// Parse an "HH:mm" wall-clock string into minutes-since-midnight, or null.
export function parseHourMinute(value: string | null | undefined): number | null {
    if (typeof value !== 'string') return null;
    const parts = value.split(':');
    if (parts.length !== 2) return null;
    const hour = Number(parts[0]);
    const minute = Number(parts[1]);
    if (!Number.isInteger(hour) || !Number.isInteger(minute)) return null;
    return hour * 60 + minute;
}

// A Date whose UTC getters read as the office-local wall clock.
export function officeNow(offsetMinutes: number) {
    return new Date(Date.now() + offsetMinutes * 60_000);
}

export function officeDateString(offsetMinutes: number, addDays = 0) {
    const date = officeNow(offsetMinutes);
    date.setUTCDate(date.getUTCDate() + addDays);
    return date.toISOString().split('T')[0]!;
}

// Office-local minutes-since-midnight for "now".
export function officeMinutesOfDay(offsetMinutes: number) {
    const now = officeNow(offsetMinutes);
    return now.getUTCHours() * 60 + now.getUTCMinutes();
}

export async function getOrderWindow(db: Database): Promise<OrderWindow> {
    const [row] = await db.select({
        value: appSettings.value,
        advanceOrderMode: appSettings.advanceOrderMode,
        advanceWindowStart: appSettings.advanceWindowStart,
        advanceWindowEnd: appSettings.advanceWindowEnd,
    })
        .from(appSettings)
        .where(eq(appSettings.key, 'cutoff_time'))
        .limit(1);

    const [tzRow] = await db.select({ value: appSettings.value })
        .from(appSettings)
        .where(eq(appSettings.key, 'timezone_offset_minutes'))
        .limit(1);
    const parsedOffset = tzRow ? Number(tzRow.value) : NaN;

    return {
        advanceOrderMode: row?.advanceOrderMode ?? false,
        advanceWindowStart: row?.advanceWindowStart ?? '06:00',
        advanceWindowEnd: row?.advanceWindowEnd ?? '22:00',
        cutoffTime: row?.value ?? '12:00',
        offsetMinutes: Number.isFinite(parsedOffset)
            ? parsedOffset
            : DEFAULT_OFFICE_UTC_OFFSET_MINUTES,
    };
}

export function effectiveOrderDate(window: OrderWindow) {
    return officeDateString(window.offsetMinutes, window.advanceOrderMode ? 1 : 0);
}

// Office-local minute-of-day at which the order window closes today.
export function windowCloseMinutes(window: OrderWindow): number {
    return window.advanceOrderMode
        ? (parseHourMinute(window.advanceWindowEnd) ?? 22 * 60)
        : (parseHourMinute(window.cutoffTime) ?? 12 * 60);
}

// Returns a human-readable reason when ordering is currently closed, else null.
// Mirrors the client's home_helpers semantics — open when now <= cutoff, or
// start <= now <= end in advance mode — so client gating and server
// enforcement stay in agreement.
export async function orderingClosedReason(
    db: Database,
    window: OrderWindow,
): Promise<string | null> {
    const orderDate = effectiveOrderDate(window);

    const [holiday] = await db.select().from(holidays)
        .where(sql`${holidays.date} = ${orderDate}`).limit(1);
    if (holiday) return holiday.name ?? 'Holiday';

    const [shutdown] = await db.select().from(shutdownDays)
        .where(sql`${shutdownDays.date} = ${orderDate}`).limit(1);
    if (shutdown) return shutdown.reason ?? 'Shutdown day';

    const nowMinutes = officeMinutesOfDay(window.offsetMinutes);

    if (window.advanceOrderMode) {
        const start = parseHourMinute(window.advanceWindowStart) ?? 6 * 60;
        const end = parseHourMinute(window.advanceWindowEnd) ?? 22 * 60;
        if (nowMinutes < start || nowMinutes > end) {
            return 'The ordering window is currently closed';
        }
        return null;
    }

    const cutoff = parseHourMinute(window.cutoffTime) ?? 12 * 60;
    if (nowMinutes > cutoff) {
        return 'The ordering cutoff time has passed for today';
    }
    return null;
}

// Format an office-local minute-of-day as "h:mm AM/PM".
export function formatClockMinutes(minutesOfDay: number): string {
    const normalized = ((minutesOfDay % 1440) + 1440) % 1440;
    const hour24 = Math.floor(normalized / 60);
    const minute = normalized % 60;
    const period = hour24 >= 12 ? 'PM' : 'AM';
    const hour12 = hour24 % 12 === 0 ? 12 : hour24 % 12;
    return `${hour12}:${minute.toString().padStart(2, '0')} ${period}`;
}
