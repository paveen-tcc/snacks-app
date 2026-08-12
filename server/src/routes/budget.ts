import type { Context } from 'hono';
import { Hono } from 'hono';
import { authMiddleware, adminMiddleware } from '../middleware/auth';
import type { AuthContext } from '../middleware/auth';
import {
    BudgetNotFoundError,
    BudgetValidationError,
    createPurchaseItem,
    getBudgetDay,
    getBudgetRange,
    removePurchaseItem,
    updatePurchaseItem,
} from '../lib/budget';
import { getOrderWindow, officeDateString } from '../lib/orderWindow';

const budgetRoutes = new Hono<AuthContext>();

budgetRoutes.use('*', authMiddleware, adminMiddleware);

async function getOfficeToday(c: Context<AuthContext>) {
    const window = await getOrderWindow(c.get('db'));
    return officeDateString(window.offsetMinutes);
}

function errorResponse(c: Context<AuthContext>, error: unknown) {
    if (error instanceof BudgetValidationError) {
        return c.json({ error: error.message }, 400);
    }
    if (error instanceof BudgetNotFoundError) {
        return c.json({ error: error.message }, 404);
    }
    const message = error instanceof Error ? error.message : 'Unknown error';
    return c.json({ error: message }, 500);
}

// Keep the range route before the parameterized day route.
budgetRoutes.get('/', async (c) => {
    try {
        const start = c.req.query('start');
        const end = c.req.query('end');
        if (!start || !end) {
            throw new BudgetValidationError('start and end are required');
        }
        const result = await getBudgetRange(
            c.get('db'),
            start,
            end,
            await getOfficeToday(c),
        );
        return c.json(result, 200);
    } catch (error) {
        return errorResponse(c, error);
    }
});

budgetRoutes.get('/:date', async (c) => {
    try {
        const result = await getBudgetDay(
            c.get('db'),
            c.req.param('date'),
            await getOfficeToday(c),
        );
        return c.json(result, 200);
    } catch (error) {
        return errorResponse(c, error);
    }
});

budgetRoutes.post('/:date/items', async (c) => {
    try {
        const item = await createPurchaseItem(
            c.get('db'),
            c.req.param('date'),
            await c.req.json(),
            await getOfficeToday(c),
        );
        return c.json({ item }, 201);
    } catch (error) {
        return errorResponse(c, error);
    }
});

budgetRoutes.put('/:date/items/:id', async (c) => {
    try {
        const item = await updatePurchaseItem(
            c.get('db'),
            c.req.param('date'),
            c.req.param('id'),
            await c.req.json(),
            await getOfficeToday(c),
        );
        return c.json({ item }, 200);
    } catch (error) {
        return errorResponse(c, error);
    }
});

budgetRoutes.delete('/:date/items/:id', async (c) => {
    try {
        await removePurchaseItem(
            c.get('db'),
            c.req.param('date'),
            c.req.param('id'),
            await getOfficeToday(c),
        );
        return c.json({ success: true }, 200);
    } catch (error) {
        return errorResponse(c, error);
    }
});

export default budgetRoutes;
