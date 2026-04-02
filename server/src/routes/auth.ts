import { Hono } from 'hono';
import { users } from '../db/schema';
import { eq } from 'drizzle-orm';
import { signToken } from '../utils/jwt';
import { verifyMicrosoftToken } from '../utils/microsoft';
import { authMiddleware } from '../middleware/auth';
import type { AppEnv } from '../index';

const authRoutes = new Hono<AppEnv>();

authRoutes.post('/microsoft', async (c) => {
    try {
        const db = c.get('db');
        const jwtSecret = c.get('jwtSecret');
        const { idToken } = await c.req.json();

        if (!idToken) {
            return c.json({ error: 'idToken is required' }, 400);
        }

        const claims = await verifyMicrosoftToken(
            idToken,
            c.env.AZURE_TENANT_ID,
            c.env.AZURE_CLIENT_ID,
        );

        // 1. Look up by microsoftId
        let [user] = await db.select().from(users)
            .where(eq(users.microsoftId, claims.oid))
            .limit(1);

        if (!user) {
            // 2. Fall back to email match (migrates existing users)
            [user] = await db.select().from(users)
                .where(eq(users.email, claims.email))
                .limit(1);

            if (user) {
                // Link existing user to their Microsoft account
                await db.update(users)
                    .set({ microsoftId: claims.oid })
                    .where(eq(users.id, user.id));
            }
        }

        if (!user) {
            // 3. Create new user
            const userCount = await db.select().from(users);
            const isFirstUser = userCount.length === 0;

            [user] = await db.insert(users).values({
                username: claims.name,
                email: claims.email,
                microsoftId: claims.oid,
                isAdmin: isFirstUser,
            }).returning();
        }

        if (!user) {
            return c.json({ error: 'Failed to create or find user' }, 500);
        }

        const token = await signToken({ userId: user.id, isAdmin: !!user.isAdmin }, jwtSecret);

        return c.json({ user, token }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

authRoutes.get('/session', authMiddleware, async (c) => {
    try {
        const db = c.get('db');
        const jwtSecret = c.get('jwtSecret');
        const authUser = c.get('user');

        const [user] = await db.select()
            .from(users)
            .where(eq(users.id, authUser.userId))
            .limit(1);

        if (!user) {
            return c.json({ error: 'User not found' }, 404);
        }

        const token = await signToken(
            { userId: user.id, isAdmin: !!user.isAdmin },
            jwtSecret,
        );

        return c.json({ user, token }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

export default authRoutes;
