import {
    pgTable,
    uuid,
    varchar,
    boolean,
    timestamp,
    integer,
    date,
    jsonb,
    uniqueIndex,
    index
} from 'drizzle-orm/pg-core';

// Users (username + email, unique username)
export const users = pgTable('users', {
    id: uuid('id').primaryKey().defaultRandom(),
    username: varchar('username', { length: 100 }).unique().notNull(),
    email: varchar('email', { length: 255 }).unique().notNull(),
    microsoftId: varchar('microsoft_id', { length: 255 }).unique(),
    deviceId: varchar('device_id', { length: 255 }),
    isAdmin: boolean('is_admin').default(false),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
});

// Snack catalog (flat list, admin controls visibility)
export const snacks = pgTable('snacks', {
    id: uuid('id').primaryKey().defaultRandom(),
    name: varchar('name', { length: 100 }).notNull(),
    category: varchar('category', { length: 100 }),
    emoji: varchar('emoji', { length: 512 }),
    isVeg: boolean('is_veg').default(true),
    isDefault: boolean('is_default').default(false), // admin-designated default
    isActive: boolean('is_active').default(true),    // admin toggle to show/hide
    servingSize: varchar('serving_size', { length: 50 }), // per-person: "2 pieces", "1 bowl"
    shareCount: integer('share_count').notNull().default(1), // 1 = per-person, 2 = serves two, etc.
    sortOrder: integer('sort_order').default(0),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
});

// Employee snack orders (one per user per day)
export const orders = pgTable('orders', {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id').references(() => users.id).notNull(),
    date: date('date').notNull(),
    snackId: uuid('snack_id').notNull(),
    snackNameSnapshot: varchar('snack_name_snapshot', { length: 100 }),
    snackEmojiSnapshot: varchar('snack_emoji_snapshot', { length: 512 }),
    isDefaultAssigned: boolean('is_default_assigned').default(false),
    orderedAt: timestamp('ordered_at', { withTimezone: true }).defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow(),
}, (t) => ({
    userDateIdx: index('orders_user_date_idx').on(t.userId, t.date),
}));

// Holidays (hybrid: auto-fetched + manual)
export const holidays = pgTable('holidays', {
    id: uuid('id').primaryKey().defaultRandom(),
    date: date('date').unique().notNull(),
    name: varchar('name', { length: 100 }),
    source: varchar('source', { length: 20 }).default('manual'), // 'auto' or 'manual'
    createdBy: uuid('created_by').references(() => users.id),
});

// Temporary shutdown days
export const shutdownDays = pgTable('shutdown_days', {
    id: uuid('id').primaryKey().defaultRandom(),
    date: date('date').unique().notNull(),
    reason: varchar('reason', { length: 255 }),
    createdBy: uuid('created_by').references(() => users.id),
});

// App settings (admin-configurable)
export const appSettings = pgTable('app_settings', {
    key: varchar('key', { length: 50 }).primaryKey(),
    value: varchar('value').notNull(),
    advanceOrderMode: boolean('advance_order_mode').notNull().default(false),
    advanceWindowStart: varchar('advance_window_start', { length: 5 }).notNull().default('06:00'),
    advanceWindowEnd: varchar('advance_window_end', { length: 5 }).notNull().default('22:00'),
    // Keys: cutoff_time, whatsapp_number, whatsapp_is_group,
    //        whatsapp_template, holiday_country
});

// Device push tokens (FCM). One row per device install; token is unique, so a
// device that re-logs-in as another user simply re-points to the new userId.
export const pushTokens = pgTable('push_tokens', {
    token: varchar('token', { length: 512 }).primaryKey(),
    userId: uuid('user_id').references(() => users.id).notNull(),
    platform: varchar('platform', { length: 20 }).default('android'),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow(),
}, (t) => ({
    userIdx: index('push_tokens_user_idx').on(t.userId),
}));

// Offline sync queue
export const syncQueue = pgTable('sync_queue', {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id').references(() => users.id).notNull(),
    tableName: varchar('table_name', { length: 50 }).notNull(),
    recordId: uuid('record_id').notNull(),
    action: varchar('action', { length: 10 }).notNull(), // INSERT, UPDATE, DELETE
    payload: jsonb('payload'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
    syncedAt: timestamp('synced_at', { withTimezone: true }),
});
