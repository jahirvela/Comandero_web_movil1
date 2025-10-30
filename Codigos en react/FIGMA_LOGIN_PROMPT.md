# Prompt para la IA de Figma - Auth/Login

## 📋 Instrucciones Generales

Editar solo los frames de **Auth/Login**.

Mantener tipografías, colores y espaciados del diseño actual de Comandix.

Entregar versiones: **Web / Tablet / Móvil** con reflow; la fila de roles puede colapsar a grid 2×3 o carrusel horizontal en móvil.

---

## 🎨 Estructura del Frame

### 1. Header del Card

**Logo Comandix:**
- Tamaño: 64px
- Centrado horizontalmente
- Margen inferior: 16px

**Título:**
- Texto: "Comandix"
- Tamaño: 2xl (text-2xl)
- Color: Amber-900
- Peso: Bold (font-bold)

**Descripción:**
- Texto: "Sistema de comandero para puesto de barbacoa"
- Color: Amber-700

---

## 👥 Sección "Roles del Sistema"

### Leyenda Superior:
- Texto: **"Roles del sistema (referencia)"**
- Tamaño: xs (text-xs)
- Color: Amber-800
- Peso: Medium (font-medium)
- Margen inferior: 12px

### Elementos Informativos (5 elementos):

**Características generales:**
- **NO interactivos** (sin hover, pressed, focus states)
- **Cursor:** Default (no pointer)
- **Stroke:** Reducido (border-width: 1px)
- **Elevación/Sombra:** Mínima o ninguna
- **Padding:** 8px
- **Border radius:** Redondeado (rounded-lg)

**Grid Layout:**
- Desktop/Tablet: 2 columnas (5to elemento ocupa 2 columnas - col-span-2)
- Mobile: Puede colapsar a 2×3 o carrusel horizontal
- Gap: 12px entre elementos

#### Elemento 1: Mesero
- **Icono:** UserCheck (Lucide)
- **Tamaño icono:** 32px (h-8 w-8)
- **Color icono:** Amber-600 (text-amber-600)
- **Border:** Amber-200 (border-amber-200)
- **Background:** Amber-50 (bg-amber-50)
- **Badge texto:** "mesero"
- **Badge estilo:** Outline, border-amber-300, text-amber-800, text-xs

#### Elemento 2: Cocina
- **Icono:** ChefHat (Lucide)
- **Tamaño icono:** 32px
- **Color icono:** Orange-600 (text-orange-600)
- **Border:** Orange-200 (border-orange-200)
- **Background:** Orange-50 (bg-orange-50)
- **Badge texto:** "cocina"
- **Badge estilo:** Outline, border-orange-300, text-orange-800, text-xs

#### Elemento 3: Admin
- **Icono:** Settings (Lucide)
- **Tamaño icono:** 32px
- **Color icono:** Green-600 (text-green-600)
- **Border:** Green-200 (border-green-200)
- **Background:** Green-50 (bg-green-50)
- **Badge texto:** "admin"
- **Badge estilo:** Outline, border-green-300, text-green-800, text-xs

#### Elemento 4: Cajero
- **Icono:** Calculator (Lucide)
- **Tamaño icono:** 32px
- **Color icono:** Blue-600 (text-blue-600)
- **Border:** Blue-200 (border-blue-200)
- **Background:** Blue-50 (bg-blue-50)
- **Badge texto:** "cajero"
- **Badge estilo:** Outline, border-blue-300, text-blue-800, text-xs

#### Elemento 5: Capitán
- **Icono:** ShieldCheck (Lucide)
- **Tamaño icono:** 32px
- **Color icono:** Purple-600 (text-purple-600)
- **Border:** Purple-200 (border-purple-200)
- **Background:** Purple-50 (bg-purple-50)
- **Badge texto:** "capitan"
- **Badge estilo:** Outline, border-purple-300, text-purple-800, text-xs

**⚠️ Importante:** Quitar toda interacción/prototipo asociado a estos elementos (no navegación, no "set variable", no autocompletar).

---

## 📝 Formulario de Acceso

### Campo: Nombre de usuario
- **Label:** "Nombre de usuario"
- **Label color:** Amber-900 (text-amber-900)
- **Input:**
  - Placeholder: "Ingresa tu nombre de usuario"
  - Border: Amber-200 (border-amber-200)
  - Focus border: Amber-500 (focus:border-amber-500)
  - Focus ring: Amber-500 (focus:ring-amber-500)
  - Auto-complete: "username"

### Campo: Contraseña
- **Label:** "Contraseña"
- **Label color:** Amber-900 (text-amber-900)
- **Input:**
  - Placeholder: "Ingresa tu contraseña"
  - Type: Password (con botón mostrar/ocultar)
  - Border: Amber-200
  - Focus border: Amber-500
  - Focus ring: Amber-500
  - Padding right: 40px (para botón de ojo)
  - Auto-complete: "current-password"

