import { describe, expect, test } from 'bun:test';
import { Hono } from 'hono';
import type { Database } from '../db';
import type { AppEnv } from '../index';
import { signToken } from '../utils/jwt';
import budgetRoutes from './budget';

function createTestApp() {
    const app = new Hono<AppEnv>();
    app.use('*', async (c, next) => {
        c.set('db', {} as Database);
        c.set('jwtSecret', 'test-secret');
        await next();
    });
    app.route('/api/admin/budget', budgetRoutes);
    return app;
}

describe('budget route authorization', () => {
    test('rejects requests without authentication', async () => {
        const response = await createTestApp().request('/api/admin/budget/2026-08-12');
        expect(response.status).toBe(401);
    });

    test('rejects authenticated non-admin users', async () => {
        const token = await signToken({ userId: 'employee', isAdmin: false }, 'test-secret');
        const response = await createTestApp().request('/api/admin/budget/2026-08-12', {
            headers: { Authorization: `Bearer ${token}` },
        });
        expect(response.status).toBe(403);
    });
});
