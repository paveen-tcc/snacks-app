import { SignJWT, importPKCS8 } from 'jose';

// Minimal FCM HTTP v1 client for Cloudflare Workers. Authenticates with a
// Firebase service account: sign a short-lived JWT (RS256) with the account's
// private key, exchange it for an OAuth2 access token, then POST to
// projects/{id}/messages:send. The whole flow runs on Web Crypto via `jose`,
// so no Node/Admin SDK is needed.

type ServiceAccount = {
    project_id: string;
    client_email: string;
    private_key: string;
};

// Access tokens last ~1h; cache within the isolate to avoid re-signing on
// every cron tick. Scoped to module so it survives across invocations that
// reuse the isolate.
let cachedToken: { value: string; expiresAt: number } | null = null;

function parseServiceAccount(raw: string | undefined): ServiceAccount | null {
    if (!raw) return null;
    try {
        const parsed = JSON.parse(raw);
        if (
            typeof parsed?.project_id === 'string' &&
            typeof parsed?.client_email === 'string' &&
            typeof parsed?.private_key === 'string'
        ) {
            return parsed as ServiceAccount;
        }
    } catch {
        /* fall through */
    }
    return null;
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
    const now = Date.now();
    if (cachedToken && cachedToken.expiresAt > now + 60_000) {
        return cachedToken.value;
    }

    const key = await importPKCS8(sa.private_key, 'RS256');
    const assertion = await new SignJWT({
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
    })
        .setProtectedHeader({ alg: 'RS256' })
        .setIssuer(sa.client_email)
        .setSubject(sa.client_email)
        .setAudience('https://oauth2.googleapis.com/token')
        .setIssuedAt()
        .setExpirationTime('1h')
        .sign(key);

    const res = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
            grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            assertion,
        }),
    });

    if (!res.ok) {
        throw new Error(`FCM token exchange failed: ${res.status} ${await res.text()}`);
    }

    const data = (await res.json()) as { access_token: string; expires_in: number };
    cachedToken = {
        value: data.access_token,
        expiresAt: now + data.expires_in * 1000,
    };
    return data.access_token;
}

export type FcmResult = { token: string; ok: boolean; status: number; error?: string };

export function isFcmConfigured(serviceAccountJson: string | undefined): boolean {
    return parseServiceAccount(serviceAccountJson) !== null;
}

async function sendOne(
    endpoint: string,
    accessToken: string,
    token: string,
    notification: { title: string; body: string },
): Promise<FcmResult> {
    try {
        const res = await fetch(endpoint, {
            method: 'POST',
            headers: {
                Authorization: `Bearer ${accessToken}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                message: {
                    token,
                    notification: { title: notification.title, body: notification.body },
                    // No explicit channel — the FCM Android SDK delivers on its
                    // auto-created fallback channel, so notifications show even
                    // without app-side channel setup.
                    android: { priority: 'high' },
                },
            }),
        });
        return {
            token,
            ok: res.ok,
            status: res.status,
            error: res.ok ? undefined : await res.text(),
        };
    } catch (err: any) {
        return { token, ok: false, status: 0, error: err?.message ?? 'send failed' };
    }
}

// Sends a notification to each token, capped concurrency to stay well under the
// Workers subrequest limit. Returns per-token results so callers can prune
// tokens FCM reports as stale (404 NOT_FOUND / 400 INVALID_ARGUMENT).
export async function sendPushToTokens(
    serviceAccountJson: string | undefined,
    tokens: string[],
    notification: { title: string; body: string },
    concurrency = 20,
): Promise<FcmResult[]> {
    const sa = parseServiceAccount(serviceAccountJson);
    if (!sa) {
        throw new Error('FCM_SERVICE_ACCOUNT is not configured');
    }
    if (tokens.length === 0) return [];

    const accessToken = await getAccessToken(sa);
    const endpoint = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

    const results: FcmResult[] = [];
    for (let i = 0; i < tokens.length; i += concurrency) {
        const batch = tokens.slice(i, i + concurrency);
        const batchResults = await Promise.all(
            batch.map((token) => sendOne(endpoint, accessToken, token, notification)),
        );
        results.push(...batchResults);
    }
    return results;
}
