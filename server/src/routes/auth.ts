import { Hono } from 'hono';
import { users } from '../db/schema';
import { eq, or } from 'drizzle-orm';
import { signToken } from '../utils/jwt';
import type { AppEnv } from '../index';

const authRoutes = new Hono<AppEnv>();

authRoutes.post('/register', async (c) => {
    try {
        const db = c.get('db');
        const jwtSecret = c.get('jwtSecret');
        const { username, email, deviceId } = await c.req.json();

        if (!username || !email) {
            return c.json({ error: 'Username and email are required' }, 400);
        }

        const existingUser = await db.select().from(users).where(
            or(eq(users.username, username), eq(users.email, email))
        ).limit(1);

        if (existingUser.length > 0) {
            return c.json({ error: 'Username or email already exists' }, 409);
        }

        const userCount = await db.select().from(users);
        const isFirstUser = userCount.length === 0;

        const [newUser] = await db.insert(users).values({
            username,
            email,
            deviceId,
            isAdmin: isFirstUser
        }).returning();

        if (!newUser) {
            return c.json({ error: 'Failed to create user' }, 500);
        }

        const token = await signToken({ userId: newUser.id, isAdmin: !!newUser.isAdmin }, jwtSecret);

        return c.json({ user: newUser, token }, 201);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

authRoutes.post('/login', async (c) => {
    try {
        const db = c.get('db');
        const jwtSecret = c.get('jwtSecret');
        const { email } = await c.req.json();

        if (!email) {
            return c.json({ error: 'Email is required' }, 400);
        }

        const [user] = await db.select().from(users).where(eq(users.email, email)).limit(1);

        if (!user) {
            return c.json({ error: 'User not found' }, 404);
        }

        const token = await signToken({ userId: user.id, isAdmin: !!user.isAdmin }, jwtSecret);

        return c.json({ user, token }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

export default authRoutes;