**Botón Mostrar/Ocultar:**
- **Posición:** Absolute, right: 12px, centrado verticalmente
- **Iconos:** Eye / EyeOff (Lucide, 16px)
- **Color:** Amber-600, hover: Amber-800
- **Sin borde**
- **Cursor:** Pointer

### Checkbox: Recordarme
- **Checkbox component** (ShadCN)
- **Label:** "Recordarme"
- **Label color:** Amber-900
- **Label size:** sm (text-sm)
- **Cursor:** Pointer en label
- **Margen vertical:** 16px

### Botón: Iniciar sesión
- **Tipo:** Submit button
- **Tamaño:** lg (size-lg)
- **Ancho:** Full width (w-full)
- **Background:** Gradient
  - From: Amber-600 (from-amber-600)
  - To: Orange-600 (to-orange-600)
- **Hover:**
  - From: Amber-700 (hover:from-amber-700)
  - To: Orange-700 (hover:to-orange-700)
- **Texto:** "Iniciar sesión" (normal), "Iniciando sesión..." (loading)
- **Shadow:** md (shadow-md)

### Mensaje Secundario
- **Texto:** "¿Problemas para entrar? **Contacta al administrador**"
- **Posición:** Centrado (text-center)
- **Tamaño:** sm (text-sm)
- **Color base:** Amber-700 (text-amber-700)
- **Color "Contacta al administrador":** Font-medium
- **Margen superior:** 16px

---

## 🔴 Estados del Formulario

### Estado 1: Normal
- Todos los campos habilitados
- Sin mensajes de error
- Botón enabled

### Estado 2: Cargando
- **Botón texto:** "Iniciando sesión..."
- **Spinner:** Loader2 icon (Lucide), 16px, animating spin
- **Spinner posición:** Margen right del texto
- **Todos los campos:** Disabled
- **Cursor:** Not-allowed en campos

### Estado 3: Credenciales Inválidas
- **Alert component** (destructive variant)
- **Posición:** Encima del formulario, margen bottom: 16px
- **Icono:** AlertCircle (Lucide), 16px
- **Texto:** "Credenciales inválidas. Verifica tu nombre de usuario y contraseña."
- **Color:** Red-50 background, Red-900 texto
- **Border:** Red-200

### Estado 4: Usuario Inactivo
- **Alert component** (destructive variant)
- **Posición:** Encima del formulario, margen bottom: 16px
- **Icono:** AlertCircle (Lucide), 16px
- **Texto:** "Tu cuenta está inactiva. Contacta al administrador para más información."
- **Color:** Red-50 background, Red-900 texto
- **Border:** Red-200

**⚠️ NO incluir:**
- "Olvidé mi contraseña"
- Enlace de recuperación
- Bloqueo por intentos fallidos
- Pantallas de cambio de contraseña

---

## 🎭 Modal: Selecciona tu Rol

**Trigger:** Se muestra cuando el usuario tiene múltiples roles asignados (roles.length > 1)

### Header del Modal:
- **Título:** "Selecciona tu rol"
- **Descripción:** "Hola, **[nombre del usuario]**. Tienes múltiples roles asignados. Selecciona el rol con el que deseas trabajar en esta sesión."

### Cards de Roles:

**Layout:**
- Grid vertical (1 columna)
- Gap: 12px entre cards
- Cada card ocupa ancho completo

**Card Individual:**
- **Border:** 2px
- **Border radius:** Redondeado (rounded-lg)
- **Padding:** 16px
- **Display:** Flex, items-center, gap: 16px
- **Cursor:** Pointer
- **Transition:** All
- **Hover:** Sombra media (hover:shadow-md)

**Contenido del Card:**
- **Icono:** 32px, flex-shrink-0
- **Título del rol:** Font-medium

**Cards por rol (usar mismos colores que sección informativa):**

1. **Mesero:**
   - Icono: UserCheck, Amber-600
   - Background: Amber-50, hover: Amber-100
   - Border: Amber-200
   - Texto: "Mesero"

2. **Cocinero:**
   - Icono: ChefHat, Orange-600
   - Background: Orange-50, hover: Orange-100
   - Border: Orange-200
   - Texto: "Cocinero"

3. **Administrador:**
   - Icono: Settings, Green-600
   - Background: Green-50, hover: Green-100
   - Border: Green-200
   - Texto: "Administrador"

4. **Cajero:**
   - Icono: Calculator, Blue-600
   - Background: Blue-50, hover: Blue-100
   - Border: Blue-200
   - Texto: "Cajero"

5. **Capitán:**
   - Icono: ShieldCheck, Purple-600
   - Background: Purple-50, hover: Purple-100
   - Border: Purple-200
   - Texto: "Capitán"

