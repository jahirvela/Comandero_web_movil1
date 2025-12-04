import { pool } from '../src/db/pool';

afterAll(async () => {
  await pool.end();
});

