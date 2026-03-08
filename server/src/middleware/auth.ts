import type { Context, Next } from 'hono';
import { verifyToken } from '../utils/jwt';
import type { AppEnv } from '../index';

export type AuthContext = AppEnv;

export const authMiddleware = async (c: Context<AppEnv>, next: Next) => {
    const authHeader = c.req.header('Authorization');

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return c.json({ error: 'Unauthorized: Missing or invalid token' }, 401);
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
        return c.json({ error: 'Unauthorized: Malformed token' }, 401);
    }

    const jwtSecret = c.get('jwtSecret');
    const payload = await verifyToken(token, jwtSecret);

    if (!payload) {
        return c.json({ error: 'Unauthorized: Invalid or expired token' }, 401);
    }

    c.set('user', payload);
    await next();
};

export const adminMiddleware = async (c: Context<AppEnv>, next: Next) => {
    const user = c.get('user');

    if (!user || !user.isAdmin) {
        return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    await next();
};
