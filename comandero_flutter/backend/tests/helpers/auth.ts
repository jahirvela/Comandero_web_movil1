import request from 'supertest';
import { app } from '../../src/server';

const defaultUsername = process.env.TEST_USERNAME ?? 'admin';
const defaultPassword = process.env.TEST_PASSWORD ?? 'Demo1234';

export const loginAsAdmin = async () => {
  const response = await request(app)
    .post('/api/auth/login')
    .send({ username: defaultUsername, password: defaultPassword });

  return response;
};

export const getAuthToken = async () => {
  const res = await loginAsAdmin();
  if (res.status !== 200) {
    throw new Error(
      `No se pudo autenticar. Revisa credenciales TEST_USERNAME/TEST_PASSWORD. Status: ${res.status}`
    );
  }
  return res.body.tokens.accessToken as string;
};

