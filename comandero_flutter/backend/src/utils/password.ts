import bcrypt from 'bcrypt';
import { logger } from '../config/logger.js';

const SALT_ROUNDS = 12;

export const hashPassword = async (plainPassword: string) => {
  return bcrypt.hash(plainPassword, SALT_ROUNDS);
};

export const comparePassword = async (plainPassword: string, passwordHash: string) => {
  if (passwordHash.startsWith('$2')) {
    return bcrypt.compare(plainPassword, passwordHash);
  }

  // Fallback temporal para contraseñas sin hash (semillas existentes)
  const match = plainPassword === passwordHash;
  if (match) {
    logger.warn(
      {
        event: 'legacy_password_detected'
      },
      'Contraseña almacenada sin hash detectada. Considera migrar a hashes bcrypt.'
    );
  }
  return match;
};

