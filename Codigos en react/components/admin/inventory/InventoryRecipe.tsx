import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Badge } from './ui/badge';
import { Checkbox } from './ui/checkbox';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogDescription } from './ui/dialog';
import { Separator } from './ui/separator';
import { 
  ChefHat, 
  Plus, 
  Minus, 
  Save, 
  Trash2, 
  AlertTriangle,
  Package,
  Clock,
  Settings
} from 'lucide-react';

interface Ingredient {
  id: string;
  name: string;
  unit: string;
  quantity: number;
  autoConsume: boolean;
}

interface Product {
  id: string;
  name: string;
  category: string;
  recipe: Ingredient[];
}

// Mock de inventario disponible
const mockInventoryItems = [
  { id: 'beef', name: 'Carne de res', unit: 'g', stock: 2500 },
  { id: 'onion', name: 'Cebolla', unit: 'g', stock: 800 },
  { id: 'tortilla', name: 'Tortillas', unit: 'pzs', stock: 50 },
  { id: 'salsa-roja', name: 'Salsa roja', unit: 'ml', stock: 1200 },
  { id: 'salsa-verde', name: 'Salsa verde', unit: 'ml', stock: 800 },
  { id: 'cheese', name: 'Queso', unit: 'g', stock: 600 },
  { id: 'consomme', name: 'Consomé base', unit: 'ml', stock: 2000 }
];

