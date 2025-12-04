# 🔄 Integración Completa Backend-Frontend

## ✅ Estado de la Integración

### Servicios Creados y Mejorados:
- ✅ `UsuariosService` - Completo con CRUD
- ✅ `ProductosService` - Completo con CRUD + DELETE
- ✅ `InventarioService` - Completo con CRUD + DELETE + Movimientos
- ✅ `MesasService` - Completo con CRUD + DELETE + Cambio de estado
- ✅ `CategoriasService` - Completo con CRUD + DELETE

### Métodos del AdminController que necesitan actualización:

#### 🔴 CRÍTICOS (solo en memoria):
1. `addInventoryItem()` - Necesita usar `InventarioService.createItem()`
2. `updateInventoryItem()` - Necesita usar `InventarioService.updateItem()`
3. `deleteInventoryItem()` - Necesita usar `InventarioService.eliminarItem()`
4. `addMenuItem()` - Necesita usar `ProductosService.createProducto()`
5. `updateMenuItem()` - Necesita usar `ProductosService.updateProducto()`
6. `deleteMenuItem()` - Necesita usar `ProductosService.desactivarProducto()`
7. `addTable()` - Necesita usar `MesasService.createMesa()`
8. `updateTable()` - Necesita usar `MesasService.updateMesa()`
9. `deleteTable()` - Necesita usar `MesasService.eliminarMesa()`

#### 🟡 IMPORTANTES (parcialmente conectados):
- `updateUser()` - Necesita usar `UsuariosService.actualizarUsuario()`
- `deleteUser()` - Necesita usar `UsuariosService.eliminarUsuario()`
- `restockInventoryItem()` - Necesita usar `InventarioService.registrarMovimiento()`

## 📋 Mapeo de Datos Frontend ↔ Backend

### Productos (MenuItem → Producto)
**Frontend (MenuItem):**
- `id` (String) → Backend: `id` (int)
- `name` → `nombre`
- `category` (String) → `categoriaId` (int) - **NECESITA MAPEO**
- `description` → `descripcion`
- `price` → `precio`
- `isAvailable` → `disponible`
- `sku` (no existe en MenuItem) → `sku` (opcional)

**⚠️ IMPORTANTE:** El frontend usa nombres de categorías (String), pero el backend necesita IDs (int). Se requiere:
1. Obtener lista de categorías del backend
2. Mapear nombre de categoría a ID
3. Usar el ID al crear/actualizar productos

### Inventario (InventoryItem → InventarioItem)
**Frontend (InventoryItem):**
- `id` (String) → Backend: `id` (int)
- `name` → `nombre`
- `unit` → `unidad`
- `currentStock` → `cantidadActual`
- `minStock` → `stockMinimo`
- `cost` → `costoUnitario`
- `status` (String) → Backend no tiene, se calcula
- `category` (String) → Backend no tiene

**⚠️ IMPORTANTE:** El frontend tiene campos adicionales (`maxStock`, `price`, `supplier`, `status`, `category`) que el backend no tiene. Se deben ignorar o mapear a campos existentes.

### Mesas (TableModel → Mesa)
**Frontend (TableModel):**
- `id` (int) → `id` (int) ✅
- `number` (int) → `codigo` (String) - **NECESITA CONVERSIÓN**
- `status` (String) → `estadoMesaId` (int) - **NECESITA MAPEO**
- `seats` (int) → `capacidad` (int)
- `section` (String) → `ubicacion` (String)
- `customers`, `waiter`, `currentTotal` → Backend no tiene (se calculan)

**⚠️ IMPORTANTE:** 
- `number` debe convertirse a String para `codigo`
- `status` (String como "libre", "ocupada") debe mapearse a `estadoMesaId` (int)
- Necesita obtener estados de mesa del backend para mapear

## 🔧 Pasos para Completar la Integración

### 1. Actualizar AdminController - Inventario
```dart
Future<void> addInventoryItem(InventoryItem item) async {
  try {
    final data = {
      'nombre': item.name,
      'unidad': item.unit,
      'cantidadActual': item.currentStock,
      'stockMinimo': item.minStock,
      'costoUnitario': item.cost,
      'activo': true,
    };
    final result = await _inventarioService.createItem(data);
    if (result != null) {
      // Mapear resultado a InventoryItem y agregar a lista
      final newItem = _mapBackendToInventoryItem(result);
      _inventory.insert(0, newItem);
      notifyListeners();
    }
  } catch (e) {
    rethrow;
  }
}
```

### 2. Actualizar AdminController - Productos
Similar al inventario, pero necesita mapeo de categorías.

### 3. Actualizar AdminController - Mesas
Similar, pero necesita mapeo de estados de mesa.

### 4. Actualizar Vistas
Las vistas que llaman a estos métodos necesitan:
- Hacer las llamadas `async`
- Mostrar indicadores de carga
- Manejar errores con SnackBar

## 📝 Consultas SQL para Verificar

Ver archivo: `backend/scripts/consultas-verificar-datos.sql`

## ⚠️ Notas Importantes

1. **Mapeo de Categorías**: El frontend usa nombres (String), el backend IDs (int). Se necesita un servicio helper para mapear.

2. **Mapeo de Estados de Mesa**: Similar a categorías, se necesita mapear nombres a IDs.

3. **Campos Adicionales del Frontend**: Algunos campos del frontend no existen en el backend. Se deben ignorar o calcular.

4. **IDs**: El frontend usa String IDs en algunos modelos, el backend usa int. Se necesita conversión.

5. **Errores**: Todos los métodos deben manejar errores y re-lanzarlos para que las vistas puedan mostrarlos.

