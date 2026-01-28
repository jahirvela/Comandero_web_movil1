import { z } from 'zod';

const productoTamanoSchema = z.object({
  nombre: z.string().min(1, 'El nombre del tamaño es obligatorio'),
  precio: z.coerce.number().positive('El precio debe ser mayor a 0')
});

const productoIngredienteSchema = z.object({
  inventarioItemId: z.number().int().positive().optional().nullable(),
  categoria: z.string().min(2).max(64).optional().nullable(),
  nombre: z.string().min(1),
  unidad: z.string().min(1).max(32),
  cantidadPorPorcion: z.coerce.number().positive(),
  descontarAutomaticamente: z.boolean().optional().default(true),
  esPersonalizado: z.boolean().optional().default(false),
  esOpcional: z.boolean().optional().default(false),
  tamanoId: z.number().int().positive().optional().nullable()
});

export const crearProductoSchema = z
  .object({
    categoriaId: z.number().int().positive(),
    nombre: z.string().min(2),
    descripcion: z.string().optional().nullable(),
    precio: z.coerce.number().positive().optional(),
    tamanos: z.array(productoTamanoSchema).optional(),
    ingredientes: z.array(productoIngredienteSchema).optional(),
    disponible: z.boolean().optional().default(true),
    sku: z.string().max(64).optional().nullable(),
    inventariable: z.boolean().optional().default(false)
  })
  .refine(
    (value) => {
      const hasTamanos = value.tamanos !== undefined && value.tamanos.length > 0;
      return hasTamanos || value.precio !== undefined;
    },
    { message: 'Debe proporcionar un precio o al menos un tamaño' }
  );

export const actualizarProductoSchema = z
  .object({
    categoriaId: z.number().int().positive().optional(),
    nombre: z.string().min(2).optional(),
    descripcion: z.string().optional().nullable(),
    precio: z.coerce.number().positive().optional(),
    tamanos: z.array(productoTamanoSchema).optional(),
    ingredientes: z.array(productoIngredienteSchema).optional(),
    disponible: z.boolean().optional(),
    sku: z.string().max(64).optional().nullable(),
    inventariable: z.boolean().optional()
  })
  .refine(
    (value) =>
      value.categoriaId !== undefined ||
      value.nombre !== undefined ||
      value.descripcion !== undefined ||
      value.precio !== undefined ||
      value.tamanos !== undefined ||
      value.disponible !== undefined ||
      value.sku !== undefined ||
      value.inventariable !== undefined,
    { message: 'Debe proporcionar al menos un campo para actualizar' }
  );

export type ProductoTamanoInput = z.infer<typeof productoTamanoSchema>;
export type ProductoIngredienteInput = z.infer<typeof productoIngredienteSchema>;
export type CrearProductoInput = z.infer<typeof crearProductoSchema>;
export type ActualizarProductoInput = z.infer<typeof actualizarProductoSchema>;

