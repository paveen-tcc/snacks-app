import { Hono } from 'hono';
import { logger } from 'hono/logger';
import { cors } from 'hono/cors';

import authRoutes from './routes/auth';
import snackRoutes from './routes/snacks';
import orderRoutes from './routes/orders';
import drinkRoutes from './routes/drinks';
import adminRoutes from './routes/admin';

const app = new Hono();

// Middleware
app.use('*', logger());
app.use('*', cors());

// Health check
app.get('/health', (c) => {
    return c.json({ status: 'ok', timestamp: new Date().toISOString() });
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

export default {
    port: process.env.PORT || 3000,
    fetch: app.fetch,
};
