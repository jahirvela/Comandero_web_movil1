export interface AuthenticatedUser {
  id: number;
  username: string;
  nombre?: string;
  roles: string[];
  rol?: string;
}

