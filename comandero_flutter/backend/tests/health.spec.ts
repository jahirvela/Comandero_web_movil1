import request from 'supertest';
import { app } from '../src/server';

describe('Health Check', () => {
  it('GET /api/health responde 200', async () => {
    const res = await request(app).get('/api/health');
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('status', 'ok');
  });
});

