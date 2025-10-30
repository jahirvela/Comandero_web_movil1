import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogDescription } from '../ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Switch } from '../ui/switch';
import { 
  Plus, 
  Edit, 
  Trash2, 
  DollarSign, 
  Package,
  AlertCircle,
  Flame,
  Info,
  Search,
  Settings,
  GripVertical,
  ChefHat
} from 'lucide-react';
import { Comandix } from '../Logo/Comandix';
import { useMenu } from '../MenuContext';
import { ImageWithFallback } from '../figma/ImageWithFallback';
import { EnhancedInventoryRecipe } from '../EnhancedInventoryRecipe';

// Se eliminó opción de aplicar a categoría — ediciones ahora afectan solo al producto.

const categories = [
  { id: 1, name: 'Tacos', icon: '🌮' },
  { id: 2, name: 'Platos Especiales', icon: '🍽️' },
  { id: 3, name: 'Acompañamientos', icon: '🥬' },
  { id: 4, name: 'Bebidas', icon: '🥤' },
  { id: 5, name: 'Extras', icon: '🌶️' },
  { id: 6, name: 'Consomes', icon: '🍲' }
];

// Datos iniciales de salsas e ingredientes extra por categoría
const defaultSalsas = [
  { id: 1, name: 'Salsa roja', description: 'Chile guajillo picante', price: 0 },
  { id: 2, name: 'Salsa verde', description: 'Chile serrano medio', price: 0 },
  { id: 3, name: 'Salsa de chile de árbol', description: 'Muy picante', price: 3 },
  { id: 4, name: 'Sin salsa', description: 'Sin salsa', price: 0 }
];

const defaultExtras = [
  { id: 1, name: 'Carne extra', description: 'Porción adicional de carne', price: 15 },
  { id: 2, name: 'Cebolla asada', description: 'Cebolla caramelizada', price: 5 },
  { id: 3, name: 'Cebolla curtida', description: 'Cebolla encurtida', price: 3 },
  { id: 4, name: 'Queso Oaxaca', description: 'Queso derretido', price: 8 },
  { id: 5, name: 'Aguacate', description: 'Rebanadas de aguacate', price: 12 }
];

const drinkOptions = [
  { id: 1, name: 'Con hielo', description: 'Bebida fría', price: 0 },
  { id: 2, name: 'Sin hielo', description: 'Al tiempo', price: 0 }
];

