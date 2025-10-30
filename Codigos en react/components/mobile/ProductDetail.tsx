import React, { useState } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent } from '../ui/card';
import { Badge } from '../ui/badge';
import { Textarea } from '../ui/textarea';
import { Label } from '../ui/label';
import { Checkbox } from '../ui/checkbox';
import { RadioGroup, RadioGroupItem } from '../ui/radio-group';
import { ArrowLeft, Plus, Minus, Flame, Clock } from 'lucide-react';
import { ImageWithFallback } from '../figma/ImageWithFallback';
import { useMenu } from '../MenuContext';

const productCustomizations = {
  1: { // Taco de Barbacoa
    portions: [
      { id: 'single', name: '1 pieza', price: -11 },
      { id: 'double', name: '2 piezas (normal)', price: 0 },
      { id: 'triple', name: '3 piezas', price: 11 }
    ],
    extras: [
      { id: 'extra-meat', name: 'Carne extra', price: 15 },
      { id: 'grilled-onion', name: 'Cebolla asada', price: 5 },
      { id: 'curtida', name: 'Cebolla curtida', price: 3 },
      { id: 'cheese', name: 'Queso Oaxaca', price: 8 }
    ]
  },
  2: { // Taco de Maciza
    portions: [
      { id: 'single', name: '1 pieza', price: -12 },
      { id: 'double', name: '2 piezas (normal)', price: 0 },
      { id: 'triple', name: '3 piezas', price: 12 }
    ],
    extras: [
      { id: 'extra-meat', name: 'Carne extra', price: 18 },
      { id: 'grilled-onion', name: 'Cebolla asada', price: 5 },
      { id: 'cheese', name: 'Queso Oaxaca', price: 8 }
    ]
  },
  4: { // Mix Barbacoa
    extras: [
      { id: 'extra-taco', name: 'Taco adicional', price: 22 },
      { id: 'extra-consomé', name: 'Consomé extra', price: 15 },
      { id: 'tortillas', name: 'Tortillas extra (5 pzs)', price: 8 }
    ]
  },
  7: { // Tortillas
    portions: [
      { id: 'half', name: '5 tortillas', price: -8 },
      { id: 'normal', name: '10 tortillas (normal)', price: 0 },
      { id: 'extra', name: '15 tortillas', price: 8 }
    ]
  }
};

const salsaOptions = [
  { id: 'salsa-roja', name: 'Salsa roja (picante)', price: 0 },
  { id: 'salsa-verde', name: 'Salsa verde (medio)', price: 0 },
  { id: 'salsa-arbol', name: 'Chile de árbol (muy picante)', price: 3 },
  { id: 'sin-salsa', name: 'Sin salsa', price: 0 }
];

