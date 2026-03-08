import { SignJWT, jwtVerify } from 'jose';

export interface JWTPayload {
    userId: string;
    isAdmin: boolean;
}

export async function signToken(payload: JWTPayload, secret: string): Promise<string> {
    const key = new TextEncoder().encode(secret);
    return new SignJWT({ ...payload })
        .setProtectedHeader({ alg: 'HS256' })
        .setIssuedAt()
        .setExpirationTime('30d')
        .sign(key);
}

export async function verifyToken(token: string, secret: string): Promise<JWTPayload | null> {
    try {
        const key = new TextEncoder().encode(secret);
        const { payload } = await jwtVerify(token, key);
        return payload as unknown as JWTPayload;
    } catch (err) {
        return null;
    }
}
