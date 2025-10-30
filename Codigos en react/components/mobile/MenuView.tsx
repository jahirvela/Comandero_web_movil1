import React, { useState } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { ArrowLeft, Search, Flame, Clock } from 'lucide-react';
import { ImageWithFallback } from '../figma/ImageWithFallback';
import { useMenu } from '../MenuContext';

const categories = [
  { id: 1, name: 'Tacos', icon: '🌮' },
  { id: 2, name: 'Platos Especiales', icon: '🍽️' },
  { id: 3, name: 'Acompañamientos', icon: '🥬' },
  { id: 4, name: 'Bebidas', icon: '🥤' },
  { id: 5, name: 'Extras', icon: '🌶️' },
  { id: 6, name: 'Consomes', icon: '🍲' }
];

export function MenuView({ onBack, onProductSelect }) {
  const { menuItems, syncNotification } = useMenu();
  const [selectedCategory, setSelectedCategory] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');

  console.log('📱 MenuView: Renderizando con', menuItems.length, 'productos');
  console.log('📱 MenuView: Productos disponibles:', menuItems.filter(item => item.available).length);

  // Filtrar solo productos disponibles para el mesero
  const availableMenuItems = menuItems.filter(item => item.available);

  const filteredItems = availableMenuItems.filter(item => {
    const matchesCategory = selectedCategory === 0 || item.category === selectedCategory;
    const matchesSearch = item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         item.description.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesCategory && matchesSearch;
  });

  const getCategoryName = (categoryId) => {
    return categories.find(cat => cat.id === categoryId)?.name || 'Sin categoría';
  };

  return (
    <div className="space-y-4 sm:space-y-6 lg:space-y-8">
      {/* Notificación de sincronización */}
      {syncNotification && (
        <div className="fixed top-4 right-4 z-50">
          <Badge className="bg-green-600 text-white shadow-lg animate-pulse text-xs sm:text-sm">
            ✅ Datos sincronizados
          </Badge>
        </div>
      )}

      {/* Header - Responsivo */}
      <div className="flex items-center gap-3 sm:gap-4 lg:gap-6">
        <Button variant="ghost" size="sm" onClick={onBack} className="text-amber-700 hover:bg-amber-100 p-2 sm:p-3">
          <ArrowLeft className="h-4 w-4 sm:h-5 sm:w-5" />
        </Button>
        <div>
          <h2 className="text-lg sm:text-xl lg:text-2xl font-medium text-amber-900">Menú Barbacoa</h2>
          <p className="text-sm sm:text-base lg:text-lg text-amber-700">Selecciona productos para la mesa</p>
        </div>
      </div>

      {/* Búsqueda - Mejorada para todas las pantallas */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-amber-500 h-4 w-4 sm:h-5 sm:w-5" />
        <Input
          placeholder="Buscar platillo, ej. 'barbacoa'"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="pl-10 sm:pl-12 lg:pl-14 border-amber-200 focus:border-amber-500 focus:ring-amber-500 h-10 sm:h-11 lg:h-12 text-sm sm:text-base"
        />
      </div>

      {/* Categorías - Mejorado scroll horizontal */}
      <div className="flex gap-2 sm:gap-3 lg:gap-4 overflow-x-auto pb-2 scrollbar-thin scrollbar-thumb-amber-300">
        <Button
          variant={selectedCategory === 0 ? "default" : "outline"}
          size="sm"
          onClick={() => setSelectedCategory(0)}
          className="whitespace-nowrap bg-amber-600 hover:bg-amber-700 border-amber-300 text-xs sm:text-sm lg:text-base px-3 py-2 sm:px-4 sm:py-2.5 lg:px-5 lg:py-3"
        >
          Todo el Menú
        </Button>
        {categories.map(category => (
          <Button
            key={category.id}
            variant={selectedCategory === category.id ? "default" : "outline"}
            size="sm"
            onClick={() => setSelectedCategory(category.id)}
            className="whitespace-nowrap bg-amber-600 hover:bg-amber-700 border-amber-300 text-xs sm:text-sm lg:text-base px-3 py-2 sm:px-4 sm:py-2.5 lg:px-5 lg:py-3"
          >
            <span className="text-sm sm:text-base lg:text-lg mr-1">{category.icon}</span>
            <span className="hidden sm:inline">{category.name}</span>
            <span className="sm:hidden">{category.name.split(' ')[0]}</span>
          </Button>
        ))}
      </div>

      {/* Especialidad del día */}
      <Card className="bg-gradient-to-r from-orange-100 to-red-100 border-orange-300">
        <CardContent className="p-4">
          <div className="flex items-center gap-3">
            <div className="text-2xl">🔥</div>
            <div>
              <h3 className="font-medium text-orange-900">Especialidad del Día</h3>
              <p className="text-sm text-orange-800">Mix Barbacoa con consomé - ¡Recién salido del horno!</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Lista de productos - Grid responsivo */}
      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-3 sm:gap-4 lg:gap-5">
        {filteredItems.map(item => (
          <Card 
            key={item.id} 
            className={`cursor-pointer transition-all duration-200 ${
              !item.available ? 'opacity-50' : 'hover:shadow-md hover:border-amber-300'
            } border-amber-200`}
            onClick={() => item.available && onProductSelect(item)}
          >
            <CardContent className="p-3 sm:p-4 lg:p-5">
              <div className="flex gap-3 sm:gap-4">
                {/* Imagen del producto - Responsiva */}
                <div className="w-16 h-16 sm:w-20 sm:h-20 lg:w-24 lg:h-24 bg-amber-50 rounded-lg flex-shrink-0 overflow-hidden border border-amber-200">
                  <ImageWithFallback
                    src={item.image || "https://images.unsplash.com/photo-1711989874705-bb85dc205541?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtZXhpY2FuJTIwYmFyYmFjb2ElMjB0YWNvcyUyMG1lYXR8ZW58MXx8fHwxNzU3NjI5MzY5fDA&ixlib=rb-4.1.0&q=80&w=1080"}
                    alt={item.name}
                    className="w-full h-full object-cover"
                  />
                </div>
                
                {/* Información del producto */}
                <div className="flex-1 min-w-0">
                  <div className="flex justify-between items-start mb-1 lg:mb-2">
                    <h3 className="font-medium truncate text-amber-900 text-sm sm:text-base lg:text-lg">{item.name}</h3>
                    <div className="flex items-center gap-2 ml-2">
                      <span className="font-medium text-orange-600 text-sm sm:text-base lg:text-lg">${item.price}</span>
                      {!item.available && (
                        <Badge variant="destructive" className="text-xs sm:text-sm">
                          Agotado
                        </Badge>
                      )}
                    </div>
                  </div>
                  
                  <p className="text-xs sm:text-sm lg:text-base text-amber-700 line-clamp-2 mb-2">
                    {item.description}
                  </p>
                  
                  {/* Badges de características */}
                  <div className="flex gap-1 flex-wrap">
                    {item.spicy && (
                      <Badge className="text-xs sm:text-sm bg-yellow-100 text-yellow-700 border-yellow-300">
                        🌶️ <span className="hidden sm:inline">Picante</span>
                      </Badge>
                    )}
                    {item.category === 2 && (
                      <Badge className="text-xs sm:text-sm bg-orange-100 text-orange-700 border-orange-300">
                        ⭐ <span className="hidden sm:inline">Especialidad</span>
                      </Badge>
                    )}
                    {item.category === 6 && item.has_sizes && (
                      <Badge className="text-xs sm:text-sm bg-blue-100 text-blue-700 border-blue-300">
                        📏 <span className="hidden sm:inline">Tamaños</span>
                      </Badge>
                    )}
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {filteredItems.length === 0 && (
        <div className="text-center py-8 text-amber-700">
          <div className="text-4xl mb-2">🔍</div>
          <p>No se encontraron productos</p>
          <p className="text-sm">Intenta con otros términos de búsqueda</p>
        </div>
      )}

      {/* Info del horario */}
      <Card className="bg-amber-50 border-amber-200">
        <CardContent className="p-3">
          <div className="flex items-center justify-center gap-2 text-sm text-amber-800">
            <Clock className="h-4 w-4" />
            <span>Barbacoa disponible hasta agotar existencias</span>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}