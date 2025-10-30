import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Badge } from './ui/badge';
import { Checkbox } from './ui/checkbox';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from './ui/dialog';
import { Separator } from './ui/separator';
import { toast } from 'sonner@2.0.3';
import { 
  ChefHat, 
  Plus, 
  Trash2, 
  AlertTriangle,
  Package,
  Settings,
  GripVertical
} from 'lucide-react';

interface Ingredient {
  id: string;
  name: string;
  unit: string;
  quantity: number;
  autoConsume: boolean;
  isCustom?: boolean;
}

interface Product {
  id: string;
  name: string;
  category: number;
  recipe?: Ingredient[];
}

// Ingredientes sugeridos por categoría (específicos para barbacoa mexicana)
const categoryIngredients: Record<number, Array<{ id: string; name: string; unit: string }>> = {
  1: [ // Tacos
    { id: 'carne-barbacoa', name: 'Carne de barbacoa', unit: 'g' },
    { id: 'cebolla-blanca', name: 'Cebolla blanca', unit: 'g' },
    { id: 'cilantro', name: 'Cilantro', unit: 'g' },
    { id: 'tortilla-maiz', name: 'Tortilla de maíz', unit: 'pzs' },
    { id: 'salsa-roja', name: 'Salsa roja', unit: 'ml' },
    { id: 'salsa-verde', name: 'Salsa verde', unit: 'ml' },
    { id: 'limon', name: 'Limón', unit: 'pzs' },
  ],
  2: [ // Platos Especiales
    { id: 'carne-barbacoa', name: 'Carne de barbacoa', unit: 'g' },
    { id: 'arroz-rojo', name: 'Arroz rojo', unit: 'g' },
    { id: 'frijoles-charros', name: 'Frijoles charros', unit: 'g' },
    { id: 'tortillas-harina', name: 'Tortillas de harina', unit: 'pzs' },
    { id: 'nopales', name: 'Nopales', unit: 'g' },
    { id: 'guacamole', name: 'Guacamole', unit: 'g' },
  ],
  3: [ // Acompañamientos
    { id: 'arroz-rojo', name: 'Arroz rojo', unit: 'g' },
    { id: 'frijoles-charros', name: 'Frijoles charros', unit: 'g' },
    { id: 'nopales', name: 'Nopales', unit: 'g' },
    { id: 'guacamole', name: 'Guacamole', unit: 'g' },
    { id: 'cebollitas-cambray', name: 'Cebollitas cambray', unit: 'pzs' },
  ],
  4: [ // Bebidas
    { id: 'agua-fresca', name: 'Agua fresca', unit: 'ml' },
    { id: 'agua-jamaica', name: 'Agua de jamaica', unit: 'ml' },
    { id: 'agua-horchata', name: 'Agua de horchata', unit: 'ml' },
    { id: 'refresco', name: 'Refresco', unit: 'ml' },
    { id: 'cerveza', name: 'Cerveza', unit: 'ml' },
    { id: 'hielo', name: 'Hielo', unit: 'g' },
  ],
  5: [ // Extras
    { id: 'queso-fresco', name: 'Queso fresco', unit: 'g' },
    { id: 'crema', name: 'Crema', unit: 'ml' },
    { id: 'aguacate', name: 'Aguacate', unit: 'g' },
    { id: 'cebolla-morada', name: 'Cebolla morada', unit: 'g' },
  ],
  6: [ // Consomes
    { id: 'caldo-barbacoa', name: 'Caldo de barbacoa', unit: 'ml' },
    { id: 'carne-barbacoa', name: 'Carne de barbacoa', unit: 'g' },
    { id: 'garbanzos', name: 'Garbanzos', unit: 'g' },
    { id: 'verdolagas', name: 'Verdolagas', unit: 'g' },
    { id: 'xoconostle', name: 'Xoconostle', unit: 'pzs' },
  ]
};

const categoryNames: Record<number, string> = {
  1: 'Tacos',
  2: 'Platos Especiales', 
  3: 'Acompañamientos',
  4: 'Bebidas',
  5: 'Extras',
  6: 'Consomes'
};

interface EnhancedInventoryRecipeProps {
  product: Product;
  onSave: (product: Product) => void;
  onClose: () => void;
}

