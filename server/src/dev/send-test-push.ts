import { existsSync, readFileSync } from 'fs';
import { desc, eq, sql } from 'drizzle-orm';
import { createDb } from '../db';
import { pushTokens } from '../db/schema';
import { isFcmConfigured, sendPushToTokens } from '../lib/fcm';

type DevEnv = {
    DATABASE_URL?: string;
    FCM_SERVICE_ACCOUNT?: string;
};

function unquote(value: string): string {
    const trimmed = value.trim();
    if (
        (trimmed.startsWith('"') && trimmed.endsWith('"')) ||
        (trimmed.startsWith("'") && trimmed.endsWith("'"))
    ) {
        return trimmed.slice(1, -1);
    }
    return trimmed;
}

function loadDevVars(): DevEnv {
    const file = '.dev.vars';
    if (!existsSync(file)) return {};

    const env: DevEnv = {};
    for (const rawLine of readFileSync(file, 'utf8').split(String.fromCharCode(10))) {
        const line = rawLine.trim();
        if (!line || line.startsWith('#')) continue;

        const separator = line.indexOf('=');
        if (separator === -1) continue;

        const key = line.slice(0, separator).trim();
        const value = unquote(line.slice(separator + 1));
        if (key === 'DATABASE_URL' || key === 'FCM_SERVICE_ACCOUNT') {
            env[key] = value;
        }
    }
    return env;
}

function argValue(name: string): string | undefined {
    const prefix = `--${name}=`;
    return process.argv.find((arg) => arg.startsWith(prefix))?.slice(prefix.length);
}

const localEnv = loadDevVars();
const databaseUrl = process.env.DATABASE_URL ?? localEnv.DATABASE_URL;
const serviceAccount = process.env.FCM_SERVICE_ACCOUNT ?? localEnv.FCM_SERVICE_ACCOUNT;
const platform = argValue('platform') ?? 'ios';
const shouldList = process.argv.includes('--list');
const title = argValue('title') ?? 'TCC Pantry local test';
const body = argValue('body') ?? `Push test sent from local Worker dev tools at ${new Date().toLocaleTimeString()}`;

if (!databaseUrl) {
    throw new Error('DATABASE_URL is missing. Add it to server/.dev.vars.');
}

const db = createDb(databaseUrl);

async function printTokenSummary() {
    const rows = await db
        .select({
            platform: pushTokens.platform,
            count: sql<string>`count(*)`,
            latest: sql<string>`max(${pushTokens.updatedAt})`,
        })
        .from(pushTokens)
        .groupBy(pushTokens.platform);

    if (rows.length === 0) {
        console.log('Registered push tokens: none');
        return;
    }

    console.log('Registered push tokens by platform:');
    for (const row of rows) {
        console.log(`- ${row.platform ?? 'unknown'}: ${row.count} latest=${row.latest ?? 'unknown'}`);
    }
}

if (shouldList) {
    await printTokenSummary();
    process.exit(0);
}

if (!isFcmConfigured(serviceAccount)) {
    throw new Error('FCM_SERVICE_ACCOUNT is missing or invalid. Add the Firebase service-account JSON to server/.dev.vars.');
}

const targetRows = platform === 'any'
    ? await db
        .select({ token: pushTokens.token, platform: pushTokens.platform, updatedAt: pushTokens.updatedAt })
        .from(pushTokens)
        .orderBy(desc(pushTokens.updatedAt))
        .limit(1)
    : await db
        .select({ token: pushTokens.token, platform: pushTokens.platform, updatedAt: pushTokens.updatedAt })
        .from(pushTokens)
        .where(eq(pushTokens.platform, platform))
        .orderBy(desc(pushTokens.updatedAt))
        .limit(1);
const [target] = targetRows;

if (!target) {
    await printTokenSummary();
    throw new Error(`No registered ${platform} push token found. Run the app, sign in, and allow notifications first.`);
}

const [result] = await sendPushToTokens(serviceAccount, [target.token], { title, body }, 1);
if (!result?.ok) {
    const error = result?.error ?? 'no response';
    if (error.includes('THIRD_PARTY_AUTH_ERROR')) {
        throw new Error(
            'FCM could not authenticate with APNs for this iOS app. Upload or fix the APNs auth key/certificate in Firebase Console > Project settings > Cloud Messaging for bundle id company.thecloud.pantry. Original FCM response: ' +
                error,
        );
    }
    throw new Error(`FCM send failed with status ${result?.status ?? 'unknown'}: ${error}`);
}

console.log(`Sent local test push to latest ${target.platform ?? platform} device token updated at ${target.updatedAt?.toISOString() ?? 'unknown time'}.`);
