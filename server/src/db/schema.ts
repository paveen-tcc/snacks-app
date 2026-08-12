import {
    sqliteTable,
    text,
    integer,
    index,
    uniqueIndex,
} from 'drizzle-orm/sqlite-core';

// D1/SQLite has no uuid type or gen_random_uuid(); ids are generated
// app-side so inserted rows still get Postgres-style uuid strings.
const uuidPk = (name: string) =>
    text(name).primaryKey().$defaultFn(() => crypto.randomUUID());

// Stored as epoch milliseconds; Drizzle returns Date, so JSON output stays
// ISO-8601 strings — identical to the old timestamptz behavior.
const timestampMs = (name: string) =>
    integer(name, { mode: 'timestamp_ms' });

// Users (username + email, unique username)
export const users = sqliteTable('users', {
    id: uuidPk('id'),
    username: text('username', { length: 100 }).unique().notNull(),
    email: text('email', { length: 255 }).unique().notNull(),
    microsoftId: text('microsoft_id', { length: 255 }).unique(),
    deviceId: text('device_id', { length: 255 }),
    isAdmin: integer('is_admin', { mode: 'boolean' }).default(false),
    createdAt: timestampMs('created_at').$defaultFn(() => new Date()),
});

// Snack catalog (flat list, admin controls visibility)
export const snacks = sqliteTable('snacks', {
    id: uuidPk('id'),
    name: text('name', { length: 100 }).notNull(),
    category: text('category', { length: 100 }),
    emoji: text('emoji', { length: 512 }),
    isVeg: integer('is_veg', { mode: 'boolean' }).default(true),
    isDefault: integer('is_default', { mode: 'boolean' }).default(false), // admin-designated default
    isActive: integer('is_active', { mode: 'boolean' }).default(true),    // admin toggle to show/hide
    servingSize: text('serving_size', { length: 50 }), // per-person: "2 pieces", "1 bowl"
    shareCount: integer('share_count').notNull().default(1), // 1 = per-person, 2 = serves two, etc.
    priceRupees: integer('price_rupees').notNull().default(0),
    sortOrder: integer('sort_order').default(0),
    createdAt: timestampMs('created_at').$defaultFn(() => new Date()),
});

// Employee snack orders (one per user per day); date is 'YYYY-MM-DD' text,
// matching what the Flutter client already parses.
export const orders = sqliteTable('orders', {
    id: uuidPk('id'),
    userId: text('user_id').references(() => users.id).notNull(),
    date: text('date').notNull(),
    snackId: text('snack_id').notNull(),
    snackNameSnapshot: text('snack_name_snapshot', { length: 100 }),
    snackEmojiSnapshot: text('snack_emoji_snapshot', { length: 512 }),
    snackPriceRupeesSnapshot: integer('snack_price_rupees_snapshot'),
    snackShareCountSnapshot: integer('snack_share_count_snapshot'),
    snackCategorySnapshot: text('snack_category_snapshot', { length: 100 }),
    isDefaultAssigned: integer('is_default_assigned', { mode: 'boolean' }).default(false),
    orderedAt: timestampMs('ordered_at').$defaultFn(() => new Date()),
    updatedAt: timestampMs('updated_at').$defaultFn(() => new Date()),
}, (t) => ({
    userDateIdx: index('orders_user_date_idx').on(t.userId, t.date),
}));

// Editable daily purchase ledger used for admin-only budget reporting.
export const dailyPurchaseItems = sqliteTable('daily_purchase_items', {
    id: uuidPk('id'),
    date: text('date').notNull(),
    sourceKey: text('source_key'),
    sourceSnackId: text('source_snack_id'),
    name: text('name', { length: 100 }).notNull(),
    itemType: text('item_type', { enum: ['snack', 'drink'] }).notNull(),
    quantity: integer('quantity').notNull(),
    unitPriceRupees: integer('unit_price_rupees').notNull(),
    isEdited: integer('is_edited', { mode: 'boolean' }).notNull().default(false),
    isRemoved: integer('is_removed', { mode: 'boolean' }).notNull().default(false),
    createdAt: timestampMs('created_at').$defaultFn(() => new Date()),
    updatedAt: timestampMs('updated_at').$defaultFn(() => new Date()),
}, (t) => ({
    dateIdx: index('daily_purchase_items_date_idx').on(t.date),
    dateSourceUnique: uniqueIndex('daily_purchase_items_date_source_unique').on(t.date, t.sourceKey),
}));

// Holidays (hybrid: auto-fetched + manual)
export const holidays = sqliteTable('holidays', {
    id: uuidPk('id'),
    date: text('date').unique().notNull(),
    name: text('name', { length: 100 }),
    source: text('source', { length: 20 }).default('manual'), // 'auto' or 'manual'
    createdBy: text('created_by').references(() => users.id),
});

// Temporary shutdown days
export const shutdownDays = sqliteTable('shutdown_days', {
    id: uuidPk('id'),
    date: text('date').unique().notNull(),
    reason: text('reason', { length: 255 }),
    createdBy: text('created_by').references(() => users.id),
});

// App settings (admin-configurable)
export const appSettings = sqliteTable('app_settings', {
    key: text('key', { length: 50 }).primaryKey(),
    value: text('value').notNull(),
    advanceOrderMode: integer('advance_order_mode', { mode: 'boolean' }).notNull().default(false),
    advanceWindowStart: text('advance_window_start', { length: 5 }).notNull().default('06:00'),
    advanceWindowEnd: text('advance_window_end', { length: 5 }).notNull().default('22:00'),
    // Keys: cutoff_time, whatsapp_number, whatsapp_is_group,
    //        whatsapp_template, holiday_country
});

// Device push tokens (FCM). One row per device install; token is unique, so a
// device that re-logs-in as another user simply re-points to the new userId.
export const pushTokens = sqliteTable('push_tokens', {
    token: text('token', { length: 512 }).primaryKey(),
    userId: text('user_id').references(() => users.id).notNull(),
    platform: text('platform', { length: 20 }).default('android'),
    updatedAt: timestampMs('updated_at').$defaultFn(() => new Date()),
}, (t) => ({
    userIdx: index('push_tokens_user_idx').on(t.userId),
}));

// Offline sync queue
export const syncQueue = sqliteTable('sync_queue', {
    id: uuidPk('id'),
    userId: text('user_id').references(() => users.id).notNull(),
    tableName: text('table_name', { length: 50 }).notNull(),
    recordId: text('record_id').notNull(),
    action: text('action', { length: 10 }).notNull(), // INSERT, UPDATE, DELETE
    payload: text('payload', { mode: 'json' }),
    createdAt: timestampMs('created_at').$defaultFn(() => new Date()),
    syncedAt: timestampMs('synced_at'),
});
