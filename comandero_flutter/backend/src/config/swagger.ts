import { getEnv } from './env.js';

const env = getEnv();

export const swaggerDocument = {
  openapi: '3.0.0',
  info: {
    title: 'Comandix API',
    version: '0.1.0',
    description:
      'API REST para Comandix (Comandero Web/Móvil). Incluye autenticación, gestión de mesas, órdenes, inventario y pagos.'
  },
  servers: [
    ...(env.API_BASE_URL
      ? [
          {
            url: `${env.API_BASE_URL}/api`,
            description: 'Servidor de producción'
          }
        ]
      : []),
    {
      url: `http://localhost:${env.PORT}/api`,
      description: env.NODE_ENV === 'production' ? 'Servidor local (desarrollo)' : 'Servidor local'
    }
  ],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT'
      }
    }
  },
  security: [{ bearerAuth: [] }],
  tags: [
    { name: 'Health', description: 'Verificación del estado del servidor' },
    { name: 'Auth', description: 'Autenticación de usuarios' },
    { name: 'Usuarios', description: 'Gestión de usuarios y roles' },
    { name: 'Roles', description: 'Catálogo de roles y permisos' },
    { name: 'Mesas', description: 'Administración de mesas y estado' },
    { name: 'Categorías', description: 'Catálogo de categorías' },
    { name: 'Productos', description: 'Catálogo de productos' },
    {
      name: 'Inventario',
      description: 'Insumos y movimientos de inventario'
    },
    { name: 'Órdenes', description: 'Gestión de órdenes y sus items' },
    { name: 'Pagos', description: 'Pagos, formas de pago y propinas' }
  ],
  paths: {
    '/health': {
      get: {
        tags: ['Health'],
        summary: 'Health check del servidor',
        description: 'Verifica que el servidor esté funcionando correctamente',
        security: [],
        responses: {
          '200': {
            description: 'Servidor funcionando correctamente',
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    status: { type: 'string', example: 'ok' },
                    timestamp: { type: 'string', format: 'date-time' }
                  }
                }
              }
            }
          }
        }
      }
    },
    '/auth/login': {
      post: {
        tags: ['Auth'],
        summary: 'Iniciar sesión',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  username: { type: 'string' },
                  password: { type: 'string' }
                },
                required: ['username', 'password']
              }
            }
          }
        },
        responses: {
          '200': { description: 'Tokens JWT y perfil del usuario' },
          '401': { description: 'Credenciales inválidas' }
        }
      }
    },
    '/auth/me': {
      get: {
        tags: ['Auth'],
        summary: 'Perfil del usuario autenticado',
        responses: {
          '200': { description: 'Datos del usuario' },
          '401': { description: 'Token inválido' }
        }
      }
    },
    '/usuarios': {
      get: {
        tags: ['Usuarios'],
        summary: 'Listado de usuarios',
        security: [{ bearerAuth: [] }],
        responses: {
          '200': { description: 'Lista de usuarios' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      post: {
        tags: ['Usuarios'],
        summary: 'Crear un nuevo usuario',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  nombre: { type: 'string', example: 'Juan Pérez' },
                  username: { type: 'string', example: 'juan123' },
                  password: { type: 'string', format: 'password', example: 'Password123' },
                  telefono: { type: 'string', nullable: true, example: '555-1234' },
                  activo: { type: 'boolean', default: true },
                  roles: {
                    type: 'array',
                    items: { type: 'integer', example: 4 },
                    description: 'IDs de roles a asignar',
                    example: [4]
                  }
                },
                required: ['nombre', 'username', 'password']
              }
            }
          }
        },
        responses: {
          '201': { description: 'Usuario creado exitosamente' },
          '400': { description: 'Datos inválidos' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/usuarios/{id}': {
      get: {
        tags: ['Usuarios'],
        summary: 'Detalle de usuario',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID del usuario'
          }
        ],
        responses: {
          '200': { description: 'Datos del usuario' },
          '404': { description: 'Usuario no encontrado' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      put: {
        tags: ['Usuarios'],
        summary: 'Actualizar usuario',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID del usuario'
          }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  nombre: { type: 'string', example: 'Juan Pérez' },
                  telefono: { type: 'string', nullable: true, example: '555-1234' },
                  activo: { type: 'boolean' },
                  password: { type: 'string', format: 'password', example: 'NewPassword123' },
                  roles: {
                    type: 'array',
                    items: { type: 'integer' },
                    example: [4]
                  }
                }
              }
            }
          }
        },
        responses: {
          '200': { description: 'Usuario actualizado' },
          '400': { description: 'Datos inválidos' },
          '404': { description: 'Usuario no encontrado' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      delete: {
        tags: ['Usuarios'],
        summary: 'Desactivar usuario',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID del usuario'
          }
        ],
        responses: {
          '204': { description: 'Usuario desactivado' },
          '404': { description: 'Usuario no encontrado' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/usuarios/{id}/roles': {
      post: {
        tags: ['Usuarios'],
        summary: 'Asignar roles a un usuario',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID del usuario'
          }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  roles: {
                    type: 'array',
                    items: { type: 'integer' },
                    example: [4, 5],
                    description: 'IDs de roles a asignar'
                  }
                },
                required: ['roles']
              }
            }
          }
        },
        responses: {
          '200': { description: 'Roles asignados correctamente' },
          '400': { description: 'Datos inválidos' },
          '404': { description: 'Usuario no encontrado' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/roles': {
      get: {
        tags: ['Roles'],
        summary: 'Listado de roles',
        security: [{ bearerAuth: [] }],
        responses: {
          '200': { description: 'Lista de roles' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      post: {
        tags: ['Roles'],
        summary: 'Crear rol',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  nombre: { type: 'string', example: 'supervisor' },
                  descripcion: { type: 'string', nullable: true, example: 'Supervisa operaciones' },
                  permisos: {
                    type: 'array',
                    items: { type: 'integer' },
                    example: [1, 2],
                    description: 'IDs de permisos a asignar'
                  }
                },
                required: ['nombre']
              }
            }
          }
        },
        responses: {
          '201': { description: 'Rol creado exitosamente' },
          '400': { description: 'Datos inválidos' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/roles/{id}': {
      get: {
        tags: ['Roles'],
        summary: 'Detalle de rol',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID del rol'
          }
        ],
        responses: {
          '200': { description: 'Datos del rol' },
          '404': { description: 'Rol no encontrado' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      put: {
        tags: ['Roles'],
        summary: 'Actualizar rol',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID del rol'
          }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  nombre: { type: 'string', example: 'supervisor' },
                  descripcion: { type: 'string', nullable: true },
                  permisos: {
                    type: 'array',
                    items: { type: 'integer' },
                    example: [1, 2]
                  }
                }
              }
            }
          }
        },
        responses: {
          '200': { description: 'Rol actualizado' },
          '400': { description: 'Datos inválidos' },
          '404': { description: 'Rol no encontrado' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      delete: {
        tags: ['Roles'],
        summary: 'Eliminar rol',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID del rol'
          }
        ],
        responses: {
          '204': { description: 'Rol eliminado' },
          '404': { description: 'Rol no encontrado' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/roles/permisos': {
      get: {
        tags: ['Roles'],
        summary: 'Listado de permisos disponibles',
        security: [{ bearerAuth: [] }],
        responses: {
          '200': { description: 'Lista de permisos' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/mesas': {
      get: {
        tags: ['Mesas'],
        summary: 'Listado de mesas',
        security: [{ bearerAuth: [] }],
        responses: {
          '200': { description: 'Lista de mesas' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      post: {
        tags: ['Mesas'],
        summary: 'Crear mesa',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  codigo: { type: 'string', example: 'MESA-01' },
                  nombre: { type: 'string', nullable: true, example: 'Mesa Principal' },
                  capacidad: { type: 'integer', nullable: true, example: 4 },
                  ubicacion: { type: 'string', nullable: true, example: 'Terraza' },
                  estadoMesaId: { type: 'integer', nullable: true, example: 1 },
                  activo: { type: 'boolean', default: true }
                },
                required: ['codigo']
              }
            }
          }
        },
        responses: {
          '201': { description: 'Mesa creada exitosamente' },
          '400': { description: 'Datos inválidos' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/mesas/{id}': {
      get: {
        tags: ['Mesas'],
        summary: 'Detalle de mesa',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID de la mesa'
          }
        ],
        responses: {
          '200': { description: 'Datos de la mesa' },
          '404': { description: 'Mesa no encontrada' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      put: {
        tags: ['Mesas'],
        summary: 'Actualizar mesa',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID de la mesa'
          }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  codigo: { type: 'string', example: 'MESA-01' },
                  nombre: { type: 'string', nullable: true },
                  capacidad: { type: 'integer', nullable: true },
                  ubicacion: { type: 'string', nullable: true },
                  estadoMesaId: { type: 'integer', nullable: true },
                  activo: { type: 'boolean' }
                }
              }
            }
          }
        },
        responses: {
          '200': { description: 'Mesa actualizada' },
          '400': { description: 'Datos inválidos' },
          '404': { description: 'Mesa no encontrada' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      delete: {
        tags: ['Mesas'],
        summary: 'Desactivar mesa',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID de la mesa'
          }
        ],
        responses: {
          '204': { description: 'Mesa desactivada' },
          '404': { description: 'Mesa no encontrada' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/mesas/{id}/estado': {
      patch: {
        tags: ['Mesas'],
        summary: 'Cambiar estado de una mesa',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID de la mesa'
          }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  estadoMesaId: { type: 'integer', example: 2 },
                  nota: { type: 'string', nullable: true, example: 'Mesa ocupada' }
                },
                required: ['estadoMesaId']
              }
            }
          }
        },
        responses: {
          '200': { description: 'Estado actualizado' },
          '400': { description: 'Datos inválidos' },
          '404': { description: 'Mesa no encontrada' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/mesas/{id}/historial': {
      get: {
        tags: ['Mesas'],
        summary: 'Historial de cambios de estado',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID de la mesa'
          }
        ],
        responses: {
          '200': { description: 'Historial de cambios' },
          '404': { description: 'Mesa no encontrada' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/categorias': {
      get: {
        tags: ['Categorías'],
        summary: 'Listado de categorías',
        security: [{ bearerAuth: [] }],
        responses: {
          '200': { description: 'Lista de categorías' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      post: {
        tags: ['Categorías'],
        summary: 'Crear categoría',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  nombre: { type: 'string', example: 'Bebidas' },
                  descripcion: { type: 'string', nullable: true, example: 'Bebidas frías y calientes' },
                  activo: { type: 'boolean', default: true }
                },
                required: ['nombre']
              }
            }
          }
        },
        responses: {
          '201': { description: 'Categoría creada exitosamente' },
          '400': { description: 'Datos inválidos' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/categorias/{id}': {
      get: {
        tags: ['Categorías'],
        summary: 'Detalle de categoría',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID de la categoría'
          }
        ],
        responses: {
          '200': { description: 'Datos de la categoría' },
          '404': { description: 'Categoría no encontrada' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      put: {
        tags: ['Categorías'],
        summary: 'Actualizar categoría',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID de la categoría'
          }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  nombre: { type: 'string', example: 'Bebidas' },
                  descripcion: { type: 'string', nullable: true },
                  activo: { type: 'boolean' }
                }
              }
            }
          }
        },
        responses: {
          '200': { description: 'Categoría actualizada' },
          '400': { description: 'Datos inválidos' },
          '404': { description: 'Categoría no encontrada' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      delete: {
        tags: ['Categorías'],
        summary: 'Desactivar categoría',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID de la categoría'
          }
        ],
        responses: {
          '204': { description: 'Categoría desactivada' },
          '404': { description: 'Categoría no encontrada' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/productos': {
      get: {
        tags: ['Productos'],
        summary: 'Listado de productos',
        security: [{ bearerAuth: [] }],
        responses: {
          '200': { description: 'Lista de productos' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      post: {
        tags: ['Productos'],
        summary: 'Crear producto',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  categoriaId: { type: 'integer', example: 1 },
                  nombre: { type: 'string', example: 'Coca Cola' },
                  descripcion: { type: 'string', nullable: true, example: 'Refresco de cola' },
                  precio: { type: 'number', example: 25.50 },
                  disponible: { type: 'boolean', default: true },
                  sku: { type: 'string', nullable: true, example: 'SKU-001' },
                  inventariable: { type: 'boolean', default: false }
                },
                required: ['categoriaId', 'nombre', 'precio']
              }
            }
          }
        },
        responses: {
          '201': { description: 'Producto creado exitosamente' },
          '400': { description: 'Datos inválidos' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/productos/{id}': {
      get: {
        tags: ['Productos'],
        summary: 'Detalle de producto',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID del producto'
          }
        ],
        responses: {
          '200': { description: 'Datos del producto' },
          '404': { description: 'Producto no encontrado' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      put: {
        tags: ['Productos'],
        summary: 'Actualizar producto',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID del producto'
          }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  categoriaId: { type: 'integer' },
                  nombre: { type: 'string' },
                  descripcion: { type: 'string', nullable: true },
                  precio: { type: 'number' },
                  disponible: { type: 'boolean' },
                  sku: { type: 'string', nullable: true },
                  inventariable: { type: 'boolean' }
                }
              }
            }
          }
        },
        responses: {
          '200': { description: 'Producto actualizado' },
          '400': { description: 'Datos inválidos' },
          '404': { description: 'Producto no encontrado' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      delete: {
        tags: ['Productos'],
        summary: 'Desactivar producto',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID del producto'
          }
        ],
        responses: {
          '204': { description: 'Producto desactivado' },
          '404': { description: 'Producto no encontrado' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/inventario/items': {
      get: {
        tags: ['Inventario'],
        summary: 'Listado de insumos',
        security: [{ bearerAuth: [] }],
        responses: {
          '200': { description: 'Lista de insumos' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      post: {
        tags: ['Inventario'],
        summary: 'Crear insumo',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  nombre: { type: 'string', example: 'Harina' },
                  unidad: { type: 'string', example: 'kg' },
                  cantidadActual: { type: 'number', default: 0, example: 10.5 },
                  stockMinimo: { type: 'number', default: 0, example: 5 },
                  costoUnitario: { type: 'number', nullable: true, example: 15.50 },
                  activo: { type: 'boolean', default: true }
                },
                required: ['nombre', 'unidad']
              }
            }
          }
        },
        responses: {
          '201': { description: 'Insumo creado exitosamente' },
          '400': { description: 'Datos inválidos' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/inventario/items/{id}': {
      get: {
        tags: ['Inventario'],
        summary: 'Detalle de insumo',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID del insumo'
          }
        ],
        responses: {
          '200': { description: 'Datos del insumo' },
          '404': { description: 'Insumo no encontrado' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      put: {
        tags: ['Inventario'],
        summary: 'Actualizar insumo',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID del insumo'
          }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  nombre: { type: 'string' },
                  unidad: { type: 'string' },
                  cantidadActual: { type: 'number' },
                  stockMinimo: { type: 'number' },
                  costoUnitario: { type: 'number', nullable: true },
                  activo: { type: 'boolean' }
                }
              }
            }
          }
        },
        responses: {
          '200': { description: 'Insumo actualizado' },
          '400': { description: 'Datos inválidos' },
          '404': { description: 'Insumo no encontrado' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      delete: {
        tags: ['Inventario'],
        summary: 'Desactivar insumo',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID del insumo'
          }
        ],
        responses: {
          '204': { description: 'Insumo desactivado' },
          '404': { description: 'Insumo no encontrado' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/inventario/movimientos': {
      get: {
        tags: ['Inventario'],
        summary: 'Historial de movimientos',
        security: [{ bearerAuth: [] }],
        responses: {
          '200': { description: 'Lista de movimientos' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      post: {
        tags: ['Inventario'],
        summary: 'Registrar movimiento',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  inventarioItemId: { type: 'integer', example: 1 },
                  tipo: {
                    type: 'string',
                    enum: ['entrada', 'salida', 'ajuste'],
                    example: 'entrada'
                  },
                  cantidad: { type: 'number', example: 5.0 },
                  costoUnitario: { type: 'number', nullable: true, example: 15.50 },
                  motivo: { type: 'string', nullable: true, example: 'Compra' },
                  origen: {
                    type: 'string',
                    enum: ['compra', 'consumo', 'ajuste', 'devolucion'],
                    nullable: true,
                    example: 'compra'
                  },
                  referenciaOrdenId: { type: 'integer', nullable: true }
                },
                required: ['inventarioItemId', 'tipo', 'cantidad']
              }
            }
          }
        },
        responses: {
          '201': { description: 'Movimiento registrado exitosamente' },
          '400': { description: 'Datos inválidos' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/ordenes': {
      get: {
        tags: ['Órdenes'],
        summary: 'Listado de órdenes',
        security: [{ bearerAuth: [] }],
        responses: {
          '200': { description: 'Lista de órdenes' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      post: {
        tags: ['Órdenes'],
        summary: 'Crear orden',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  mesaId: { type: 'integer', nullable: true, example: 1 },
                  reservaId: { type: 'integer', nullable: true },
                  clienteId: { type: 'integer', nullable: true },
                  clienteNombre: { type: 'string', nullable: true, example: 'Juan Pérez' },
                  subtotal: { type: 'number', example: 150.00 },
                  descuentoTotal: { type: 'number', default: 0 },
                  impuestoTotal: { type: 'number', default: 0 },
                  propinaSugerida: { type: 'number', nullable: true },
                  estadoOrdenId: { type: 'integer' },
                  items: {
                    type: 'array',
                    items: {
                      type: 'object',
                      properties: {
                        productoId: { type: 'integer', example: 1 },
                        productoTamanoId: { type: 'integer', nullable: true },
                        cantidad: { type: 'number', example: 2 },
                        precioUnitario: { type: 'number', example: 75.00 },
                        nota: { type: 'string', nullable: true, example: 'Sin cebolla' },
                        modificadores: {
                          type: 'array',
                          items: {
                            type: 'object',
                            properties: {
                              modificadorOpcionId: { type: 'integer', example: 1 },
                              precioUnitario: { type: 'number', default: 0 }
                            },
                            required: ['modificadorOpcionId']
                          }
                        }
                      },
                      required: ['productoId', 'cantidad', 'precioUnitario']
                    }
                  }
                },
                required: ['items']
              }
            }
          }
        },
        responses: {
          '201': { description: 'Orden creada exitosamente' },
          '400': { description: 'Datos inválidos' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/ordenes/{id}': {
      get: {
        tags: ['Órdenes'],
        summary: 'Detalle de orden',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID de la orden'
          }
        ],
        responses: {
          '200': { description: 'Datos de la orden' },
          '404': { description: 'Orden no encontrada' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      put: {
        tags: ['Órdenes'],
        summary: 'Actualizar orden',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID de la orden'
          }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  mesaId: { type: 'integer', nullable: true },
                  reservaId: { type: 'integer', nullable: true },
                  clienteId: { type: 'integer', nullable: true },
                  clienteNombre: { type: 'string', nullable: true }
                }
              }
            }
          }
        },
        responses: {
          '200': { description: 'Orden actualizada' },
          '400': { description: 'Datos inválidos' },
          '404': { description: 'Orden no encontrada' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/ordenes/{id}/items': {
      post: {
        tags: ['Órdenes'],
        summary: 'Agregar items a orden',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID de la orden'
          }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  items: {
                    type: 'array',
                    items: {
                      type: 'object',
                      properties: {
                        productoId: { type: 'integer', example: 1 },
                        productoTamanoId: { type: 'integer', nullable: true },
                        cantidad: { type: 'number', example: 1 },
                        precioUnitario: { type: 'number', example: 75.00 },
                        nota: { type: 'string', nullable: true },
                        modificadores: {
                          type: 'array',
                          items: {
                            type: 'object',
                            properties: {
                              modificadorOpcionId: { type: 'integer' },
                              precioUnitario: { type: 'number', default: 0 }
                            },
                            required: ['modificadorOpcionId']
                          }
                        }
                      },
                      required: ['productoId', 'cantidad', 'precioUnitario']
                    }
                  }
                },
                required: ['items']
              }
            }
          }
        },
        responses: {
          '200': { description: 'Items agregados correctamente' },
          '400': { description: 'Datos inválidos' },
          '404': { description: 'Orden no encontrada' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/ordenes/{id}/estado': {
      patch: {
        tags: ['Órdenes'],
        summary: 'Cambiar estado de orden',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID de la orden'
          }
        ],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  estadoOrdenId: { type: 'integer', example: 2 }
                },
                required: ['estadoOrdenId']
              }
            }
          }
        },
        responses: {
          '200': { description: 'Estado actualizado' },
          '400': { description: 'Datos inválidos' },
          '404': { description: 'Orden no encontrada' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/pagos': {
      get: {
        tags: ['Pagos'],
        summary: 'Listado de pagos',
        security: [{ bearerAuth: [] }],
        responses: {
          '200': { description: 'Lista de pagos' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      post: {
        tags: ['Pagos'],
        summary: 'Registrar pago',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  ordenId: { type: 'integer', example: 1 },
                  formaPagoId: { type: 'integer', example: 1 },
                  monto: { type: 'number', example: 150.00 },
                  referencia: { type: 'string', nullable: true, example: 'REF-12345' },
                  estado: {
                    type: 'string',
                    enum: ['aplicado', 'anulado', 'pendiente'],
                    default: 'aplicado',
                    example: 'aplicado'
                  },
                  fechaPago: { type: 'string', format: 'date-time', nullable: true }
                },
                required: ['ordenId', 'formaPagoId', 'monto']
              }
            }
          }
        },
        responses: {
          '201': { description: 'Pago registrado exitosamente' },
          '400': { description: 'Datos inválidos' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/pagos/{id}': {
      get: {
        tags: ['Pagos'],
        summary: 'Detalle de pago',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'id',
            in: 'path',
            required: true,
            schema: { type: 'integer' },
            description: 'ID del pago'
          }
        ],
        responses: {
          '200': { description: 'Datos del pago' },
          '404': { description: 'Pago no encontrado' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/pagos/propinas': {
      get: {
        tags: ['Pagos'],
        summary: 'Listado de propinas',
        security: [{ bearerAuth: [] }],
        responses: {
          '200': { description: 'Lista de propinas' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      },
      post: {
        tags: ['Pagos'],
        summary: 'Registrar propina',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  ordenId: { type: 'integer', example: 1 },
                  monto: { type: 'number', example: 15.00 }
                },
                required: ['ordenId', 'monto']
              }
            }
          }
        },
        responses: {
          '201': { description: 'Propina registrada exitosamente' },
          '400': { description: 'Datos inválidos' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    },
    '/pagos/formas': {
      get: {
        tags: ['Pagos'],
        summary: 'Formas de pago disponibles',
        security: [{ bearerAuth: [] }],
        responses: {
          '200': { description: 'Lista de formas de pago' },
          '401': { description: 'No autenticado' },
          '403': { description: 'Sin permisos' }
        }
      }
    }
  }
};

