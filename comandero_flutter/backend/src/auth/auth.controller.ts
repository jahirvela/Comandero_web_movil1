import type { Request, Response, NextFunction } from 'express';
import { login as loginService, refreshTokens, getProfile } from './auth.service.js';
import { loginSchema, refreshSchema } from './auth.schemas.js';

export const loginController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = loginSchema.parse(req.body);
    const result = await loginService(data);
    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
};

export const refreshController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = refreshSchema.parse(req.body);
    const result = await refreshTokens(data.refreshToken);
    return res.status(200).json(result);
  } catch (error) {
    return next(error);
  }
};

export const meController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ error: 'unauthorized', message: 'Token inválido' });
    }
    const profile = await getProfile(userId);
    return res.status(200).json(profile);
  } catch (error) {
    return next(error);
  }
};

