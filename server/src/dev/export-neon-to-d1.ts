import { neon } from '@neondatabase/serverless';

// One-off Neon → D1 exporter. Reads every table from the old Postgres
// database and writes neon-export.sql containing SQLite INSERTs matching the
// new schema (booleans → 0/1, timestamptz → epoch ms, jsonb → JSON text).
// Usage: DATABASE_URL='postgresql://...' bun run src/dev/export-neon-to-d1.ts

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
    throw new Error('Set DATABASE_URL to the Neon connection string.');
}
const sql = neon(databaseUrl);

type ColType = 'text' | 'bool' | 'ts' | 'json' | 'int' | 'date';

// Insertion order satisfies foreign keys (users first).
const TABLES: Array<{ name: string; columns: Array<[string, ColType]> }> = [
    { name: 'users', columns: [['id', 'text'], ['username', 'text'], ['email', 'text'], ['microsoft_id', 'text'], ['device_id', 'text'], ['is_admin', 'bool'], ['created_at', 'ts']] },
    { name: 'snacks', columns: [['id', 'text'], ['name', 'text'], ['category', 'text'], ['emoji', 'text'], ['is_veg', 'bool'], ['is_default', 'bool'], ['is_active', 'bool'], ['serving_size', 'text'], ['share_count', 'int'], ['sort_order', 'int'], ['created_at', 'ts']] },
    { name: 'holidays', columns: [['id', 'text'], ['date', 'date'], ['name', 'text'], ['source', 'text'], ['created_by', 'text']] },
    { name: 'shutdown_days', columns: [['id', 'text'], ['date', 'date'], ['reason', 'text'], ['created_by', 'text']] },
    { name: 'app_settings', columns: [['key', 'text'], ['value', 'text'], ['advance_order_mode', 'bool'], ['advance_window_start', 'text'], ['advance_window_end', 'text']] },
    { name: 'push_tokens', columns: [['token', 'text'], ['user_id', 'text'], ['platform', 'text'], ['updated_at', 'ts']] },
    { name: 'orders', columns: [['id', 'text'], ['user_id', 'text'], ['date', 'date'], ['snack_id', 'text'], ['snack_name_snapshot', 'text'], ['snack_emoji_snapshot', 'text'], ['is_default_assigned', 'bool'], ['ordered_at', 'ts'], ['updated_at', 'ts']] },
    { name: 'sync_queue', columns: [['id', 'text'], ['user_id', 'text'], ['table_name', 'text'], ['record_id', 'text'], ['action', 'text'], ['payload', 'json'], ['created_at', 'ts'], ['synced_at', 'ts']] },
];

function lit(value: unknown, type: ColType): string {
    if (value === null || value === undefined) return 'NULL';
    switch (type) {
        case 'bool':
            return value === true || value === 't' || value === 1 ? '1' : '0';
        case 'ts': {
            const d = value instanceof Date ? value : new Date(String(value));
            if (Number.isNaN(d.getTime())) throw new Error(`Bad timestamp: ${String(value)}`);
            return String(d.getTime());
        }
        case 'date': {
            const d = value instanceof Date ? value : new Date(String(value));
            if (Number.isNaN(d.getTime())) throw new Error(`Bad date: ${String(value)}`);
            const year = d.getFullYear();
            const month = String(d.getMonth() + 1).padStart(2, '0');
            const day = String(d.getDate()).padStart(2, '0');
            return `'${year}-${month}-${day}'`;
        }
        case 'int':
            return String(Number(value));
        case 'json':
            return `'${JSON.stringify(value).replace(/'/g, "''")}'`;
        case 'text':
            return `'${String(value).replace(/'/g, "''")}'`;
    }
}

const lines: string[] = ['PRAGMA defer_foreign_keys = true;'];
const counts: Record<string, number> = {};

for (const table of TABLES) {
    const rows = (await sql.query(`SELECT * FROM ${table.name}`)) as Record<string, unknown>[];
    counts[table.name] = rows.length;
    const columnNames = table.columns.map(([name]) => name).join(', ');
    for (const row of rows) {
        const values = table.columns.map(([name, type]) => lit(row[name], type)).join(', ');
        lines.push(`INSERT INTO ${table.name} (${columnNames}) VALUES (${values});`);
    }
}

await Bun.write('neon-export.sql', lines.join('\n') + '\n');
console.log('Exported row counts:', JSON.stringify(counts, null, 2));
console.log('Wrote neon-export.sql — do NOT commit this file (contains user emails).');
