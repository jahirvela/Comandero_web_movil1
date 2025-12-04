export interface UserWithRoles {
  id: number;
  nombre: string;
  username: string;
  passwordHash: string;
  activo: boolean;
  ultimoAcceso: Date | null;
  roles: string[];
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export interface AuthResponse {
  user: {
    id: number;
    nombre: string;
    username: string;
    roles: string[];
  };
  tokens: AuthTokens;
}

