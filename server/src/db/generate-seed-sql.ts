import { menuSnackCatalog } from './menu_catalog';

// Mirrors the normalization the old Postgres seed used for duplicate checks.
const normalizeWhitespace = (value: string) => value.trim().replace(/\s+/g, ' ');
const normalizeName = (value: string) => normalizeWhitespace(value).toLowerCase();
const normalizeCategory = (value: string | null | undefined) => {
    if (value == null) return 'general';
    const normalized = normalizeWhitespace(value);
    return normalized.length === 0 ? 'general' : normalized.toLowerCase();
};
const q = (value: string | null | undefined) =>
    value == null ? 'NULL' : `'${value.replace(/'/g, "''")}'`;

const lines: string[] = [];

// App settings — INSERT OR IGNORE mirrors the old onConflictDoNothing().
const settings: Array<[string, string]> = [
    ['cutoff_time', '12:00'],
    ['whatsapp_number', '919876543210'],
    ['whatsapp_is_group', 'false'],
    ['holiday_country', 'IN'],
];
for (const [key, value] of settings) {
    lines.push(
        `INSERT OR IGNORE INTO app_settings (key, value, advance_order_mode, advance_window_start, advance_window_end) ` +
        `VALUES (${q(key)}, ${q(value)}, 0, '06:00', '22:00');`,
    );
}

// Menu catalog — insert-if-missing on normalized (name, category). The SQL
// normalization (lower/trim) doesn't collapse internal whitespace like the
// old JS check did; catalog names are clean so this is equivalent in practice.
for (const item of menuSnackCatalog) {
    lines.push(
        `INSERT INTO snacks (id, name, category, emoji, is_veg, is_default, is_active, serving_size, share_count, sort_order, created_at) ` +
        `SELECT ${q(crypto.randomUUID())}, ${q(item.name)}, ${q(item.category)}, ${q(item.emoji)}, ${item.isVeg ? 1 : 0}, 0, 1, ${q(item.servingSize)}, 1, ${item.sortOrder}, ${Date.now()} ` +
        `WHERE NOT EXISTS (SELECT 1 FROM snacks WHERE lower(trim(name)) = ${q(normalizeName(item.name))} ` +
        `AND lower(coalesce(nullif(trim(category), ''), 'general')) = ${q(normalizeCategory(item.category))});`,
    );
}

await Bun.write('seed.sql', lines.join('\n') + '\n');
console.log(`Wrote seed.sql with ${lines.length} statements`);
