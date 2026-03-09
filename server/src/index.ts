import { Hono } from 'hono';
import { logger } from 'hono/logger';
import { cors } from 'hono/cors';
import { createDb } from './db';
import type { Database } from './db';

import authRoutes from './routes/auth';
import snackRoutes from './routes/snacks';
import orderRoutes from './routes/orders';
import drinkRoutes from './routes/drinks';
import adminRoutes from './routes/admin';

// Cloudflare Worker env bindings
export type Bindings = {
    DATABASE_URL: string;
    JWT_SECRET: string;
    AZURE_TENANT_ID: string;
    AZURE_CLIENT_ID: string;
};

// Variables injected into context per-request
export type AppVariables = {
    db: Database;
    jwtSecret: string;
    user: import('./utils/jwt').JWTPayload;
};

export type AppEnv = { Bindings: Bindings; Variables: AppVariables };

const app = new Hono<AppEnv>();

// Middleware
app.use('*', logger());
app.use('*', cors());

// Inject db and jwtSecret into every request context
app.use('*', async (c, next) => {
    const db = createDb(c.env.DATABASE_URL);
    c.set('db', db);
    c.set('jwtSecret', c.env.JWT_SECRET);
    await next();
});

// Health check
app.get('/health', (c) => {
    return c.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Debug: test JWKS fetch
app.get('/debug/jwks', async (c) => {
    const tenantId = c.env.AZURE_TENANT_ID;
    const url = `https://login.microsoftonline.com/${tenantId}/discovery/v2.0/keys`;
    try {
        const res = await fetch(url);
        const body = await res.json();
        return c.json({ status: res.status, tenantId, url, keys: body });
    } catch (err: any) {
        return c.json({ error: err.message, tenantId, url });
    }
});

// Mount routes
app.route('/api/auth', authRoutes);
app.route('/api/snacks', snackRoutes);
app.route('/api/orders', orderRoutes);
app.route('/api/drinks', drinkRoutes);
app.route('/api/admin', adminRoutes);

app.notFound((c) => {
    return c.json({ error: 'Not Found' }, 404);
});

app.onError((err, c) => {
    console.error(`${err}`);
    return c.json({ error: 'Internal Server Error', message: err.message }, 500);
});

export default app;
