import { actualizarUltimoAcceso, findUserById, findUserByUsername } from './auth.repository.js';
import type { AuthResponse, UserWithRoles } from './auth.types.js';
import type { LoginInput } from './auth.schemas.js';
import { comparePassword } from '../utils/password.js';
import { signAccessToken, signRefreshToken, verifyRefreshToken } from '../utils/jwt.js';
import { HttpError, unauthorized, forbidden } from '../utils/http-error.js';

const ensureUserActive = (user: UserWithRoles) => {
  if (!user.activo) {
    throw forbidden('El usuario está deshabilitado');
  }
};

const buildAuthResponse = (user: UserWithRoles): AuthResponse => {
  const payload = {
    sub: user.id,
    username: user.username,
    roles: user.roles
  };

  const accessToken = signAccessToken(payload);
  const refreshToken = signRefreshToken(payload);

  return {
    user: {
      id: user.id,
      nombre: user.nombre,
      username: user.username,
      roles: user.roles
    },
    tokens: {
      accessToken,
      refreshToken
    }
  };
};

export const login = async (input: LoginInput): Promise<AuthResponse> => {
  const user = await findUserByUsername(input.username);

  if (!user) {
    throw unauthorized('Credenciales inválidas');
  }

  ensureUserActive(user);

  const isValidPassword = await comparePassword(input.password, user.passwordHash);

  if (!isValidPassword) {
    throw unauthorized('Credenciales inválidas');
  }

  await actualizarUltimoAcceso(user.id);

  return buildAuthResponse(user);
};

export const refreshTokens = async (refreshToken: string): Promise<AuthResponse> => {
  const { valid, decoded } = verifyRefreshToken(refreshToken);

  if (!valid || !decoded) {
    throw unauthorized('Token de refresco inválido');
  }

  const user = await findUserById(decoded.sub);

  if (!user) {
    throw unauthorized('Usuario no encontrado');
  }

  ensureUserActive(user);

  return buildAuthResponse(user);
};

export const getProfile = async (userId: number) => {
  const user = await findUserById(userId);

  if (!user) {
    throw new HttpError(404, 'Usuario no encontrado');
  }

  ensureUserActive(user);

  return {
    id: user.id,
    nombre: user.nombre,
    username: user.username,
    roles: user.roles,
    ultimoAcceso: user.ultimoAcceso
  };
};