export function MenuManagement() {
  const { menuItems, updateMenuItem, addMenuItem, deleteMenuItem, toggleAvailability } = useMenu();
  const [selectedCategory, setSelectedCategory] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');
  const [editingItem, setEditingItem] = useState(null);
  const [newSalsa, setNewSalsa] = useState({ name: '', description: '', price: 0 });
  const [newExtra, setNewExtra] = useState({ name: '', description: '', price: 0 });
  const [productSalsas, setProductSalsas] = useState([]);
  const [productExtras, setProductExtras] = useState([]);
  const [newCategory, setNewCategory] = useState({ name: '', description: '', station: '' });
  const [managedCategories, setManagedCategories] = useState(categories);
  const [newSize, setNewSize] = useState({ label: '', price: '' });
  const [productSizes, setProductSizes] = useState([]);
  const [editingRecipe, setEditingRecipe] = useState(null);
  const [newItem, setNewItem] = useState({
    name: '',
    category: 1,
    price: '',
    description: '',
    available: true,
    hot: false,
    spicy: false,
    supports_salsas: true,
    supports_extras: true,
    supports_sizes: false,
    has_sizes: false,
    image: '',
    sizes: [],
    selectedSize: ''
  });

  const filteredItems = menuItems.filter(item => {
    const matchesCategory = selectedCategory === 0 || item.category === selectedCategory;
    const matchesSearch = item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         item.description.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesCategory && matchesSearch;
  });

  const handleAddItem = () => {
    // Validar bebidas con soporte de tamaños
    if (newItem.has_sizes || newItem.supports_sizes) {
      if (productSizes.length === 0) {
        alert('Agrega al menos un tamaño');
        return;
      }
      for (const size of productSizes) {
        if (!size.price || size.price <= 0) {
          alert('Precio inválido');
          return;
        }
      }
    }

    // Validar Consomes (siempre tienen tamaños)
    if (newItem.category === 6) {
      if (productSizes.length === 0) {
        alert('Agrega al menos un tamaño para este Consomé');
        return;
      }
      for (const size of productSizes) {
        if (!size.price || size.price <= 0) {
          alert('Precio inválido');
          return;
        }
      }
    }

    const categoryDefaults = {
      supports_salsas: newItem.category !== 4,
      supports_extras: newItem.category !== 4 && newItem.category !== 5,
      hot: newItem.category !== 4,
      spicy: newItem.category !== 4
    };
    
    let itemToAdd = { ...newItem };
    
    // Para Consomes, siempre habilitar tamaños
    if (newItem.category === 6) {
      itemToAdd = {
        ...itemToAdd,
        has_sizes: true,
        supports_sizes: true
      };
    }
    
    const item = {
      id: Date.now(),
      ...itemToAdd,
      ...categoryDefaults,
      price: (newItem.has_sizes || newItem.supports_sizes || newItem.category === 6) ? 0 : parseFloat(newItem.price || 0),
      sizes: productSizes.length > 0 ? [...productSizes] : [],
      local_salsas: [...defaultSalsas],
      local_extras: [...defaultExtras]
    };
    addMenuItem(item);
    setNewItem({
      name: '',
      category: 1,
      price: '',
      description: '',
      available: true,
      hot: false,
      spicy: false,
      supports_sizes: false,
      has_sizes: false,
      image: '',
      sizes: [],
      selectedSize: ''
    });
    setProductSizes([]);
  };

  const handleUpdateItem = () => {
    // Validar tamaños si has_sizes está habilitado
    if (editingItem.has_sizes || editingItem.supports_sizes) {
      if (productSizes.length === 0) {
        alert('Agrega al menos un tamaño');
        return;
      }
      for (const size of productSizes) {
        if (!size.price || size.price <= 0) {
          alert('Precio inválido');
          return;
        }
      }
    }

    // Validar Consomes (siempre tienen tamaños)
    if (editingItem.category === 6) {
      if (productSizes.length === 0) {
        alert('Agrega al menos un tamaño para este Consomé');
        return;
      }
      for (const size of productSizes) {
        if (!size.price || size.price <= 0) {
          alert('Precio inválido');
          return;
        }
      }
    }

    const updatedItem = {
      ...editingItem, 
      price: (editingItem.has_sizes || editingItem.supports_sizes || editingItem.category === 6) ? 0 : parseFloat(editingItem.price || 0),
      sizes: productSizes.length > 0 ? [...productSizes] : (editingItem.sizes || []),
      local_salsas: [...productSalsas],
      local_extras: [...productExtras]
    };
    updateMenuItem(updatedItem);
    setEditingItem(null);
    resetEditForm();
  };

  const handleDeleteItem = (id) => {
    deleteMenuItem(id);
  };

  const handleToggleAvailability = (id) => {
    toggleAvailability(id);
  };

  const getCategoryName = (categoryId) => {
    return managedCategories.find(cat => cat.id === categoryId)?.name || 'Sin categoría';
  };

  const handleAddProductSalsa = () => {
    if (newSalsa.name) {
      const salsa = {
        id: Date.now(),
        ...newSalsa
      };
      setProductSalsas([...productSalsas, salsa]);
      setNewSalsa({ name: '', description: '', price: 0 });
    }
  };

  const handleDeleteProductSalsa = (id) => {
    setProductSalsas(productSalsas.filter(salsa => salsa.id !== id));
  };

  const handleAddProductExtra = () => {
    if (newExtra.name) {
      const extra = {
        id: Date.now(),
        ...newExtra
      };
      setProductExtras([...productExtras, extra]);
      setNewExtra({ name: '', description: '', price: 0 });
    }
  };

  const handleDeleteProductExtra = (id) => {
    setProductExtras(productExtras.filter(extra => extra.id !== id));
  };

  const handleAddProductSize = () => {
    if (newSize.label && newSize.price) {
      const price = parseFloat(newSize.price);
      if (price <= 0) {
        alert('Precio inválido');
        return;
      }
      const size = {
        id: Date.now(),
        ...newSize,
        price: price
      };
      setProductSizes([...productSizes, size]);
      setNewSize({ label: '', price: '' });
    } else if (newSize.label && !newSize.price) {
      alert('Precio inválido');
    }
  };

  const handleDeleteProductSize = (id) => {
    setProductSizes(productSizes.filter(size => size.id !== id));
  };
  
  const handleCreateCategory = () => {
    if (newCategory.name) {
      const category = {
        id: Date.now(),
        name: newCategory.name,
        description: newCategory.description,
        station: newCategory.station,
        icon: '📦'
      };
      setManagedCategories([...managedCategories, category]);
      setNewCategory({ name: '', description: '', station: '' });
      alert(`Categoría "${category.name}" creada exitosamente`);
    }
  };

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

  const handleEditRecipe = (item) => {
    setEditingRecipe(item);
  };

  const handleSaveRecipe = (updatedProduct) => {
    updateMenuItem(updatedProduct);
    setEditingRecipe(null);
  };

  const handleCloseRecipe = () => {
    setEditingRecipe(null);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div className="flex items-center gap-4">
          <div className="bg-white rounded-lg p-2 shadow-md border border-amber-200">
            <Comandix width={40} height={40} />
          </div>
          <div>
            <h1 className="text-xl sm:text-2xl font-medium text-amber-900 flex items-center gap-2">
              🔥 Gestión de Menú
            </h1>
            <p className="text-amber-700">Administra los productos del puesto de barbacoa</p>
          </div>
        </div>
        
        <div className="flex flex-col sm:flex-row gap-2 w-full sm:w-auto">
          <Dialog>
            <DialogTrigger asChild>
              <Button className="bg-amber-600 hover:bg-amber-700 text-white w-full sm:w-auto">
                <Plus className="h-4 w-4 mr-2" />
                Agregar Producto
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-md">
              <DialogHeader>
                <DialogTitle className="text-amber-900">Agregar Nuevo Producto</DialogTitle>
                <DialogDescription className="text-amber-700">
                  Crea un nuevo producto para el menú del puesto de barbacoa
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-4 max-h-96 overflow-y-auto">
                <div>
                  <Label className="text-amber-900">Nombre del Producto</Label>
                  <Input
                    placeholder="Ej: Taco de Suadero"
                    value={newItem.name}
                    onChange={(e) => setNewItem({...newItem, name: e.target.value})}
                    className="border-amber-200 focus:border-amber-500"
                  />
                </div>
                <div>
                  <Label className="text-amber-900">Categoría</Label>
                  <Select value={newItem.category.toString()} onValueChange={(value) => setNewItem({...newItem, category: parseInt(value)})}>
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
                {newItem.category !== 6 && (
                  <div className="flex items-center justify-between">
                    <Label className="text-amber-900">Tamaños (Sí/No)</Label>
                    <Switch
                      checked={newItem.has_sizes}
                      onCheckedChange={(checked) => setNewItem({...newItem, has_sizes: checked, supports_sizes: checked})}
                    />
                  </div>
                )}
                
                {/* Campo de precio - deshabilitado si tiene tamaños */}
                {!newItem.has_sizes && newItem.category !== 6 && (
                  <div>
                    <Label className="text-amber-900">Precio ($)</Label>
                    <Input
                      type="number"
                      placeholder="Ej: 25"
                      value={newItem.price}
                      onChange={(e) => setNewItem({...newItem, price: e.target.value})}
                      className="border-amber-200 focus:border-amber-500"
                    />
                  </div>
                )}
                
                {/* Campo de precio deshabilitado cuando hay tamaños */}
                {(newItem.has_sizes || newItem.category === 6) && (
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
                {(newItem.has_sizes || newItem.category === 6) && (
                  <div className="space-y-3">
                    <Label className="text-amber-900">Configurar Tamaños</Label>
                    
                    {/* Lista de tamaños existentes */}
                    {productSizes.length > 0 && (
                      <div className="space-y-2 max-h-32 overflow-y-auto p-2 border border-amber-200 rounded">
                        {productSizes.map((size, index) => (
                          <div key={size.id} className="flex items-center gap-2 p-2 bg-amber-50 rounded">
                            <GripVertical className="h-4 w-4 text-amber-600 cursor-move" />
                            <Input
                              value={size.label}
                              onChange={(e) => {
                                const updated = productSizes.map(s => 
                                  s.id === size.id ? {...s, label: e.target.value} : s
                                );
                                setProductSizes(updated);
                              }}
                              placeholder="Chico"
                              className="flex-1 text-sm border-amber-200"
                            />
                            <Input
                              type="number"
                              value={size.price}
                              onChange={(e) => {
                                const updated = productSizes.map(s => 
                                  s.id === size.id ? {...s, price: parseFloat(e.target.value) || 0} : s
                                );
                                setProductSizes(updated);
                              }}
                              placeholder="Precio (ej. 45)"
                              className="w-24 text-sm border-amber-200"
                            />
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
                        placeholder={newItem.category === 6 ? "Chico" : "Chico"}
                        value={newSize.label}
                        onChange={(e) => setNewSize({...newSize, label: e.target.value})}
                        className="flex-1 border-amber-200 focus:border-amber-500"
                      />
                      <Input
                        type="number"
                        placeholder="Precio (ej. 45)"
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
                        + Añadir tamaño
                      </Button>
                    </div>
                    
                    {newItem.category === 6 && (
                      <div className="text-xs text-amber-600">
                        Sugeridos: Chico, Mediano, Grande
                      </div>
                    )}
                  </div>
                )}
                
                {(newItem.has_sizes || newItem.category === 6) && (
                  <div className="p-3 bg-blue-50 border border-blue-200 rounded">
                    <p className="text-sm text-blue-700">
                      <Info className="inline h-4 w-4 mr-1" />
                      Nota: El precio general está deshabilitado. Usa precios por tamaño.
                    </p>
                  </div>
                )}
                
                {newItem.category === 6 && (
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
                    value={newItem.description}
                    onChange={(e) => setNewItem({...newItem, description: e.target.value})}
                    className="border-amber-200 focus:border-amber-500"
                    rows={3}
                  />
                </div>
                <div className="space-y-3">
                  {newItem.category !== 4 && (
                    <>
                      <div className="flex items-center justify-between">
                        <Label className="text-amber-900">Servir caliente</Label>
                        <div className="flex items-center gap-2">
                          <span className="text-xs text-amber-700">{newItem.hot ? 'Sí' : 'No'}</span>
                          <Switch
                            checked={newItem.hot}
                            onCheckedChange={(checked) => setNewItem({...newItem, hot: checked})}
                          />
                        </div>
                      </div>
                      <div className="flex items-center justify-between">
                        <Label className="text-amber-900">Picante</Label>
                        <div className="flex items-center gap-2">
                          <span className="text-xs text-amber-700">{newItem.spicy ? 'Sí' : 'No'}</span>
                          <Switch
                            checked={newItem.spicy}
                            onCheckedChange={(checked) => setNewItem({...newItem, spicy: checked})}
                          />
                        </div>
                      </div>
                      <div className="flex items-center justify-between">
                        <Label className="text-amber-900">Permitir Salsas</Label>
                        <div className="flex items-center gap-2">
                          <span className="text-xs text-amber-700">{newItem.supports_salsas ? 'Sí' : 'No'}</span>
                          <Switch
                            checked={newItem.supports_salsas}
                            onCheckedChange={(checked) => setNewItem({...newItem, supports_salsas: checked})}
                          />
                        </div>
                      </div>
                      <div className="flex items-center justify-between">
                        <Label className="text-amber-900">Permitir Ingredientes extra</Label>
                        <div className="flex items-center gap-2">
                          <span className="text-xs text-amber-700">{newItem.supports_extras ? 'Sí' : 'No'}</span>
                          <Switch
                            checked={newItem.supports_extras}
                            onCheckedChange={(checked) => setNewItem({...newItem, supports_extras: checked})}
                          />
                        </div>
                      </div>
                    </>
                  )}
                  
                  <div className="flex items-center justify-between">
                    <Label className="text-amber-900">Disponible</Label>
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-amber-700">{newItem.available ? 'Sí' : 'No'}</span>
                      <Switch
                        checked={newItem.available}
                        onCheckedChange={(checked) => setNewItem({...newItem, available: checked})}
                      />
                    </div>
                  </div>
                </div>
                
                <Button onClick={handleAddItem} className="w-full bg-amber-600 hover:bg-amber-700">
                  Crear Producto
                </Button>
              </div>
            </DialogContent>
          </Dialog>
        </div>
      </div>

      {/* Estadísticas */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card className="border-amber-200">
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-amber-900">{menuItems.length}</div>
            <div className="text-sm text-amber-700">Total Productos</div>
          </CardContent>
        </Card>
        <Card className="border-green-200">
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-green-700">
              {menuItems.filter(item => item.available).length}
            </div>
            <div className="text-sm text-green-600">Disponibles</div>
          </CardContent>
        </Card>
        <Card className="border-red-200">
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-red-700">
              {menuItems.filter(item => item.hot).length}
            </div>
            <div className="text-sm text-red-600">🔥 Calientes</div>
          </CardContent>
        </Card>
        <Card className="border-orange-200">
          <CardContent className="p-4 text-center">
            <div className="text-2xl font-bold text-orange-700">
              ${menuItems.length > 0 ? Math.round(menuItems.reduce((sum, item) => sum + item.price, 0) / menuItems.length) : 0}
            </div>
            <div className="text-sm text-orange-600">Precio Promedio</div>
          </CardContent>
        </Card>
      </div>

      {/* Filtros y búsqueda */}
      <div className="flex flex-col md:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-amber-500 h-4 w-4" />
          <Input
            placeholder="Buscar productos..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10 border-amber-200 focus:border-amber-500"
          />
        </div>
        <div className="flex gap-2 flex-wrap">
          <Button
            variant={selectedCategory === 0 ? "default" : "outline"}
            size="sm"
            onClick={() => setSelectedCategory(0)}
            className={selectedCategory === 0 
              ? "bg-amber-600 hover:bg-amber-700 text-white" 
              : "border-amber-300 text-amber-700 hover:bg-amber-100"
            }
          >
            Todos
          </Button>
          {managedCategories.map(category => (
            <Button
              key={category.id}
              variant={selectedCategory === category.id ? "default" : "outline"}
              size="sm"
              onClick={() => setSelectedCategory(category.id)}
              className={selectedCategory === category.id 
                ? "bg-amber-600 hover:bg-amber-700 text-white" 
                : "border-amber-300 text-amber-700 hover:bg-amber-100"
              }
            >
              <span className="hidden sm:inline">{category.icon} {category.name}</span>
              <span className="sm:hidden">{category.icon}</span>
            </Button>
          ))}
        </div>
      </div>

      {/* Lista de productos */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredItems.map(item => (
          <Card key={item.id} className={`border-2 ${item.available ? 'border-amber-200' : 'border-gray-300 opacity-60'}`}>
            <CardHeader>
              <div className="flex justify-between items-start">
                <CardTitle className="text-lg text-amber-900">{item.name}</CardTitle>
                <div className="flex items-center gap-1">
                  {!item.has_sizes && !item.supports_sizes && item.category !== 6 && (
                    <span className="text-lg font-bold text-orange-600">${item.price}</span>
                  )}
                  {(item.has_sizes || item.supports_sizes || item.category === 6) && (
                    <span className="text-sm text-amber-700">Varios precios</span>
                  )}
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                <div className="flex items-center gap-2 flex-wrap">
                  <Badge variant="outline" className="border-amber-300 text-amber-700">
                    {getCategoryName(item.category)}
                  </Badge>
                  {item.hot && (
                    <Badge variant="outline" className="border-red-300 text-red-700">
                      <Flame className="h-3 w-3 mr-1" />
                      Caliente
                    </Badge>
                  )}
                  {!item.available && (
                    <Badge variant="destructive">
                      <AlertCircle className="h-3 w-3 mr-1" />
                      No disponible
                    </Badge>
                  )}
                </div>
                
                <p className="text-sm text-amber-700 line-clamp-2">
                  {item.description || 'Sin descripción'}
                </p>
                
                {/* Información de tamaños */}
                {(item.has_sizes || item.supports_sizes || item.category === 6) && item.sizes && item.sizes.length > 0 && (
                  <div className="text-xs text-amber-600">
                    <p className="font-medium">Tamaños disponibles:</p>
                    <div className="flex gap-1 flex-wrap mt-1">
                      {item.sizes.map((size, index) => (
                        <span key={index} className="bg-amber-100 px-2 py-1 rounded text-xs">
                          {size.label}: ${size.price}
                        </span>
                      ))}
                    </div>
                  </div>
                )}
                
                <div className="flex gap-2 pt-2 flex-wrap">
                  <Dialog>
                    <DialogTrigger asChild>
                      <Button 
                        variant="outline" 
                        size="sm"
                        onClick={() => handleEditItem(item)}
                        className="border-amber-300 text-amber-700 hover:bg-amber-100"
                      >
                        <Edit className="h-3 w-3 mr-1" />
                        Editar
                      </Button>
                    </DialogTrigger>
                    <DialogContent className="sm:max-w-md lg:max-w-lg max-h-[90vh] overflow-y-auto">
                      <DialogHeader>
                        <DialogTitle className="text-amber-900">Editar Producto</DialogTitle>
                        <DialogDescription className="text-amber-700">
                          Modifica la información del producto
                        </DialogDescription>
                      </DialogHeader>
                      {editingItem && (
                        <div className="space-y-4">
                          <div>
                            <Label className="text-amber-900">Nombre del Producto</Label>
                            <Input
                              value={editingItem.name}
                              onChange={(e) => setEditingItem({...editingItem, name: e.target.value})}
                              className="border-amber-200 focus:border-amber-500"
                            />
                          </div>
                          
                          <div>
                            <Label className="text-amber-900">Categoría</Label>
                            <Select 
                              value={editingItem.category.toString()} 
                              onValueChange={(value) => setEditingItem({...editingItem, category: parseInt(value)})}
                            >
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
                                checked={editingItem.has_sizes}
                                onCheckedChange={(checked) => setEditingItem({...editingItem, has_sizes: checked, supports_sizes: checked})}
                              />
                            </div>
                          )}
                          
                          {!editingItem.has_sizes && editingItem.category !== 6 && (
                            <div>
                              <Label className="text-amber-900">Precio ($)</Label>
                              <Input
                                type="number"
                                value={editingItem.price}
                                onChange={(e) => setEditingItem({...editingItem, price: parseFloat(e.target.value) || 0})}
                                className="border-amber-200 focus:border-amber-500"
                              />
                            </div>
                          )}
                          
                          {/* Campo de precio deshabilitado cuando hay tamaños */}
                          {(editingItem.has_sizes || editingItem.category === 6) && (
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
                          {(editingItem.has_sizes || editingItem.category === 6) && (
                            <div className="space-y-3">
                              <Label className="text-amber-900">Configurar Tamaños</Label>
                              
                              {/* Lista de tamaños existentes */}
                              {productSizes.length > 0 && (
                                <div className="space-y-2 max-h-32 overflow-y-auto p-2 border border-amber-200 rounded">
                                  {productSizes.map((size, index) => (
                                    <div key={size.id} className="flex items-center gap-2 p-2 bg-amber-50 rounded">
                                      <GripVertical className="h-4 w-4 text-amber-600 cursor-move" />
                                      <Input
                                        value={size.label}
                                        onChange={(e) => {
                                          const updated = productSizes.map(s => 
                                            s.id === size.id ? {...s, label: e.target.value} : s
                                          );
                                          setProductSizes(updated);
                                        }}
                                        placeholder="Chico"
                                        className="flex-1 text-sm border-amber-200"
                                      />
                                      <Input
                                        type="number"
                                        value={size.price}
                                        onChange={(e) => {
                                          const updated = productSizes.map(s => 
                                            s.id === size.id ? {...s, price: parseFloat(e.target.value) || 0} : s
                                          );
                                          setProductSizes(updated);
                                        }}
                                        placeholder="Precio (ej. 45)"
                                        className="w-24 text-sm border-amber-200"
                                      />
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
                                  placeholder={editingItem.category === 6 ? "Chico" : "Chico"}
                                  value={newSize.label}
                                  onChange={(e) => setNewSize({...newSize, label: e.target.value})}
                                  className="flex-1 border-amber-200 focus:border-amber-500"
                                />
                                <Input
                                  type="number"
                                  placeholder="Precio (ej. 45)"
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
                                  + Añadir tamaño
                                </Button>
                              </div>
                              
                              {editingItem.category === 6 && (
                                <div className="text-xs text-amber-600">
                                  Sugeridos: Chico, Mediano, Grande
                                </div>
                              )}
                            </div>
                          )}
                          
                          {(editingItem.has_sizes || editingItem.category === 6) && (
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
                                  <Switch
                                    checked={editingItem.hot}
                                    onCheckedChange={(checked) => setEditingItem({...editingItem, hot: checked})}
                                  />
                                </div>
                                <div className="flex items-center justify-between">
                                  <Label className="text-amber-900">Picante</Label>
                                  <Switch
                                    checked={editingItem.spicy}
                                    onCheckedChange={(checked) => setEditingItem({...editingItem, spicy: checked})}
                                  />
                                </div>
                                <div className="flex items-center justify-between">
                                  <Label className="text-amber-900">Permitir Salsas</Label>
                                  <Switch
                                    checked={editingItem.supports_salsas}
                                    onCheckedChange={(checked) => setEditingItem({...editingItem, supports_salsas: checked})}
                                  />
                                </div>
                                <div className="flex items-center justify-between">
                                  <Label className="text-amber-900">Permitir Ingredientes extra</Label>
                                  <Switch
                                    checked={editingItem.supports_extras}
                                    onCheckedChange={(checked) => setEditingItem({...editingItem, supports_extras: checked})}
                                  />
                                </div>
                              </>
                            )}
                            
                            <div className="flex items-center justify-between">
                              <Label className="text-amber-900">Disponible</Label>
                              <Switch
                                checked={editingItem.available}
                                onCheckedChange={(checked) => setEditingItem({...editingItem, available: checked})}
                              />
                            </div>
                          </div>
                          
                          <div className="flex gap-2 pt-4">
                            <Button 
                              onClick={handleUpdateItem} 
                              className="flex-1 bg-amber-600 hover:bg-amber-700"
                            >
                              Guardar Cambios
                            </Button>
                            <Button 
                              variant="outline" 
                              onClick={resetEditForm}
                              className="border-amber-300 text-amber-700 hover:bg-amber-100"
                            >
                              Cancelar
                            </Button>
                          </div>
                        </div>
                      )}
                    </DialogContent>
                  </Dialog>
                  
                  <Button 
                    variant="outline" 
                    size="sm"
                    onClick={() => handleEditRecipe(item)}
                    className="border-green-300 text-green-700 hover:bg-green-100"
                  >
                    <ChefHat className="h-3 w-3 mr-1" />
                    Receta
                  </Button>
                  
                  <Button 
                    variant="outline" 
                    size="sm"
                    onClick={() => handleToggleAvailability(item.id)}
                    className={item.available 
                      ? "border-orange-300 text-orange-700 hover:bg-orange-100" 
                      : "border-green-300 text-green-700 hover:bg-green-100"
                    }
                  >
                    <Package className="h-3 w-3 mr-1" />
                    {item.available ? 'Deshabilitar' : 'Habilitar'}
                  </Button>
                  
                  <Button 
                    variant="outline" 
                    size="sm"
                    onClick={() => handleDeleteItem(item.id)}
                    className="border-red-300 text-red-700 hover:bg-red-100"
                  >
                    <Trash2 className="h-3 w-3 mr-1" />
                    Eliminar
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {filteredItems.length === 0 && (
        <div className="text-center py-12">
          <Package className="h-12 w-12 mx-auto text-amber-500 mb-4" />
          <h3 className="text-lg font-medium text-amber-900 mb-2">No hay productos</h3>
          <p className="text-amber-700 mb-4">
            {searchTerm || selectedCategory > 0 
              ? 'No se encontraron productos con los filtros aplicados' 
              : 'Agrega tu primer producto al menú'}
          </p>
          <Button className="bg-amber-600 hover:bg-amber-700 text-white">
            <Plus className="h-4 w-4 mr-2" />
            Agregar Producto
          </Button>
        </div>
      )}

      {/* Enhanced Inventory Recipe Modal */}
      {editingRecipe && (
        <EnhancedInventoryRecipe
          product={editingRecipe}
          onSave={handleSaveRecipe}
          onClose={handleCloseRecipe}
        />
      )}
    </div>
  );
}