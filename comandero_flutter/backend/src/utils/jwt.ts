import jwt from 'jsonwebtoken';
import { getEnv } from '../config/env.js';

const env = getEnv();

export interface TokenUserPayload {
  sub: number;
  username: string;
  roles: string[];
}

export interface VerifyResult<T> {
  valid: boolean;
  decoded?: T;
  error?: Error;
}

export const signAccessToken = (payload: TokenUserPayload) => {
  return jwt.sign(payload, env.JWT_ACCESS_SECRET, {
    expiresIn: env.JWT_ACCESS_EXPIRES_IN
  } as jwt.SignOptions);
};

export const signRefreshToken = (payload: TokenUserPayload) => {
  return jwt.sign(payload, env.JWT_REFRESH_SECRET, {
    expiresIn: env.JWT_REFRESH_EXPIRES_IN
  } as jwt.SignOptions);
};

export const verifyAccessToken = (token: string): VerifyResult<TokenUserPayload> => {
  try {
    const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET) as unknown as TokenUserPayload;
    return { valid: true, decoded };
  } catch (error) {
    return { valid: false, error: error as Error };
  }
};

export const verifyRefreshToken = (token: string): VerifyResult<TokenUserPayload> => {
  try {
    const decoded = jwt.verify(token, env.JWT_REFRESH_SECRET) as unknown as TokenUserPayload;
    return { valid: true, decoded };
  } catch (error) {
    return { valid: false, error: error as Error };
  }
};

