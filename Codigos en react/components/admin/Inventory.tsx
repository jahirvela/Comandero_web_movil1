import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogDescription } from '../ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { 
  Plus, 
  Edit, 
  Trash2, 
  Package, 
  AlertTriangle, 
  TrendingDown,
  TrendingUp,
  Search,
  Save,
  CheckCircle,
  ExternalLink
} from 'lucide-react';
import { Progress } from '../ui/progress';
import comandixLogo from 'figma:asset/1fbc60f087d05875d90014246dd3d98bb2726ad3.png';

const categories = ['Todos', 'Carne', 'Tortillas', 'Condimentos', 'Bebidas', 'Otros'];

const initialInventory = [
  { 
    id: 1, 
    name: 'Carne de Res para Barbacoa', 
    category: 'Carne',
    currentStock: 15,
    minStock: 5,
    maxStock: 30,
    unit: 'kg',
    cost: 180,
    supplier: 'Carnicería San Juan',
    lastUpdate: '2024-01-15'
  },
  { 
    id: 2, 
    name: 'Costilla de Res', 
    category: 'Carne',
    currentStock: 8,
    minStock: 3,
    maxStock: 20,
    unit: 'kg',
    cost: 220,
    supplier: 'Carnicería San Juan',
    lastUpdate: '2024-01-15'
  },
  { 
    id: 3, 
    name: 'Maciza de Res', 
    category: 'Carne',
    currentStock: 12,
    minStock: 5,
    maxStock: 25,
    unit: 'kg',
    cost: 200,
    supplier: 'Carnicería San Juan',
    lastUpdate: '2024-01-15'
  },
  { 
    id: 4, 
    name: 'Tortillas de Maíz', 
    category: 'Tortillas',
    currentStock: 200,
    minStock: 50,
    maxStock: 500,
    unit: 'pzs',
    cost: 0.80,
    supplier: 'Tortillería Local',
    lastUpdate: '2024-01-15'
  },
  { 
    id: 5, 
    name: 'Cebolla Blanca', 
    category: 'Condimentos',
    currentStock: 3,
    minStock: 2,
    maxStock: 10,
    unit: 'kg',
    cost: 25,
    supplier: 'Mercado Central',
    lastUpdate: '2024-01-14'
  },
  { 
    id: 6, 
    name: 'Cilantro', 
    category: 'Condimentos',
    currentStock: 1,
    minStock: 1,
    maxStock: 5,
    unit: 'kg',
    cost: 30,
    supplier: 'Mercado Central',
    lastUpdate: '2024-01-14'
  },
  { 
    id: 7, 
    name: 'Chile Guajillo', 
    category: 'Condimentos',
    currentStock: 0.5,
    minStock: 0.5,
    maxStock: 3,
    unit: 'kg',
    cost: 80,
    supplier: 'Mercado Central',
    lastUpdate: '2024-01-13'
  },
  { 
    id: 8, 
    name: 'Chile Serrano', 
    category: 'Condimentos',
    currentStock: 0.3,
    minStock: 0.2,
    maxStock: 2,
    unit: 'kg',
    cost: 60,
    supplier: 'Mercado Central',
    lastUpdate: '2024-01-13'
  },
  { 
    id: 9, 
    name: 'Agua de Horchata (Base)', 
    category: 'Bebidas',
    currentStock: 5,
    minStock: 2,
    maxStock: 15,
    unit: 'L',
    cost: 35,
    supplier: 'Distribuidora López',
    lastUpdate: '2024-01-15'
  },
  { 
    id: 10, 
    name: 'Agua de Jamaica (Base)', 
    category: 'Bebidas',
    currentStock: 4,
    minStock: 2,
    maxStock: 15,
    unit: 'L',
    cost: 25,
    supplier: 'Distribuidora López',
    lastUpdate: '2024-01-15'
  },
  { 
    id: 11, 
    name: 'Refrescos Variados', 
    category: 'Bebidas',
    currentStock: 24,
    minStock: 12,
    maxStock: 60,
    unit: 'pzs',
    cost: 12,
    supplier: 'Distribuidora López',
    lastUpdate: '2024-01-14'
  },
  { 
    id: 12, 
    name: 'Cerveza Nacional', 
    category: 'Bebidas',
    currentStock: 18,
    minStock: 12,
    maxStock: 48,
    unit: 'pzs',
    cost: 18,
    supplier: 'Distribuidora López',
    lastUpdate: '2024-01-14'
  },
  { 
    id: 13, 
    name: 'Sal', 
    category: 'Condimentos',
    currentStock: 2,
    minStock: 1,
    maxStock: 5,
    unit: 'kg',
    cost: 15,
    supplier: 'Abarrotes Diversos',
    lastUpdate: '2024-01-12'
  },
  { 
    id: 14, 
    name: 'Gas LP', 
    category: 'Otros',
    currentStock: 1,
    minStock: 1,
    maxStock: 2,
    unit: 'tanque',
    cost: 450,
    supplier: 'Gas Express',
    lastUpdate: '2024-01-10'
  }
];

