import { drizzle } from 'drizzle-orm/d1';
import * as schema from './schema';

// D1Database is a global type via tsconfig "types": ["@cloudflare/workers-types"].
export function createDb(d1: D1Database) {
    return drizzle(d1, { schema });
}

export type Database = ReturnType<typeof createDb>;
