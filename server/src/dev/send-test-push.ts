import { existsSync, readFileSync } from 'fs';
import { isFcmConfigured, sendPushToTokens } from '../lib/fcm';

// Dev utility: sends a test FCM push to the most recently registered device.
// Post-D1 it reads tokens through `wrangler d1 execute --remote` instead of a
// database connection string.

type DevEnv = { FCM_SERVICE_ACCOUNT?: string };

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
        if (key === 'FCM_SERVICE_ACCOUNT') env[key] = unquote(line.slice(separator + 1));
    }
    return env;
}

function argValue(name: string): string | undefined {
    const prefix = `--${name}=`;
    return process.argv.find((arg) => arg.startsWith(prefix))?.slice(prefix.length);
}

async function d1Query<T>(query: string): Promise<T[]> {
    const proc = await Bun.$`wrangler d1 execute snacks-db --remote --json --command ${query}`.quiet();
    const parsed = JSON.parse(proc.stdout.toString()) as Array<{ results?: T[] }>;
    return parsed[0]?.results ?? [];
}

const localEnv = loadDevVars();
const serviceAccount = process.env.FCM_SERVICE_ACCOUNT ?? localEnv.FCM_SERVICE_ACCOUNT;
const platform = argValue('platform') ?? 'ios';
const shouldList = process.argv.includes('--list');
const title = argValue('title') ?? 'TCC Pantry local test';
const body = argValue('body') ?? `Push test sent from local Worker dev tools at ${new Date().toLocaleTimeString()}`;

// platform is interpolated into SQL below — allowlist it.
if (!['ios', 'android', 'any'].includes(platform)) {
    throw new Error(`--platform must be ios, android, or any (got "${platform}")`);
}

type TokenRow = { token: string; platform: string | null; updated_at: number | null };

async function printTokenSummary() {
    const rows = await d1Query<{ platform: string | null; count: number; latest: number | null }>(
        'SELECT platform, count(*) AS count, max(updated_at) AS latest FROM push_tokens GROUP BY platform',
    );
    if (rows.length === 0) {
        console.log('Registered push tokens: none');
        return;
    }
    console.log('Registered push tokens by platform:');
    for (const row of rows) {
        const latest = row.latest == null ? 'unknown' : new Date(Number(row.latest)).toISOString();
        console.log(`- ${row.platform ?? 'unknown'}: ${row.count} latest=${latest}`);
    }
}

if (shouldList) {
    await printTokenSummary();
    process.exit(0);
}

if (!isFcmConfigured(serviceAccount)) {
    throw new Error('FCM_SERVICE_ACCOUNT is missing or invalid. Add the Firebase service-account JSON to server/.dev.vars.');
}

const where = platform === 'any' ? '' : `WHERE platform = '${platform}' `;
const [target] = await d1Query<TokenRow>(
    `SELECT token, platform, updated_at FROM push_tokens ${where}ORDER BY updated_at DESC LIMIT 1`,
);

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

const updatedLabel = target.updated_at == null ? 'unknown time' : new Date(Number(target.updated_at)).toISOString();
console.log(`Sent local test push to latest ${target.platform ?? platform} device token updated at ${updatedLabel}.`);
