import request from 'supertest';
import { randomUUID } from 'crypto';
import { app } from '../src/server';
import { getAuthToken } from './helpers/auth';

const shouldRunDbTests = process.env.RUN_DB_TESTS === 'true';
const describeDb = shouldRunDbTests ? describe : describe.skip;

describeDb('Órdenes API', () => {
  let token: string;

  beforeAll(async () => {
    token = await getAuthToken();
  });

  it('Crea una categoría, un producto y registra una orden', async () => {
    const categoriaNombre = `Categoria Test ${randomUUID().slice(0, 6)}`;
    const createCategoria = await request(app)
      .post('/api/categorias')
      .set('Authorization', `Bearer ${token}`)
      .send({
        nombre: categoriaNombre,
        descripcion: 'Categoría para pruebas'
      });
    expect(createCategoria.status).toBe(201);
    const categoriaId = createCategoria.body.data.id as number;

    const productoNombre = `Producto Test ${randomUUID().slice(0, 6)}`;
    const createProducto = await request(app)
      .post('/api/productos')
      .set('Authorization', `Bearer ${token}`)
      .send({
        categoriaId,
        nombre: productoNombre,
        precio: 120.5,
        disponible: true
      });
    expect(createProducto.status).toBe(201);
    const productoId = createProducto.body.data.id as number;

    const createOrden = await request(app)
      .post('/api/ordenes')
      .set('Authorization', `Bearer ${token}`)
      .send({
        mesaId: null,
        clienteNombre: 'Cliente Test',
        items: [
          {
            productoId,
            cantidad: 2,
            precioUnitario: 120.5
          }
        ]
      });

    expect(createOrden.status).toBe(201);
    expect(createOrden.body.data).toHaveProperty('id');
    expect(createOrden.body.data.items.length).toBeGreaterThan(0);
  });
});