### Checkbox: Recordar este rol
- **Posición:** Debajo de los cards, padding-top: 8px
- **Label:** "Recordar este rol para futuras sesiones"
- **Label size:** sm (text-sm)
- **Cursor:** Pointer

**⚠️ Comportamiento del Modal:**
- No se puede cerrar sin seleccionar un rol (onInteractOutside prevented)
- No tiene botón X de cerrar
- Solo se cierra al seleccionar un rol

---

## 🔄 Flujo de Prototipo

### Login Exitoso:

**Si usuario tiene 1 solo rol:**
1. Mostrar estado "Cargando" (1 segundo)
2. Navegar directamente al home del rol:
   - **mesero** → MobileApp (FloorView - vista de mesas)
   - **cocina** → KitchenApp (órdenes activas)
   - **admin** → AdminApp (Dashboard)
   - **cajero** → CashierApp (cuentas pendientes)
   - **capitan** → CaptainApp (alertas y supervisión)

**Si usuario tiene múltiples roles:**
1. Mostrar estado "Cargando" (1 segundo)
2. Abrir Modal "Selecciona tu rol"
3. Usuario selecciona rol
4. Navegar al home del rol seleccionado

### Login Fallido:

**Credenciales inválidas:**
1. Mostrar estado "Cargando" (1 segundo)
2. Mostrar Alert "Credenciales inválidas"
3. Mantener formulario con valores ingresados
4. Focus en campo de contraseña

**Usuario inactivo:**
1. Mostrar estado "Cargando" (1 segundo)
2. Mostrar Alert "Usuario inactivo"
3. Mantener formulario con valores ingresados

---

## 🎨 Estilos del Card Principal

**Card Container:**
- **Max width:** 28rem (max-w-md - 448px)
- **Width:** Full width (w-full)
- **Border:** Amber-200/50 (border-amber-200/50)
- **Border radius:** Redondeado (rounded-lg)
- **Shadow:** lg (shadow-lg)
- **Background:** White

**Card Background (pantalla completa):**
- **Min height:** 100vh (min-h-screen)
- **Display:** Flex, items-center, justify-center
- **Background:** Gradient
  - From: Amber-50 (from-amber-50)
  - To: Orange-100 (to-orange-100)
  - Direction: Bottom-right (bg-gradient-to-br)
- **Padding:** 16px (p-4)

---

## 📱 Responsive Behavior

### Desktop (≥1024px):
- Card: 448px de ancho, centrado
- Roles: Grid 2 columnas
- Formulario: Spacing normal

### Tablet (≥768px, <1024px):
- Card: 90% ancho, max 448px, centrado
- Roles: Grid 2 columnas
- Formulario: Spacing ajustado

### Mobile (<768px):
- Card: 95% ancho, centrado
- Roles: Grid 2 columnas O carrusel horizontal
- Formulario: Spacing compacto
- Labels: Puede reducir tamaño de fuente si necesario
- Modal rol picker: Full screen en mobile

---

## ✅ Checklist Final

- [ ] Logo Comandix (64px) centrado
- [ ] Título y descripción con colores Amber
- [ ] 5 elementos informativos de roles (NO interactivos)
- [ ] Leyenda "Roles del sistema (referencia)"
- [ ] Campo Nombre de usuario con placeholder
- [ ] Campo Contraseña con mostrar/ocultar
- [ ] Checkbox "Recordarme"
- [ ] Botón "Iniciar sesión" con gradient Amber-Orange
- [ ] Mensaje "¿Problemas para entrar? Contacta al administrador"
- [ ] Estado Cargando con spinner
- [ ] Estado Credenciales Inválidas con Alert
- [ ] Estado Usuario Inactivo con Alert
- [ ] Modal "Selecciona tu rol" con cards por rol
- [ ] Checkbox "Recordar este rol" en modal
- [ ] Flujo de prototipo para 1 rol
- [ ] Flujo de prototipo para múltiples roles
- [ ] NO incluye "Olvidé mi contraseña"
- [ ] Responsive: Web / Tablet / Mobile
- [ ] Colores consistentes con sistema Comandix

---

## 🎯 Usuarios de Prueba

Para testing del prototipo:

| Username | Password | Rol(es) | Estado |
|----------|----------|---------|--------|
| mesero | demo123 | Mesero | Activo |
| cocina | demo123 | Cocinero | Activo |
| admin | demo123 | Administrador | Activo |
| cajero | demo123 | Cajero | Activo |
| capitan | demo123 | Capitán | Activo |
| inactivo | demo123 | Mesero | Inactivo |

**Ejemplo de usuario con múltiples roles (para probar modal):**
- Username: admin_multi
- Roles: Administrador, Cajero

---

**Fecha:** 21 de octubre de 2025
**Versión:** 1.0 - Sistema de Autenticación con Username
