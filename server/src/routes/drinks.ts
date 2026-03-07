import { Hono } from 'hono';
import { db } from '../db';
import { hotDrinks, drinkVotes } from '../db/schema';
import { and, eq, sql } from 'drizzle-orm';
import { authMiddleware } from '../middleware/auth';
import type { AuthContext } from '../middleware/auth';

const drinkRoutes = new Hono<AuthContext>();

// Get all active hot drinks
drinkRoutes.get('/', async (c) => {
    try {
        const drinks = await db
            .select()
            .from(hotDrinks)
            .where(eq(hotDrinks.isActive, true));

        return c.json({ drinks }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

// Protected routes below
drinkRoutes.use('*', authMiddleware);

// Get today's user vote
drinkRoutes.get('/vote', async (c) => {
    try {
        const user = c.get('user');
        const today = new Date().toISOString().split('T')[0];

        const [vote] = await db.select()
            .from(drinkVotes)
            .where(and(eq(drinkVotes.userId, user.userId), sql`${drinkVotes.date} = ${today}`))
            .limit(1);

        return c.json({ vote: vote || null }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

// Cast or update a vote
drinkRoutes.post('/vote', async (c) => {
    try {
        const user = c.get('user');
        const { drinkId, date } = await c.req.json();
        const voteDate = date || new Date().toISOString().split('T')[0];

        if (!drinkId) {
            return c.json({ error: 'drinkId is required' }, 400);
        }

        const [savedVote] = await db.insert(drinkVotes)
            .values({
                userId: user.userId,
                date: voteDate,
                drinkId,
            })
            .onConflictDoUpdate({
                target: [drinkVotes.userId, drinkVotes.date],
                set: { drinkId, votedAt: new Date() }
            })
            .returning();

        return c.json({ vote: savedVote }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

// Get poll results for a specific date
drinkRoutes.get('/results', async (c) => {
    try {
        const dateStr = c.req.query('date') || new Date().toISOString().split('T')[0];

        // Count votes per drink for the given date
        const results = await db
            .select({
                drinkId: drinkVotes.drinkId,
                drinkName: hotDrinks.name,
                voteCount: sql<number>`count(${drinkVotes.id})`.mapWith(Number),
            })
            .from(drinkVotes)
            .innerJoin(hotDrinks, eq(drinkVotes.drinkId, hotDrinks.id))
            .where(sql`${drinkVotes.date} = ${dateStr}`)
            .groupBy(drinkVotes.drinkId, hotDrinks.name);

        return c.json({ date: dateStr, results }, 200);
    } catch (err: any) {
        return c.json({ error: err.message }, 500);
    }
});

export default drinkRoutes;
