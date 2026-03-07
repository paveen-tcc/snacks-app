import type { Context, Next } from 'hono';
import { verifyToken } from '../utils/jwt';
import type { JWTPayload } from '../utils/jwt';

// Define a custom context type to inject the user payload
export type AuthContext = { Variables: { user: JWTPayload } };

export const authMiddleware = async (c: Context, next: Next) => {
    const authHeader = c.req.header('Authorization');

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return c.json({ error: 'Unauthorized: Missing or invalid token' }, 401);
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
        return c.json({ error: 'Unauthorized: Malformed token' }, 401);
    }

    const payload = await verifyToken(token);

    if (!payload) {
        return c.json({ error: 'Unauthorized: Invalid or expired token' }, 401);
    }

    // Inject the decoded user into the context variables
    c.set('user', payload);
    await next();
};

export const adminMiddleware = async (c: Context<AuthContext>, next: Next) => {
    const user = c.get('user');

    if (!user || !user.isAdmin) {
        return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    await next();
};