export function EnhancedInventoryRecipe({ product, onSave, onClose }: EnhancedInventoryRecipeProps) {
  const [recipe, setRecipe] = useState<Ingredient[]>(product?.recipe || []);
  const [showAddIngredient, setShowAddIngredient] = useState(false);
  const [newIngredient, setNewIngredient] = useState({
    selectedId: '',
    quantity: 0,
    autoConsume: true
  });
  const [customIngredient, setCustomIngredient] = useState({
    name: '',
    unit: '',
    quantity: 0,
    autoConsume: true
  });
  const [showCustomInput, setShowCustomInput] = useState(false);

  const getSuggestedIngredients = () => {
    return categoryIngredients[product?.category ?? 1] || [];
  };

  const getAvailableIngredients = () => {
    const suggested = getSuggestedIngredients();
    return suggested.filter(ing => !recipe.some(r => r.id === ing.id));
  };

  const addSuggestedIngredient = () => {
    const selectedIngredient = getSuggestedIngredients().find(ing => ing.id === newIngredient.selectedId);
    if (!selectedIngredient || newIngredient.quantity <= 0) return;

    const ingredient: Ingredient = {
      id: selectedIngredient.id,
      name: selectedIngredient.name,
      unit: selectedIngredient.unit,
      quantity: newIngredient.quantity,
      autoConsume: newIngredient.autoConsume,
      isCustom: false
    };

    setRecipe(prev => [...prev, ingredient]);
    setNewIngredient({ selectedId: '', quantity: 0, autoConsume: true });
    setShowAddIngredient(false);
  };

  const addCustomIngredient = () => {
    if (!customIngredient.name || !customIngredient.unit || customIngredient.quantity <= 0) return;

    const ingredient: Ingredient = {
      id: `custom-${Date.now()}`,
      name: customIngredient.name,
      unit: customIngredient.unit,
      quantity: customIngredient.quantity,
      autoConsume: customIngredient.autoConsume,
      isCustom: true
    };

    setRecipe(prev => [...prev, ingredient]);
    setCustomIngredient({ name: '', unit: '', quantity: 0, autoConsume: true });
    setShowCustomInput(false);
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
    toast.success(`Receta guardada para ${product?.name}`);
    onClose();
  };

  const calculateTotalCost = () => {
    // Mock de cálculo de costo - en producción vendría de precios de inventario
    return recipe.reduce((total, ing) => {
      // Costos base ajustados para ingredientes de barbacoa mexicana
      let baseCost = 0.05; // Costo base por defecto
      
      if (ing.id.includes('carne-barbacoa')) baseCost = 0.12;
      else if (ing.id.includes('queso')) baseCost = 0.08;
      else if (ing.id.includes('aguacate') || ing.id.includes('guacamole')) baseCost = 0.10;
      else if (ing.id.includes('tortilla')) baseCost = 0.03;
      else if (ing.id.includes('cerveza')) baseCost = 0.15;
      else if (ing.id.includes('refresco')) baseCost = 0.08;
      
      return total + (ing.quantity * baseCost);
    }, 0);
  };

  const categoryName = categoryNames[product?.category ?? 1] || 'Sin categoría';

  return (
    <Dialog open={true} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-xl lg:max-w-2xl xl:max-w-3xl max-h-[85vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <ChefHat className="h-5 w-5" />
            Receta / Ingredientes — {product?.name}
          </DialogTitle>
          <DialogDescription>
            Configura los ingredientes y cantidades necesarios para este producto
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* Información del producto */}
          <Card className="border-amber-200 bg-amber-50">
            <CardContent className="p-4">
              <div className="flex justify-between items-center">
                <div>
                  <h4 className="font-medium text-amber-900">{product?.name}</h4>
                  <p className="text-sm text-amber-700">Categoría: {categoryName}</p>
                  <Badge className="mt-1 bg-blue-100 text-blue-800 border-blue-300 text-xs">
                    Sugerencias basadas en categoría: {categoryName}
                  </Badge>
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
                Especifica la cantidad exacta que se consume por porción. Los ingredientes sugeridos se basan en la categoría del producto.
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
                  <GripVertical className="h-4 w-4 text-blue-600 cursor-move" />
                  
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <span className="font-medium text-blue-900">{ingredient.name}</span>
                      {ingredient.isCustom && (
                        <Badge className="bg-purple-100 text-purple-800 border-purple-300 text-xs">
                          Personalizado
                        </Badge>
                      )}
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
                      placeholder="ej. 30 g"
                    />
                    <span className="text-sm text-blue-700 w-8">{ingredient.unit}</span>
                  </div>

                  <Checkbox
                    checked={ingredient.autoConsume}
                    onCheckedChange={(checked) => updateIngredient(ingredient.id, 'autoConsume', checked)}
                  />
                  <Label className="text-xs text-blue-700">Descontar automáticamente</Label>

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
                <div className="p-4 bg-gray-50 border border-gray-200 rounded space-y-4">
                  <div className="flex items-center justify-between">
                    <h4 className="font-medium text-gray-900">+ Agregar ingrediente</h4>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => {
                        setShowAddIngredient(false);
                        setShowCustomInput(false);
                      }}
                      className="text-gray-500"
                    >
                      ×
                    </Button>
                  </div>

                  {!showCustomInput ? (
                    <>
                      {/* Ingredientes sugeridos */}
                      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                        <div className="sm:col-span-1">
                          <Label className="text-gray-700">Ingrediente sugerido</Label>
                          <Select 
                            value={newIngredient.selectedId} 
                            onValueChange={(value) => setNewIngredient(prev => ({...prev, selectedId: value}))}
                          >
                            <SelectTrigger className="border-gray-300">
                              <SelectValue placeholder="Seleccionar..." />
                            </SelectTrigger>
                            <SelectContent>
                              {getAvailableIngredients().map(item => (
                                <SelectItem key={item.id} value={item.id}>
                                  {item.name} ({item.unit})
                                </SelectItem>
                              ))}
                            </SelectContent>
                          </Select>
                        </div>

                        <div>
                          <Label className="text-gray-700">Cantidad por porción</Label>
                          <Input
                            type="number"
                            value={newIngredient.quantity}
                            onChange={(e) => setNewIngredient(prev => ({...prev, quantity: parseFloat(e.target.value) || 0}))}
                            className="border-gray-300"
                            min="0"
                            step="0.1"
                            placeholder="ej. 30 g"
                          />
                        </div>

                        <div className="flex items-end">
                          <div className="flex items-center space-x-2">
                            <Checkbox
                              checked={newIngredient.autoConsume}
                              onCheckedChange={(checked) => setNewIngredient(prev => ({...prev, autoConsume: checked}))}
                            />
                            <Label className="text-xs text-gray-700">Descontar automáticamente</Label>
                          </div>
                        </div>
                      </div>

                      <div className="flex gap-2">
                        <Button
                          size="sm"
                          onClick={addSuggestedIngredient}
                          disabled={!newIngredient.selectedId || newIngredient.quantity <= 0}
                          className="bg-blue-600 hover:bg-blue-700"
                        >
                          <Plus className="h-3 w-3 mr-1" />
                          Agregar
                        </Button>
                        
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => setShowCustomInput(true)}
                          className="border-purple-300 text-purple-700 hover:bg-purple-50"
                        >
                          Agregar ingrediente personalizado
                        </Button>
                      </div>
                    </>
                  ) : (
                    <>
                      {/* Ingrediente personalizado */}
                      <div className="grid grid-cols-1 sm:grid-cols-4 gap-3">
                        <div>
                          <Label className="text-gray-700">Nombre</Label>
                          <Input
                            value={customIngredient.name}
                            onChange={(e) => setCustomIngredient(prev => ({...prev, name: e.target.value}))}
                            className="border-gray-300"
                            placeholder="Ej: Aceite"
                          />
                        </div>

                        <div>
                          <Label className="text-gray-700">Unidad</Label>
                          <Input
                            value={customIngredient.unit}
                            onChange={(e) => setCustomIngredient(prev => ({...prev, unit: e.target.value}))}
                            className="border-gray-300"
                            placeholder="Ej: ml"
                          />
                        </div>

                        <div>
                          <Label className="text-gray-700">Cantidad</Label>
                          <Input
                            type="number"
                            value={customIngredient.quantity}
                            onChange={(e) => setCustomIngredient(prev => ({...prev, quantity: parseFloat(e.target.value) || 0}))}
                            className="border-gray-300"
                            min="0"
                            step="0.1"
                            placeholder="ej. 30"
                          />
                        </div>

                        <div className="flex items-end">
                          <div className="flex items-center space-x-2">
                            <Checkbox
                              checked={customIngredient.autoConsume}
                              onCheckedChange={(checked) => setCustomIngredient(prev => ({...prev, autoConsume: checked}))}
                            />
                            <Label className="text-xs text-gray-700">Auto</Label>
                          </div>
                        </div>
                      </div>

                      <div className="flex gap-2">
                        <Button
                          size="sm"
                          onClick={addCustomIngredient}
                          disabled={!customIngredient.name || !customIngredient.unit || customIngredient.quantity <= 0}
                          className="bg-purple-600 hover:bg-purple-700"
                        >
                          <Plus className="h-3 w-3 mr-1" />
                          Agregar personalizado
                        </Button>
                        
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => setShowCustomInput(false)}
                          className="border-gray-300"
                        >
                          Volver a sugeridos
                        </Button>
                      </div>
                    </>
                  )}
                </div>
              )}

              {!showAddIngredient && (
                <Button
                  variant="outline"
                  onClick={() => setShowAddIngredient(true)}
                  className="w-full border-blue-300 text-blue-700 hover:bg-blue-50"
                >
                  <Plus className="h-4 w-4 mr-2" />
                  + Agregar ingrediente
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
                      <div className="flex gap-2">
                        {ingredient.isCustom && (
                          <Badge className="bg-purple-100 text-purple-800 border-purple-300 text-xs">
                            Personalizado
                          </Badge>
                        )}
                        {ingredient.autoConsume && (
                          <Badge className="bg-green-100 text-green-800 border-green-300 text-xs">
                            Se descontará automáticamente
                          </Badge>
                        )}
                      </div>
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
            <Settings className="h-4 w-4 mr-2" />
            Guardar Receta
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}