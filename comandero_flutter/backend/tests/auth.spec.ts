import request from 'supertest';
import { app } from '../src/server';

const shouldRunDbTests = process.env.RUN_DB_TESTS === 'true';
const describeDb = shouldRunDbTests ? describe : describe.skip;

describeDb('Auth API', () => {
  it('POST /api/auth/login devuelve tokens para credenciales válidas', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        username: process.env.TEST_USERNAME ?? 'admin',
        password: process.env.TEST_PASSWORD ?? 'Demo1234'
      });

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('tokens.accessToken');
    expect(res.body).toHaveProperty('user.username');
  });

  it('POST /api/auth/login devuelve 401 para credenciales inválidas', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        username: 'usuario_inexistente',
        password: 'clave_incorrecta'
      });

    expect(res.status).toBe(401);
  });
});

