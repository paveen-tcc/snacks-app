import { createRemoteJWKSet, jwtVerify, decodeJwt, decodeProtectedHeader } from 'jose';

export interface MicrosoftClaims {
    oid: string;
    email: string;
    name: string;
}

export async function verifyMicrosoftToken(
    token: string,
    tenantId: string,
    clientId: string,
): Promise<MicrosoftClaims> {
    // Decode the header to check nonce (access tokens have it, ID tokens don't)
    const header = decodeProtectedHeader(token);
    const decoded = decodeJwt(token);

    console.log('Token header kid:', header.kid, 'nonce:', header.nonce ? 'present' : 'absent');
    console.log('Token aud:', decoded.aud, 'iss:', decoded.iss);

    // Determine JWKS URL based on issuer version
    const issuer = decoded.iss as string;
    let jwksUrl: string;
    if (issuer?.includes('/v2.0')) {
        jwksUrl = `https://login.microsoftonline.com/${tenantId}/discovery/v2.0/keys`;
    } else {
        jwksUrl = `https://login.microsoftonline.com/${tenantId}/discovery/keys`;
    }

    console.log('Using JWKS URL:', jwksUrl);

    const jwks = createRemoteJWKSet(new URL(jwksUrl));

    // For access tokens (audience is Graph API), skip audience validation
    const isIdToken = decoded.aud === clientId;

    const { payload } = await jwtVerify(token, jwks, {
        issuer: isIdToken ? `https://login.microsoftonline.com/${tenantId}/v2.0` : undefined,
        audience: isIdToken ? clientId : undefined,
    });

    const oid = (payload.oid ?? payload.sub) as string;
    const email = (payload.email ?? payload.preferred_username ?? payload.upn) as string;
    const name = (payload.name ?? email?.split('@')[0]) as string;

    if (!oid || !email) {
        throw new Error(`Missing required claims. oid=${oid}, email=${email}, aud=${decoded.aud}`);
    }

    return { oid, email, name };
}
