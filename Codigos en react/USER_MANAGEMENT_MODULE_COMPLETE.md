# Módulo de Gestión de Usuarios - Comandix

## Descripción General

Módulo completo de administración de usuarios para el rol Administrador de Comandix. Incluye todas las funcionalidades CRUD, gestión de roles, control de estados y cambio de contraseñas con validaciones completas.

## Características Implementadas

### 1. Listado de Usuarios
- **Tabla completa** con columnas:
  - Checkbox de selección múltiple
  - Nombre completo
  - Email
  - Teléfono
  - Roles (chips con colores diferenciados)
  - Estado (Activo/Inactivo)
  - Fecha de creación
  - Menú de acciones

- **Barra de Filtros**:
  - Búsqueda por nombre o email (en tiempo real)
  - Filtro por rol (Mesero, Cocinero, Capitán, Cajero, Administrador)
  - Filtro por estado (Activo/Inactivo)

- **Funcionalidades**:
  - Paginación (10 usuarios por página)
  - Selección múltiple con checkbox maestro
  - Acciones masivas: Activar, Desactivar, Eliminar
  - Estados: Cargando (skeleton), Vacío, Sin resultados, Error

### 2. Alta de Usuario (Modal)
- **Campos del formulario**:
  - Nombre completo (obligatorio)
  - Email (obligatorio, único, validación de formato)
  - Teléfono (opcional)
  - Roles (checkboxes múltiples, al menos uno obligatorio)
  - Contraseña (obligatoria, mínimo 8 caracteres)

- **Funcionalidades**:
  - Mostrar/ocultar contraseña
  - Medidor de fuerza de contraseña (débil/media/fuerte)
  - Validaciones en tiempo real
  - Detección de emails duplicados
  - Mensajes de error contextuales

### 3. Edición de Usuario (Modal)
- **Campos editables**:
  - Nombre completo
  - Email (con validación de duplicados)
  - Teléfono
  - Roles múltiples
  - Estado (toggle Activo/Inactivo)

- **Información de auditoría** (solo lectura):
  - Fecha de creación
  - Última actualización

- **Acciones**:
  - Guardar cambios
  - Restablecer valores originales
  - Eliminar usuario (con confirmación)

### 4. Cambio de Contraseña (Modal)
- **Campos**:
  - Contraseña actual (obligatoria)
  - Nueva contraseña (obligatoria, validaciones de seguridad)
  - Confirmar nueva contraseña (obligatoria, debe coincidir)

- **Validaciones de contraseña**:
  - Mínimo 8 caracteres
  - Al menos una letra mayúscula
  - Al menos una letra minúscula
  - Al menos un número
  - Medidor de fuerza en tiempo real
  - Indicador visual de coincidencia

- **Estados**:
  - Éxito
  - Error (contraseña actual incorrecta)
  - Alerta para usuarios con contraseña predefinida

### 5. Componentes Reutilizables

#### RoleBadge
Chip de rol con variantes de color:
- **Mesero**: Azul
- **Cocinero**: Naranja
- **Capitán**: Morado
- **Cajero**: Verde
- **Administrador**: Gris oscuro

#### PasswordStrengthMeter
Medidor visual de fuerza de contraseña con:
- Barra de progreso coloreada
- Etiqueta de nivel (Débil/Media/Fuerte)
- Cálculo basado en longitud y complejidad

### 6. Diálogos de Confirmación
- **Eliminación individual**: Confirmación con nombre del usuario
- **Acciones masivas**: 
  - Activar usuarios (confirmación con cantidad)
  - Desactivar usuarios (confirmación con cantidad)
  - Eliminar usuarios (confirmación destructiva)

### 7. Notificaciones Toast
Implementadas con Sonner para:
- ✅ Usuario creado exitosamente
- ✅ Usuario actualizado
- ✅ Contraseña cambiada
- ✅ Usuarios activados/desactivados
- ✅ Usuario(s) eliminado(s)
- ❌ Errores de validación
- ❌ Email duplicado
- ❌ Contraseña actual incorrecta

## Responsividad

### Desktop (1440px+)
- Tabla completa visible
- Sidebar fijo
- Todos los controles en línea
- Paginación completa

### Tablet (1024px)
- Tabla completa con ajuste de espaciado
- Header sticky con menú hamburguesa
- Filtros apilados verticalmente

### Mobile (390px)
- Lista de cards en lugar de tabla
- Acciones en menú desplegable
- Filtros en columna única
- Paginación simplificada
- Modales full-screen

## Estructura de Archivos