export function ProductDetail({ product, onBack, onAddToCart }) {
  const { syncNotification } = useMenu();
  const [quantity, setQuantity] = useState(1);
  const [selectedOptions, setSelectedOptions] = useState({});
  const [selectedExtras, setSelectedExtras] = useState([]);
  const [selectedSalsa, setSelectedSalsa] = useState('salsa-roja');
  const [selectedSize, setSelectedSize] = useState(
    product.category === 6 && product.sizes && product.sizes.length > 0 ? product.sizes[0].label : // Para Consomes, usar el primer tamaño disponible
    product.category === 4 && product.supports_sizes && product.sizes && product.sizes.length > 0 ? product.sizes[0].label : // Para bebidas con tamaños, usar el primer tamaño
    '' 
  );
  const [notes, setNotes] = useState('');

  const customizations = productCustomizations[product.id] || {};

  const calculatePrice = () => {
    let basePrice = product.price * quantity;
    
    // Para Consomes (categoría 6), usar precio específico del tamaño seleccionado
    if (product.category === 6 && selectedSize && product.sizes) {
      const selectedSizeData = product.sizes.find(size => size.label === selectedSize);
      if (selectedSizeData) {
        basePrice = selectedSizeData.price * quantity;
      }
    }
    
    // Para bebidas (categoría 4) con soporte de tamaños
    if (product.category === 4 && product.supports_sizes && selectedSize && product.sizes) {
      const selectedSizeData = product.sizes.find(size => size.label === selectedSize);
      if (selectedSizeData) {
        basePrice = selectedSizeData.price * quantity;
      }
    }
    
    // Agregar precio de opciones seleccionadas
    Object.values(selectedOptions).forEach(option => {
      if (option && option.price) {
        basePrice += option.price * quantity;
      }
    });
    
    // Agregar precio de extras
    selectedExtras.forEach(extraId => {
      const extra = Object.values(customizations).flat().find(item => item.id === extraId);
      if (extra && extra.price) {
        basePrice += extra.price * quantity;
      }
    });
    
    // Agregar precio de salsa
    const salsaOption = salsaOptions.find(s => s.id === selectedSalsa);
    if (salsaOption && salsaOption.price > 0) {
      basePrice += salsaOption.price * quantity;
    }
    
    return basePrice;
  };

  const handleAddToCart = () => {
    // Validar que se seleccione tamaño para Consomes
    if (product.category === 6 && !selectedSize) {
      alert('Por favor selecciona un tamaño para este Consomé');
      return;
    }
    
    // Validar que se seleccione tamaño para bebidas que soportan tamaños
    if (product.category === 4 && product.supports_sizes && !selectedSize) {
      alert('Por favor selecciona un tamaño para esta bebida');
      return;
    }
    
    const customizationsData = {
      quantity,
      options: selectedOptions,
      extras: selectedExtras,
      salsa: selectedSalsa,
      size: selectedSize, // Añadir tamaño seleccionado
      notes: notes.trim(),
      price: calculatePrice()
    };
    
    onAddToCart({...product, price: calculatePrice()}, customizationsData);
    onBack();
  };

  const handleOptionChange = (optionType, option) => {
    setSelectedOptions(prev => ({
      ...prev,
      [optionType]: option
    }));
  };

  const handleExtraChange = (extraId, checked) => {
    if (checked) {
      setSelectedExtras(prev => [...prev, extraId]);
    } else {
      setSelectedExtras(prev => prev.filter(id => id !== extraId));
    }
  };

  const estimatedTime = product.hot ? '8-12 min' : '2-3 min';

  return (
    <div className="space-y-6">
      {/* Notificación de sincronización */}
      {syncNotification && (
        <div className="fixed top-4 right-4 z-50">
          <Badge className="bg-green-600 text-white shadow-lg animate-pulse">
            ✅ Datos sincronizados
          </Badge>
        </div>
      )}

      {/* Header */}
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="sm" onClick={onBack} className="text-amber-700 hover:bg-amber-100">
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <div>
          <h2 className="text-xl font-medium text-amber-900">{product.name}</h2>
          <p className="text-sm text-amber-700">Personaliza tu orden</p>
        </div>
      </div>

      {/* Imagen y descripción */}
      <Card className="border-amber-200">
        <CardContent className="p-4">
          <div className="space-y-4">
            <div className="w-full h-48 bg-amber-50 rounded-lg overflow-hidden border border-amber-200">
              <ImageWithFallback
                src={product.image || "https://images.unsplash.com/photo-1711989874705-bb85dc205541?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtZXhpY2FuJTIwYmFyYmFjb2ElMjB0YWNvcyUyMG1lYXR8ZW58MXx8fHwxNzU3NjI5MzY5fDA&ixlib=rb-4.1.0&q=80&w=1080"}
                alt={product.name}
                className="w-full h-full object-cover"
              />
            </div>
            <div>
              <div className="flex justify-between items-center mb-2">
                <h3 className="text-lg font-medium text-amber-900">{product.name}</h3>
                <Badge className="bg-orange-100 text-orange-800 border-orange-300">
                  ${product.price}
                </Badge>
              </div>
              <p className="text-amber-700 mb-3">{product.description}</p>
              
              {/* Mostrar tamaño seleccionado si aplica */}
              {product.category === 6 && product.selectedSize && (
                <div className="mb-3">
                  <span className="text-sm font-medium text-amber-800">
                    Tamaño seleccionado: {product.selectedSize}
                  </span>
                </div>
              )}
              
              {/* Características del producto */}
              <div className="flex gap-2 flex-wrap">
                {product.spicy && (
                  <Badge className="text-xs bg-yellow-100 text-yellow-700 border-yellow-300">
                    🌶️ Picante
                  </Badge>
                )}
                <Badge className="text-xs bg-blue-100 text-blue-700 border-blue-300">
                  <Clock className="h-3 w-3 mr-1" />
                  {estimatedTime}
                </Badge>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Cantidad */}
      <Card className="border-amber-200">
        <CardContent className="p-4">
          <Label className="text-base font-medium text-amber-900">Cantidad</Label>
          <div className="flex items-center gap-3 mt-2">
            <Button 
              variant="outline" 
              size="sm"
              onClick={() => setQuantity(Math.max(1, quantity - 1))}
              disabled={quantity <= 1}
              className="border-amber-300 text-amber-700 hover:bg-amber-100"
            >
              <Minus className="h-4 w-4" />
            </Button>
            <span className="text-lg font-medium px-4 text-amber-900">{quantity}</span>
            <Button 
              variant="outline" 
              size="sm"
              onClick={() => setQuantity(quantity + 1)}
              className="border-amber-300 text-amber-700 hover:bg-amber-100"
            >
              <Plus className="h-4 w-4" />
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Selección de tamaño para Consomes */}
      {product.category === 6 && product.sizes && product.sizes.length > 0 && (
        <Card className="border-amber-200">
          <CardContent className="p-4">
            <Label className="text-base font-medium text-amber-900 mb-3 block">
              Selecciona tamaño: Chico / Mediano / Grande
            </Label>
            <RadioGroup value={selectedSize} onValueChange={setSelectedSize}>
              {product.sizes.map(size => (
                <div key={size.id} className="flex items-center space-x-2">
                  <RadioGroupItem value={size.label} id={`consomé-${size.id}`} className="border-amber-300 text-amber-600" />
                  <Label htmlFor={`consomé-${size.id}`} className="flex-1 cursor-pointer text-amber-900">
                    <div className="flex justify-between">
                      <span>{size.label}</span>
                      <span className="text-orange-600">${size.price}</span>
                    </div>
                  </Label>
                </div>
              ))}
            </RadioGroup>
          </CardContent>
        </Card>
      )}

      {/* Selección de tamaño para bebidas que soportan tamaños */}
      {product.category === 4 && product.supports_sizes && product.sizes && product.sizes.length > 0 && (
        <Card className="border-amber-200">
          <CardContent className="p-4">
            <Label className="text-base font-medium text-amber-900 mb-3 block">
              Selecciona tamaño:
            </Label>
            <RadioGroup value={selectedSize} onValueChange={setSelectedSize}>
              {product.sizes.map(size => (
                <div key={size.id} className="flex items-center space-x-2">
                  <RadioGroupItem value={size.label} id={`size-${size.id}`} className="border-amber-300 text-amber-600" />
                  <Label htmlFor={`size-${size.id}`} className="flex-1 cursor-pointer text-amber-900">
                    <div className="flex justify-between">
                      <span>{size.label}</span>
                      <span className="text-orange-600">${size.price}</span>
                    </div>
                  </Label>
                </div>
              ))}
            </RadioGroup>
          </CardContent>
        </Card>
      )}

      {/* Extras del producto */}
      {customizations.extras && product.supports_extras && (
        <Card className="border-amber-200">
          <CardContent className="p-4">
            <Label className="text-base font-medium mb-3 block text-amber-900">
              Ingredientes extra
            </Label>
            
            <div className="space-y-2">
              {customizations.extras.map(option => (
                <div key={option.id} className="flex items-center space-x-2">
                  <Checkbox
                    id={option.id}
                    checked={selectedExtras.includes(option.id)}
                    onCheckedChange={(checked) => handleExtraChange(option.id, checked)}
                    className="border-amber-300 data-[state=checked]:bg-amber-600"
                  />
                  <Label htmlFor={option.id} className="flex-1 cursor-pointer text-amber-900">
                    <div className="flex justify-between">
                      <span>{option.name}</span>
                      {option.price > 0 && (
                        <span className="text-orange-600">+${option.price}</span>
                      )}
                    </div>
                  </Label>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Selección de salsa - Solo para productos que soportan salsas */}
      {product.supports_salsas && (
        <Card className="border-amber-200">
          <CardContent className="p-4">
            <Label className="text-base font-medium text-amber-900 mb-3 block">
              Salsas (incluida)
            </Label>
            <RadioGroup value={selectedSalsa} onValueChange={setSelectedSalsa}>
              {salsaOptions.map(salsa => (
                <div key={salsa.id} className="flex items-center space-x-2">
                  <RadioGroupItem value={salsa.id} id={salsa.id} className="border-amber-300 text-amber-600" />
                  <Label htmlFor={salsa.id} className="flex-1 cursor-pointer text-amber-900">
                    <div className="flex justify-between">
                      <span>{salsa.name}</span>
                      {salsa.price > 0 && (
                        <span className="text-orange-600">+${salsa.price}</span>
                      )}
                    </div>
                  </Label>
                </div>
              ))}
            </RadioGroup>
          </CardContent>
        </Card>
      )}

      {/* Opciones de bebida - Solo para bebidas */}
      {product.category === 4 && (
        <Card className="border-amber-200">
          <CardContent className="p-4">
            <Label className="text-base font-medium text-amber-900 mb-3 block">
              Temperatura / Hielo
            </Label>
            <RadioGroup value={selectedSalsa} onValueChange={setSelectedSalsa}>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="con-hielo" id="con-hielo" className="border-amber-300 text-amber-600" />
                <Label htmlFor="con-hielo" className="flex-1 cursor-pointer text-amber-900">
                  ¿Con hielo? (Fría)
                </Label>
              </div>
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="sin-hielo" id="sin-hielo" className="border-amber-300 text-amber-600" />
                <Label htmlFor="sin-hielo" className="flex-1 cursor-pointer text-amber-900">
                  Sin hielo (Al tiempo)
                </Label>
              </div>
            </RadioGroup>
          </CardContent>
        </Card>
      )}

      {/* Notas especiales */}
      <Card className="border-amber-200">
        <CardContent className="p-4">
          <Label htmlFor="notes" className="text-base font-medium text-amber-900">
            Notas para cocina
          </Label>
          <Textarea
            id="notes"
            placeholder="Ej: sin cilantro, extra picante, tortilla doradita"
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            className="mt-2 border-amber-200 focus:border-amber-500 focus:ring-amber-500"
            rows={3}
          />
        </CardContent>
      </Card>

      {/* Resumen y agregar */}
      <Card className="bg-gradient-to-r from-orange-50 to-amber-50 border-orange-300">
        <CardContent className="p-4">
          <div className="flex justify-between items-center mb-4">
            <span className="text-lg font-medium text-amber-900">Total:</span>
            <span className="text-2xl font-medium text-orange-600">
              ${calculatePrice()}
            </span>
          </div>
          <div className="text-sm text-amber-700 mb-4">
            <div className="flex justify-between">
              <span>Tiempo estimado:</span>
              <span className="font-medium">{estimatedTime}</span>
            </div>
          </div>
          <Button 
            onClick={handleAddToCart}
            className="w-full bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-700 hover:to-orange-700 text-white shadow-md"
            size="lg"
          >
            Agregar al Pedido
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}