import pino from 'pino';
import { getEnv } from './env.js';

const env = getEnv();
const isDev = env.NODE_ENV !== 'production';

const usePretty = env.LOG_PRETTY ?? isDev;

const transport = usePretty
  ? {
      target: 'pino-pretty',
      options: {
        colorize: true,
        singleLine: true,
        translateTime: 'SYS:yyyy-mm-dd HH:MM:ss',
        ignore: 'pid,hostname'
      }
    }
  : undefined;

export const logger = pino({
  level: env.LOG_LEVEL,
  transport
});