```
/components/admin/
├── UserManagement.tsx              # Componente principal
└── users/
    ├── mockUsers.ts                # Datos de ejemplo (20 usuarios)
    ├── RoleBadge.tsx               # Chip de rol
    ├── PasswordStrengthMeter.tsx   # Medidor de contraseña
    ├── NewUserModal.tsx            # Modal de creación
    ├── EditUserModal.tsx           # Modal de edición
    └── ChangePasswordModal.tsx     # Modal de cambio de contraseña
```

## Datos de Ejemplo

### Usuarios Mock (20 registros)
- **Activos**: 17 usuarios
- **Inactivos**: 3 usuarios
- **Combinaciones de roles**: Individuales y múltiples
- **Casos especiales**:
  - Usuario sin teléfono
  - Usuario con contraseña predefinida
  - Usuarios con múltiples roles

### Casos Límite Contemplados
- Email duplicado (validación)
- Usuario sin roles asignados (validación)
- Usuario inactivo (estado visual)
- Búsqueda sin resultados
- Lista vacía (estado inicial)
- Error de carga (skeleton)

## Accesibilidad

### Cumplimiento WCAG AA
- ✅ Etiquetas `aria-label` en todos los checkboxes
- ✅ `DialogDescription` en todos los modales
- ✅ Contraste de color AA en badges y estados
- ✅ Navegación por teclado completa
- ✅ Foco visible en todos los elementos interactivos
- ✅ Mensajes de error asociados a campos
- ✅ Textos alternativos en iconos

### Atajos y Navegación
- Tab/Shift+Tab: Navegación secuencial
- Enter: Confirmar acciones
- Escape: Cerrar modales
- Space: Toggle checkboxes

## Integración con AdminApp

El módulo se integra en el menú de navegación principal:

```tsx
{ id: 'users', name: 'Gestión de Usuarios', icon: Users }
```

Accesible desde el panel administrativo con icono de Users (lucide-react).

## Flujos Implementados

### Flujo de Creación
1. Click en "Nuevo Usuario"
2. Completar formulario con validaciones
3. Guardar → Toast de éxito
4. Usuario aparece en la lista

### Flujo de Edición
1. Click en menú → "Editar"
2. Modificar campos
3. Guardar cambios → Toast de éxito
4. O Restablecer para descartar cambios

### Flujo de Cambio de Contraseña
1. Click en menú → "Cambiar contraseña"
2. Validar contraseña actual
3. Ingresar y confirmar nueva contraseña
4. Guardar → Toast de éxito

### Flujo de Eliminación
1. Click en menú → "Eliminar"
2. Confirmación con nombre del usuario
3. Confirmar → Toast de éxito
4. Usuario removido de la lista

### Flujo de Acciones Masivas
1. Seleccionar múltiples usuarios (checkbox)
2. Click en acción masiva (Activar/Desactivar/Eliminar)
3. Confirmación con cantidad
4. Confirmar → Toast de éxito
5. Estados actualizados en la lista

## Seguridad

### Validaciones Frontend
- Email único
- Formato de email
- Longitud mínima de contraseña
- Complejidad de contraseña
- Confirmación de contraseña
- Al menos un rol asignado

### Simulación de Backend
- Delay de 600-1000ms en operaciones
- Chance de error (20%) en cambio de contraseña
- Validación de email duplicado

## Tecnologías Utilizadas

- **React**: Componentes funcionales con hooks
- **TypeScript**: Tipado completo
- **Shadcn/ui**: Componentes UI base
- **Lucide React**: Iconografía
- **Sonner**: Sistema de toasts
- **Tailwind CSS**: Estilos y responsividad

## Estado del Sistema

✅ **COMPLETO Y FUNCIONAL**

- Todos los componentes creados
- Todas las validaciones implementadas
- Responsividad completa (desktop/tablet/mobile)
- Accesibilidad WCAG AA
- Estados de carga y error
- Integración con AdminApp

## Próximos Pasos (Integración Backend)

Cuando se conecte con backend real:

1. **Reemplazar mockUsers** con llamadas a API
2. **Implementar autenticación** en endpoints
3. **Validar permisos** del administrador
4. **Persistir cambios** en base de datos MySQL
5. **Hash de contraseñas** en backend
6. **Logs de auditoría** para cambios
7. **Roles y permisos** granulares
8. **Rate limiting** en cambios de contraseña
9. **Emails de notificación** al crear/modificar usuarios
10. **Soft delete** en lugar de eliminación física

---

**Fecha de Implementación**: Octubre 2025  
**Versión**: 1.0.0  
**Autor**: Sistema Comandix
