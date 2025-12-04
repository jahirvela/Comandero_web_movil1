import request from 'supertest';
import { randomUUID } from 'crypto';
import { app } from '../src/server';
import { getAuthToken } from './helpers/auth';

const shouldRunDbTests = process.env.RUN_DB_TESTS === 'true';
const describeDb = shouldRunDbTests ? describe : describe.skip;

describeDb('Usuarios API', () => {
  let token: string;

  beforeAll(async () => {
    token = await getAuthToken();
  });

  it('POST /api/usuarios crea un usuario y GET /api/usuarios lo lista', async () => {
    const username = `testuser_${randomUUID().slice(0, 8)}`;

    const createRes = await request(app)
      .post('/api/usuarios')
      .set('Authorization', `Bearer ${token}`)
      .send({
        nombre: 'Usuario de Prueba',
        username,
        password: 'Prueba1234',
        activo: true,
        roles: []
      });

    expect(createRes.status).toBe(201);
    const userId = createRes.body.data.id as number;

    const listRes = await request(app)
      .get('/api/usuarios')
      .set('Authorization', `Bearer ${token}`);

    expect(listRes.status).toBe(200);
    const exists = listRes.body.data.some((user: { id: number }) => user.id === userId);
    expect(exists).toBe(true);
  });
});

