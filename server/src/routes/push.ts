import { Hono } from 'hono';
import { pushTokens } from '../db/schema';
import { eq, and } from 'drizzle-orm';
import { authMiddleware } from '../middleware/auth';
import type { AuthContext } from '../middleware/auth';

const pushRoutes = new Hono<AuthContext>();

// Device push-token registration is user-scoped.
pushRoutes.use('*', authMiddleware);

// Register (or refresh) this device's FCM token for the current user. Token is
// the primary key, so re-registering the same device just re-points it.
pushRoutes.post('/token', async (c) => {
    try {
        const db = c.get('db');
        const user = c.get('user');
        const { token, platform } = await c.req.json();

        if (typeof token !== 'string' || token.trim().length === 0) {
            return c.json({ error: 'token is required' }, 400);
        }
        const normalizedPlatform =
            typeof platform === 'string' && platform.trim().length > 0
                ? platform.trim()
                : 'android';

        await db.insert(pushTokens)
            .values({
                token,
                userId: user.userId,
                platform: normalizedPlatform,
                updatedAt: new Date(),
            })
            .onConflictDoUpdate({
                target: pushTokens.token,
                set: {
                    userId: user.userId,
                    platform: normalizedPlatform,
                    updatedAt: new Date(),
                },
            });

        return c.json({ success: true }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

// Unregister a device token (e.g. on logout). Scoped to the current user so a
// user can't drop someone else's token.
pushRoutes.delete('/token', async (c) => {
    try {
        const db = c.get('db');
        const user = c.get('user');
        const body = await c.req.json().catch(() => ({} as { token?: unknown }));
        const token = (body as { token?: unknown }).token;

        if (typeof token === 'string' && token.length > 0) {
            await db.delete(pushTokens).where(
                and(eq(pushTokens.token, token), eq(pushTokens.userId, user.userId)),
            );
        }
        return c.json({ success: true }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

export default pushRoutes;