export function Inventory() {
  const [inventory, setInventory] = useState(initialInventory);
  const [selectedCategory, setSelectedCategory] = useState('Todos');
  const [searchTerm, setSearchTerm] = useState('');
  const [editingItem, setEditingItem] = useState(null);
  const [newItem, setNewItem] = useState({
    name: '',
    category: 'Carne',
    currentStock: '',
    minStock: '',
    maxStock: '',
    unit: '',
    cost: '',
    supplier: ''
  });

  const filteredInventory = inventory.filter(item => {
    const matchesCategory = selectedCategory === 'Todos' || item.category === selectedCategory;
    const matchesSearch = item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         item.supplier.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesCategory && matchesSearch;
  });

  const getStockStatus = (item) => {
    const percentage = (item.currentStock / item.maxStock) * 100;
    if (item.currentStock <= item.minStock) return { status: 'critical', color: 'text-red-600', bgColor: 'bg-red-100' };
    if (percentage <= 30) return { status: 'low', color: 'text-yellow-600', bgColor: 'bg-yellow-100' };
    if (percentage >= 80) return { status: 'high', color: 'text-green-600', bgColor: 'bg-green-100' };
    return { status: 'normal', color: 'text-blue-600', bgColor: 'bg-blue-100' };
  };

  const getStockPercentage = (item) => {
    return Math.min((item.currentStock / item.maxStock) * 100, 100);
  };

  const handleAddItem = () => {
    const item = {
      id: Date.now(),
      ...newItem,
      currentStock: parseFloat(newItem.currentStock),
      minStock: parseFloat(newItem.minStock),
      maxStock: parseFloat(newItem.maxStock),
      cost: parseFloat(newItem.cost),
      lastUpdate: new Date().toISOString().split('T')[0]
    };
    setInventory([...inventory, item]);
    setNewItem({
      name: '',
      category: 'Carne',
      currentStock: '',
      minStock: '',
      maxStock: '',
      unit: '',
      cost: '',
      supplier: ''
    });
  };

  const handleUpdateItem = () => {
    setInventory(inventory.map(item => 
      item.id === editingItem.id ? {
        ...editingItem,
        currentStock: parseFloat(editingItem.currentStock),
        minStock: parseFloat(editingItem.minStock),
        maxStock: parseFloat(editingItem.maxStock),
        cost: parseFloat(editingItem.cost),
        lastUpdate: new Date().toISOString().split('T')[0]
      } : item
    ));
    setEditingItem(null);
  };

  const handleDeleteItem = (id) => {
    setInventory(inventory.filter(item => item.id !== id));
  };

  const handleStockAdjustment = (id, amount) => {
    setInventory(inventory.map(item => 
      item.id === id ? {
        ...item,
        currentStock: Math.max(0, item.currentStock + amount),
        lastUpdate: new Date().toISOString().split('T')[0]
      } : item
    ));
  };

  const criticalItems = inventory.filter(item => item.currentStock <= item.minStock);
  const lowStockItems = inventory.filter(item => {
    const percentage = (item.currentStock / item.maxStock) * 100;
    return percentage <= 30 && item.currentStock > item.minStock;
  });

  const totalValue = inventory.reduce((sum, item) => sum + (item.currentStock * item.cost), 0);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 bg-white rounded-lg flex items-center justify-center shadow-md border border-amber-200">
            <img 
              src={comandixLogo}
              alt="Comandix Logo"
              className="w-10 h-10 object-contain"
            />
          </div>
          <div>
            <h1 className="text-2xl font-medium text-amber-900 flex items-center gap-2">
              🔥 Inventario Barbacoa
            </h1>
            <p className="text-amber-700">Control de existencias del puesto</p>
          </div>
        </div>
        
        <Dialog>
          <DialogTrigger asChild>
            <Button className="bg-amber-600 hover:bg-amber-700 text-white">
              <Plus className="h-4 w-4 mr-2" />
              Agregar Producto
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle className="text-amber-900">Agregar al Inventario</DialogTitle>
              <DialogDescription className="text-amber-700">
                Registra un nuevo producto en el inventario del puesto
              </DialogDescription>
            </DialogHeader>
            <div className="space-y-4">
              <div>
                <Label className="text-amber-900">Nombre del Producto</Label>
                <Input
                  placeholder="Ej: Cebolla Morada"
                  value={newItem.name}
                  onChange={(e) => setNewItem({...newItem, name: e.target.value})}
                  className="border-amber-200 focus:border-amber-500"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label className="text-amber-900">Categoría</Label>
                  <Select value={newItem.category} onValueChange={(value) => setNewItem({...newItem, category: value})}>
                    <SelectTrigger className="border-amber-200 focus:border-amber-500">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {categories.filter(cat => cat !== 'Todos').map(category => (
                        <SelectItem key={category} value={category}>{category}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div>
                  <Label className="text-amber-900">Unidad</Label>
                  <Input
                    placeholder="kg, L, pzs"
                    value={newItem.unit}
                    onChange={(e) => setNewItem({...newItem, unit: e.target.value})}
                    className="border-amber-200 focus:border-amber-500"
                  />
                </div>
              </div>
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <Label className="text-amber-900">Stock Actual</Label>
                  <Input
                    type="number"
                    value={newItem.currentStock}
                    onChange={(e) => setNewItem({...newItem, currentStock: e.target.value})}
                    className="border-amber-200 focus:border-amber-500"
                  />
                </div>
                <div>
                  <Label className="text-amber-900">Stock Mínimo</Label>
                  <Input
                    type="number"
                    value={newItem.minStock}
                    onChange={(e) => setNewItem({...newItem, minStock: e.target.value})}
                    className="border-amber-200 focus:border-amber-500"
                  />
                </div>
                <div>
                  <Label className="text-amber-900">Stock Máximo</Label>
                  <Input
                    type="number"
                    value={newItem.maxStock}
                    onChange={(e) => setNewItem({...newItem, maxStock: e.target.value})}
                    className="border-amber-200 focus:border-amber-500"
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label className="text-amber-900">Costo Unitario ($)</Label>
                  <Input
                    type="number"
                    step="0.01"
                    value={newItem.cost}
                    onChange={(e) => setNewItem({...newItem, cost: e.target.value})}
                    className="border-amber-200 focus:border-amber-500"
                  />
                </div>
                <div>
                  <Label className="text-amber-900">Proveedor</Label>
                  <Input
                    placeholder="Nombre del proveedor"
                    value={newItem.supplier}
                    onChange={(e) => setNewItem({...newItem, supplier: e.target.value})}
                    className="border-amber-200 focus:border-amber-500"
                  />
                </div>
              </div>
              <Button onClick={handleAddItem} className="w-full bg-amber-600 hover:bg-amber-700">
                Agregar al Inventario
              </Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      {/* Alertas */}
      {(criticalItems.length > 0 || lowStockItems.length > 0) && (
        <div className="space-y-3">
          {criticalItems.length > 0 && (
            <Card className="bg-red-50 border-red-200">
              <CardContent className="p-4">
                <div className="flex items-center gap-2 text-red-800 font-medium mb-2">
                  <AlertTriangle className="h-4 w-4" />
                  Stock Crítico ({criticalItems.length} productos)
                </div>
                <div className="text-sm text-red-700">
                  {criticalItems.map(item => item.name).join(', ')}
                </div>
              </CardContent>
            </Card>
          )}
          {lowStockItems.length > 0 && (
            <Card className="bg-yellow-50 border-yellow-200">
              <CardContent className="p-4">
                <div className="flex items-center gap-2 text-yellow-800 font-medium mb-2">
                  <TrendingDown className="h-4 w-4" />
                  Stock Bajo ({lowStockItems.length} productos)
                </div>
                <div className="text-sm text-yellow-700">
                  {lowStockItems.map(item => item.name).join(', ')}
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      )}

      {/* Estadísticas */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card className="border-amber-200">
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-amber-900">{inventory.length}</div>
            <div className="text-sm text-amber-700">Productos Total</div>
          </CardContent>
        </Card>
        <Card className="border-red-200">
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-red-700">{criticalItems.length}</div>
            <div className="text-sm text-red-600">Stock Crítico</div>
          </CardContent>
        </Card>
        <Card className="border-yellow-200">
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-yellow-700">{lowStockItems.length}</div>
            <div className="text-sm text-yellow-600">Stock Bajo</div>
          </CardContent>
        </Card>
        <Card className="border-green-200">
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-green-700">${totalValue.toFixed(0)}</div>
            <div className="text-sm text-green-600">Valor Total</div>
          </CardContent>
        </Card>
      </div>

      {/* Filtros */}
      <div className="flex flex-col md:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-amber-500 h-4 w-4" />
          <Input
            placeholder="Buscar productos o proveedores..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10 border-amber-200 focus:border-amber-500"
          />
        </div>
        <div className="flex gap-2 flex-wrap">
          {categories.map(category => (
            <Button
              key={category}
              variant={selectedCategory === category ? "default" : "outline"}
              size="sm"
              onClick={() => setSelectedCategory(category)}
              className={selectedCategory === category 
                ? "bg-amber-600 hover:bg-amber-700 text-white" 
                : "border-amber-300 text-amber-700 hover:bg-amber-100"
              }
            >
              {category}
            </Button>
          ))}
        </div>
      </div>

      {/* Lista de inventario */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {filteredInventory.map(item => {
          const stockStatus = getStockStatus(item);
          const stockPercentage = getStockPercentage(item);
          
          return (
            <Card key={item.id} className={`border-2 ${stockStatus.bgColor} border-opacity-50`}>
              <CardHeader>
                <div className="flex justify-between items-start">
                  <div>
                    <CardTitle className="text-lg text-amber-900">{item.name}</CardTitle>
                    <div className="flex gap-2 mt-1">
                      <Badge variant="outline" className="text-xs border-amber-300 text-amber-800">
                        {item.category}
                      </Badge>
                      <Badge className={`text-xs ${stockStatus.color} bg-white border`}>
                        {item.currentStock} {item.unit}
                      </Badge>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-lg font-bold text-amber-900">
                      ${(item.currentStock * item.cost).toFixed(0)}
                    </div>
                    <div className="text-xs text-amber-700">${item.cost}/{item.unit}</div>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-amber-900">Stock:</span>
                    <span className={stockStatus.color}>
                      {item.currentStock}/{item.maxStock} {item.unit}
                    </span>
                  </div>
                  <Progress value={stockPercentage} className="h-2" />
                  <div className="flex justify-between text-xs text-amber-700">
                    <span>Mín: {item.minStock}</span>
                    <span>Máx: {item.maxStock}</span>
                  </div>
                </div>
                
                <div className="text-xs text-amber-700">
                  <div>Proveedor: {item.supplier}</div>
                  <div>Última actualización: {item.lastUpdate}</div>
                </div>
                
                <div className="flex justify-between items-center">
                  <div className="flex gap-1">
                    <Button 
                      variant="outline" 
                      size="sm"
                      onClick={() => handleStockAdjustment(item.id, -1)}
                      className="border-red-300 text-red-600 hover:bg-red-50"
                    >
                      <TrendingDown className="h-3 w-3" />
                    </Button>
                    <Button 
                      variant="outline" 
                      size="sm"
                      onClick={() => handleStockAdjustment(item.id, 1)}
                      className="border-green-300 text-green-600 hover:bg-green-50"
                    >
                      <TrendingUp className="h-3 w-3" />
                    </Button>
                  </div>
                  
                  <div className="flex gap-1">
                    <Dialog>
                      <DialogTrigger asChild>
                        <Button 
                          variant="outline" 
                          size="sm"
                          onClick={() => setEditingItem({
                            ...item,
                            currentStock: item.currentStock.toString(),
                            minStock: item.minStock.toString(),
                            maxStock: item.maxStock.toString(),
                            cost: item.cost.toString()
                          })}
                          className="border-amber-300 text-amber-700 hover:bg-amber-100"
                        >
                          <Edit className="h-3 w-3" />
                        </Button>
                      </DialogTrigger>
                      {editingItem && (
                        <DialogContent>
                          <DialogHeader>
                            <DialogTitle className="text-amber-900">Editar {editingItem.name}</DialogTitle>
                            <DialogDescription className="text-amber-700">
                              Modifica la información del producto en inventario
                            </DialogDescription>
                          </DialogHeader>
                          <div className="space-y-4">
                            <div>
                              <Label className="text-amber-900">Nombre</Label>
                              <Input
                                value={editingItem.name}
                                onChange={(e) => setEditingItem({...editingItem, name: e.target.value})}
                                className="border-amber-200 focus:border-amber-500"
                              />
                            </div>
                            <div className="grid grid-cols-3 gap-4">
                              <div>
                                <Label className="text-amber-900">Stock Actual</Label>
                                <Input
                                  type="number"
                                  value={editingItem.currentStock}
                                  onChange={(e) => setEditingItem({...editingItem, currentStock: e.target.value})}
                                  className="border-amber-200 focus:border-amber-500"
                                />
                              </div>
                              <div>
                                <Label className="text-amber-900">Stock Mínimo</Label>
                                <Input
                                  type="number"
                                  value={editingItem.minStock}
                                  onChange={(e) => setEditingItem({...editingItem, minStock: e.target.value})}
                                  className="border-amber-200 focus:border-amber-500"
                                />
                              </div>
                              <div>
                                <Label className="text-amber-900">Stock Máximo</Label>
                                <Input
                                  type="number"
                                  value={editingItem.maxStock}
                                  onChange={(e) => setEditingItem({...editingItem, maxStock: e.target.value})}
                                  className="border-amber-200 focus:border-amber-500"
                                />
                              </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                              <div>
                                <Label className="text-amber-900">Costo ($)</Label>
                                <Input
                                  type="number"
                                  step="0.01"
                                  value={editingItem.cost}
                                  onChange={(e) => setEditingItem({...editingItem, cost: e.target.value})}
                                  className="border-amber-200 focus:border-amber-500"
                                />
                              </div>
                              <div>
                                <Label className="text-amber-900">Proveedor</Label>
                                <Input
                                  value={editingItem.supplier}
                                  onChange={(e) => setEditingItem({...editingItem, supplier: e.target.value})}
                                  className="border-amber-200 focus:border-amber-500"
                                />
                              </div>
                            </div>
                            <Button onClick={handleUpdateItem} className="w-full bg-amber-600 hover:bg-amber-700">
                              Guardar Cambios
                            </Button>
                          </div>
                        </DialogContent>
                      )}
                    </Dialog>
                    
                    <Button 
                      variant="outline" 
                      size="sm"
                      onClick={() => handleDeleteItem(item.id)}
                      className="border-red-300 text-red-600 hover:bg-red-50"
                    >
                      <Trash2 className="h-3 w-3" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {filteredInventory.length === 0 && (
        <div className="text-center py-12 text-amber-700">
          <Package className="h-12 w-12 mx-auto mb-4 opacity-50" />
          <p>No se encontraron productos</p>
          <p className="text-sm">Intenta con otros términos de búsqueda</p>
        </div>
      )}
    </div>
  );
}