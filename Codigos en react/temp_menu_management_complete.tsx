// Archivo temporal completo para reemplazar el MenuManagement.tsx
// Incluye función para inicializar edición y modal de edición completo con tamaños

const handleEditItem = (item) => {
  setEditingItem(item);
  setProductSalsas(item.local_salsas || [...defaultSalsas]);
  setProductExtras(item.local_extras || [...defaultExtras]);
  // Importante: Cargar los tamaños existentes del producto
  setProductSizes(item.sizes || []);
};

const resetEditForm = () => {
  setEditingItem(null);
  setProductSalsas([]);
  setProductExtras([]);
  setProductSizes([]);
  setNewSize({ label: '', price: '' });
};

// Agregar después de línea 530 (después del Dialog de agregar producto):

{/* Modal de Edición */}
{editingItem && (
  <Dialog open={!!editingItem} onOpenChange={(open) => !open && resetEditForm()}>
    <DialogContent className="max-w-md">
      <DialogHeader>
        <DialogTitle className="text-amber-900">Editar Producto</DialogTitle>
        <DialogDescription className="text-amber-700">
          Modifica los detalles del producto "{editingItem.name}"
        </DialogDescription>
      </DialogHeader>
      <div className="space-y-4 max-h-96 overflow-y-auto">
        <div>
          <Label className="text-amber-900">Nombre del Producto</Label>
          <Input
            placeholder="Ej: Taco de Suadero"
            value={editingItem.name}
            onChange={(e) => setEditingItem({...editingItem, name: e.target.value})}
            className="border-amber-200 focus:border-amber-500"
          />
        </div>
        <div>
          <Label className="text-amber-900">Categoría</Label>
          <Select value={editingItem.category.toString()} onValueChange={(value) => setEditingItem({...editingItem, category: parseInt(value)})}>
            <SelectTrigger className="border-amber-200 focus:border-amber-500">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {managedCategories.map(category => (
                <SelectItem key={category.id} value={category.id.toString()}>
                  {category.icon} {category.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        
        {/* Switch de Tamaños para todas las categorías excepto Consomes */}
        {editingItem.category !== 6 && (
          <div className="flex items-center justify-between">
            <Label className="text-amber-900">Tamaños (Sí/No)</Label>
            <Switch
              checked={editingItem.has_sizes || editingItem.supports_sizes}
              onCheckedChange={(checked) => setEditingItem({...editingItem, has_sizes: checked, supports_sizes: checked})}
            />
          </div>
        )}
        
        {/* Campo de precio - deshabilitado si tiene tamaños */}
        {!(editingItem.has_sizes || editingItem.supports_sizes) && editingItem.category !== 6 && (
          <div>
            <Label className="text-amber-900">Precio ($)</Label>
            <Input
              type="number"
              placeholder="Ej: 25"
              value={editingItem.price}
              onChange={(e) => setEditingItem({...editingItem, price: e.target.value})}
              className="border-amber-200 focus:border-amber-500"
            />
          </div>
        )}
        
        {/* Campo de precio deshabilitado cuando hay tamaños */}
        {((editingItem.has_sizes || editingItem.supports_sizes) || editingItem.category === 6) && (
          <div>
            <Label className="text-amber-900 text-muted-foreground">Precio ($)</Label>
            <Input
              type="number"
              placeholder="Deshabilitado - usar precios por tamaño"
              value=""
              disabled
              className="border-amber-200 bg-gray-100 text-gray-400 cursor-not-allowed"
            />
          </div>
        )}
        
        {/* Lista de tamaños cuando está habilitado */}
        {((editingItem.has_sizes || editingItem.supports_sizes) || editingItem.category === 6) && (
          <div className="space-y-3">
            <Label className="text-amber-900">Configurar Tamaños</Label>
            
            {/* Lista de tamaños existentes */}
            {productSizes.length > 0 && (
              <div className="space-y-2 max-h-32 overflow-y-auto p-2 border border-amber-200 rounded">
                {productSizes.map((size, index) => (
                  <div key={size.id} className="flex items-center justify-between gap-2 p-2 bg-amber-50 rounded">
                    <span className="text-sm text-amber-900 font-medium">{size.label}</span>
                    <span className="text-sm text-orange-600">${size.price}</span>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handleDeleteProductSize(size.id)}
                      className="text-red-600 hover:text-red-700 hover:bg-red-50 h-6 w-6 p-0"
                    >
                      <Trash2 className="h-3 w-3" />
                    </Button>
                  </div>
                ))}
              </div>
            )}
            
            {/* Agregar nuevo tamaño */}
            <div className="flex gap-2">
              <Input
                placeholder={editingItem.category === 6 ? "Chico" : "Tamaño"}
                value={newSize.label}
                onChange={(e) => setNewSize({...newSize, label: e.target.value})}
                className="flex-1 border-amber-200 focus:border-amber-500"
              />
              <Input
                type="number"
                placeholder="Precio"
                value={newSize.price}
                onChange={(e) => setNewSize({...newSize, price: e.target.value})}
                className="w-24 border-amber-200 focus:border-amber-500"
              />
              <Button
                variant="outline"
                size="sm"
                onClick={handleAddProductSize}
                className="border-amber-300 text-amber-700 hover:bg-amber-100"
              >
                <Plus className="h-3 w-3" />
              </Button>
            </div>
            
            {editingItem.category === 6 && (
              <div className="text-xs text-amber-600">
                Sugeridos: Chico, Mediano, Grande
              </div>
            )}
          </div>
        )}
        
        {((editingItem.has_sizes || editingItem.supports_sizes) || editingItem.category === 6) && (
          <div className="p-3 bg-blue-50 border border-blue-200 rounded">
            <p className="text-sm text-blue-700">
              <Info className="inline h-4 w-4 mr-1" />
              Nota: El precio general está deshabilitado. Usa precios por tamaño.
            </p>
          </div>
        )}
        
        {editingItem.category === 6 && (
          <div className="p-3 bg-blue-50 border border-blue-200 rounded">
            <p className="text-sm text-blue-700">
              <Info className="inline h-4 w-4 mr-1" />
              Nota: Los Consomés siempre requieren tamaños.
            </p>
          </div>
        )}
        
        <div>
          <Label className="text-amber-900">Descripción</Label>
          <Textarea
            placeholder="Describe el producto..."
            value={editingItem.description}
            onChange={(e) => setEditingItem({...editingItem, description: e.target.value})}
            className="border-amber-200 focus:border-amber-500"
            rows={3}
          />
        </div>
        <div className="space-y-3">
          {editingItem.category !== 4 && (
            <>
              <div className="flex items-center justify-between">
                <Label className="text-amber-900">Servir caliente</Label>
                <div className="flex items-center gap-2">
                  <span className="text-xs text-amber-700">{editingItem.hot ? 'Sí' : 'No'}</span>
                  <Switch
                    checked={editingItem.hot}
                    onCheckedChange={(checked) => setEditingItem({...editingItem, hot: checked})}
                  />
                </div>
              </div>
              <div className="flex items-center justify-between">
                <Label className="text-amber-900">Picante</Label>
                <div className="flex items-center gap-2">
                  <span className="text-xs text-amber-700">{editingItem.spicy ? 'Sí' : 'No'}</span>
                  <Switch
                    checked={editingItem.spicy}
                    onCheckedChange={(checked) => setEditingItem({...editingItem, spicy: checked})}
                  />
                </div>
              </div>
              <div className="flex items-center justify-between">
                <Label className="text-amber-900">Permitir Salsas</Label>
                <div className="flex items-center gap-2">
                  <span className="text-xs text-amber-700">{editingItem.supports_salsas ? 'Sí' : 'No'}</span>
                  <Switch
                    checked={editingItem.supports_salsas}
                    onCheckedChange={(checked) => setEditingItem({...editingItem, supports_salsas: checked})}
                  />
                </div>
              </div>
              <div className="flex items-center justify-between">
                <Label className="text-amber-900">Permitir Ingredientes extra</Label>
                <div className="flex items-center gap-2">
                  <span className="text-xs text-amber-700">{editingItem.supports_extras ? 'Sí' : 'No'}</span>
                  <Switch
                    checked={editingItem.supports_extras}
                    onCheckedChange={(checked) => setEditingItem({...editingItem, supports_extras: checked})}
                  />
                </div>
              </div>
            </>
          )}
          
          <div className="flex items-center justify-between">
            <Label className="text-amber-900">Disponible</Label>
            <div className="flex items-center gap-2">
              <span className="text-xs text-amber-700">{editingItem.available ? 'Sí' : 'No'}</span>
              <Switch
                checked={editingItem.available}
                onCheckedChange={(checked) => setEditingItem({...editingItem, available: checked})}
              />
            </div>
          </div>
        </div>
        
        <div className="flex gap-2">
          <Button variant="outline" onClick={resetEditForm} className="flex-1">
            Cancelar
          </Button>
          <Button onClick={handleUpdateItem} className="flex-1 bg-amber-600 hover:bg-amber-700">
            Actualizar Producto
          </Button>
        </div>
      </div>
    </DialogContent>
  </Dialog>
)}

// Después en los botones de acciones del producto (línea 667 aprox), agregar:

                <Button
                  variant="outline" 
                  size="sm"
                  onClick={() => handleEditItem(item)}
                  className="border-blue-300 text-blue-700 hover:bg-blue-50"
                >
                  <Edit className="h-3 w-3" />
                </Button>