export function InventoryRecipe({ product, onSave, onClose }) {
  const [recipe, setRecipe] = useState<Ingredient[]>(product?.recipe || []);
  const [showAddIngredient, setShowAddIngredient] = useState(false);
  const [newIngredient, setNewIngredient] = useState({
    inventoryItemId: '',
    quantity: 0,
    autoConsume: true
  });

  const addIngredient = () => {
    const inventoryItem = mockInventoryItems.find(item => item.id === newIngredient.inventoryItemId);
    if (!inventoryItem) return;

    const ingredient: Ingredient = {
      id: inventoryItem.id,
      name: inventoryItem.name,
      unit: inventoryItem.unit,
      quantity: newIngredient.quantity,
      autoConsume: newIngredient.autoConsume
    };

    setRecipe(prev => [...prev, ingredient]);
    setNewIngredient({ inventoryItemId: '', quantity: 0, autoConsume: true });
    setShowAddIngredient(false);
  };

  const removeIngredient = (id: string) => {
    setRecipe(prev => prev.filter(ing => ing.id !== id));
  };

  const updateIngredient = (id: string, field: keyof Ingredient, value: any) => {
    setRecipe(prev => prev.map(ing => 
      ing.id === id ? { ...ing, [field]: value } : ing
    ));
  };

  const handleSave = () => {
    onSave({
      ...product,
      recipe
    });
    onClose();
  };

  const calculateTotalCost = () => {
    // Mock de cálculo de costo - en producción vendría de precios de inventario
    return recipe.reduce((total, ing) => {
      const baseCost = ing.id === 'beef' ? 0.08 : ing.id === 'cheese' ? 0.12 : 0.05;
      return total + (ing.quantity * baseCost);
    }, 0);
  };

  return (
    <Dialog open={true} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-lg lg:max-w-2xl max-h-[85vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <ChefHat className="h-5 w-5" />
            Receta / Ingredientes — {product?.name}
          </DialogTitle>
          <DialogDescription>
            Configura los ingredientes necesarios para preparar este producto
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* Información del producto */}
          <Card className="border-amber-200 bg-amber-50">
            <CardContent className="p-4">
              <div className="flex justify-between items-center">
                <div>
                  <h4 className="font-medium text-amber-900">{product?.name}</h4>
                  <p className="text-sm text-amber-700">Categoría: {product?.category}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm text-amber-700">Costo estimado por porción:</p>
                  <p className="text-lg font-medium text-amber-900">${calculateTotalCost().toFixed(2)}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Lista de ingredientes */}
          <Card className="border-blue-200">
            <CardHeader>
              <CardTitle className="text-blue-900">Ingredientes de la receta</CardTitle>
              <p className="text-sm text-blue-700">
                Especifica la cantidad exacta que se consume por porción. Ej: Carne: 30 g; Tortilla: 2 pzs.
              </p>
            </CardHeader>
            <CardContent className="space-y-3">
              {recipe.length === 0 && (
                <div className="text-center py-6 text-blue-600">
                  <Package className="h-8 w-8 mx-auto mb-2 opacity-50" />
                  <p>Sin ingredientes configurados</p>
                  <p className="text-sm">Agrega ingredientes para crear la receta</p>
                </div>
              )}

              {recipe.map((ingredient) => (
                <div key={ingredient.id} className="flex items-center gap-3 p-3 bg-blue-50 rounded border border-blue-200">
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <span className="font-medium text-blue-900">{ingredient.name}</span>
                      {ingredient.autoConsume && (
                        <Badge className="bg-green-100 text-green-800 border-green-300 text-xs">
                          Auto-descuento
                        </Badge>
                      )}
                    </div>
                  </div>
                  
                  <div className="flex items-center gap-2">
                    <Input
                      type="number"
                      value={ingredient.quantity}
                      onChange={(e) => updateIngredient(ingredient.id, 'quantity', parseFloat(e.target.value) || 0)}
                      className="w-20 border-blue-200"
                      min="0"
                      step="0.1"
                    />
                    <span className="text-sm text-blue-700 w-8">{ingredient.unit}</span>
                  </div>

                  <Checkbox
                    checked={ingredient.autoConsume}
                    onCheckedChange={(checked) => updateIngredient(ingredient.id, 'autoConsume', checked)}
                  />
                  <Label className="text-xs text-blue-700">Auto</Label>

                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => removeIngredient(ingredient.id)}
                    className="border-red-300 text-red-700 hover:bg-red-50"
                  >
                    <Trash2 className="h-3 w-3" />
                  </Button>
                </div>
              ))}

              {/* Formulario para agregar ingrediente */}
              {showAddIngredient && (
                <div className="p-3 bg-gray-50 border border-gray-200 rounded">
                  <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
                    <div className="sm:col-span-2">
                      <Label className="text-gray-700">Ingrediente</Label>
                      <Select 
                        value={newIngredient.inventoryItemId} 
                        onValueChange={(value) => setNewIngredient(prev => ({...prev, inventoryItemId: value}))}
                      >
                        <SelectTrigger className="border-gray-300">
                          <SelectValue placeholder="Seleccionar..." />
                        </SelectTrigger>
                        <SelectContent>
                          {mockInventoryItems
                            .filter(item => !recipe.some(ing => ing.id === item.id))
                            .map(item => (
                              <SelectItem key={item.id} value={item.id}>
                                {item.name} ({item.unit})
                              </SelectItem>
                            ))
                          }
                        </SelectContent>
                      </Select>
                    </div>

                    <div>
                      <Label className="text-gray-700">Cantidad</Label>
                      <Input
                        type="number"
                        value={newIngredient.quantity}
                        onChange={(e) => setNewIngredient(prev => ({...prev, quantity: parseFloat(e.target.value) || 0}))}
                        className="border-gray-300"
                        min="0"
                        step="0.1"
                      />
                    </div>

                    <div className="flex items-end gap-2">
                      <div className="flex items-center space-x-2">
                        <Checkbox
                          checked={newIngredient.autoConsume}
                          onCheckedChange={(checked) => setNewIngredient(prev => ({...prev, autoConsume: checked}))}
                        />
                        <Label className="text-xs text-gray-700">Auto-descuento</Label>
                      </div>
                    </div>
                  </div>

                  <div className="flex gap-2 mt-3">
                    <Button
                      size="sm"
                      onClick={addIngredient}
                      disabled={!newIngredient.inventoryItemId || newIngredient.quantity <= 0}
                      className="bg-blue-600 hover:bg-blue-700"
                    >
                      <Plus className="h-3 w-3 mr-1" />
                      Agregar
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setShowAddIngredient(false)}
                      className="border-gray-300"
                    >
                      Cancelar
                    </Button>
                  </div>
                </div>
              )}

              {!showAddIngredient && (
                <Button
                  variant="outline"
                  onClick={() => setShowAddIngredient(true)}
                  className="w-full border-blue-300 text-blue-700 hover:bg-blue-50"
                >
                  <Plus className="h-4 w-4 mr-2" />
                  Agregar Ingrediente
                </Button>
              )}
            </CardContent>
          </Card>

          {/* Resumen de consumo */}
          {recipe.length > 0 && (
            <Card className="border-green-200 bg-green-50">
              <CardHeader>
                <CardTitle className="text-green-900">Resumen de consumo por porción</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  {recipe.map((ingredient) => (
                    <div key={ingredient.id} className="flex justify-between text-sm">
                      <span className="text-green-700">
                        {ingredient.name}: {ingredient.quantity} {ingredient.unit}
                      </span>
                      {ingredient.autoConsume && (
                        <Badge className="bg-green-100 text-green-800 border-green-300 text-xs">
                          Se descontará automáticamente
                        </Badge>
                      )}
                    </div>
                  ))}
                  <Separator className="my-2" />
                  <div className="flex justify-between font-medium">
                    <span className="text-green-900">Costo estimado:</span>
                    <span className="text-green-900">${calculateTotalCost().toFixed(2)}</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Alertas */}
          {recipe.some(ing => !ing.autoConsume) && (
            <div className="flex items-center gap-2 p-3 bg-yellow-50 border border-yellow-200 rounded">
              <AlertTriangle className="h-4 w-4 text-yellow-600" />
              <p className="text-sm text-yellow-800">
                Algunos ingredientes no tienen auto-descuento activado. Se deberán descontar manualmente.
              </p>
            </div>
          )}
        </div>

        {/* Acciones */}
        <div className="flex gap-2 pt-4">
          <Button variant="outline" onClick={onClose} className="flex-1">
            Cancelar
          </Button>
          <Button onClick={handleSave} className="flex-1 bg-green-600 hover:bg-green-700">
            <Save className="h-4 w-4 mr-2" />
            Guardar Receta
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}