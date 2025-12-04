import { Router } from 'express';
import { loginController, meController, refreshController } from './auth.controller.js';
import { authenticate } from '../middlewares/authentication.js';
import { loginRateLimiter } from '../config/rate-limit.js';

const authRouter = Router();

// Aplicar rate limiting más restrictivo solo al login
authRouter.post('/login', loginRateLimiter, loginController);
authRouter.post('/refresh', refreshController);
authRouter.get('/me', authenticate, meController);

export default authRouter;

