import React, { useState } from 'react';
import { Button } from '../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Separator } from '../ui/separator';
import { Switch } from '../ui/switch';
import { ArrowLeft, Trash2, Users, Receipt, Send, Clock, Flame, Package } from 'lucide-react';

export function CartView({ table, items, onBack, onRemoveItem, onClearCart, onSendToKitchen }) {
  const [splitBetween, setSplitBetween] = useState(1);
  const [discount, setDiscount] = useState(0);
  const [isTakeaway, setIsTakeaway] = useState(false);
  const [customerName, setCustomerName] = useState('');
  const [customerPhone, setCustomerPhone] = useState('');
  const [pickupTime, setPickupTime] = useState('');

  const subtotal = items.reduce((sum, item) => sum + item.price, 0);
  const discountAmount = subtotal * (discount / 100);
  const subtotalAfterDiscount = subtotal - discountAmount;
  const total = subtotalAfterDiscount;
  const perPerson = splitBetween > 1 ? total / splitBetween : total;

  const getEstimatedTime = () => {
    const hasHotItems = items.some(item => item.hot);
    return hasHotItems ? '15-20 min' : '5-8 min';
  };

  const handleSendToKitchen = () => {
    // Validar campos obligatorios para takeaway
    if (isTakeaway && !customerName.trim()) {
      alert('Por favor ingresa el nombre del cliente para el pedido solo para llevar');
      return;
    }

    const orderData = {
      table: table,
      items: items,
      total: total,
      discount: discountAmount,
      isTakeaway: isTakeaway,
      customerName: isTakeaway ? customerName.trim() : null,
      customerPhone: isTakeaway && customerPhone.trim() ? customerPhone.trim() : null,
      pickupTime: isTakeaway && pickupTime ? pickupTime : 'Ahora',
      timestamp: new Date()
    };

    if (onSendToKitchen) {
      onSendToKitchen(orderData);
    } else {
      // Fallback si no se pasa la función
      if (isTakeaway) {
        alert(`¡Pedido solo para llevar enviado a cocina!\nCliente: ${customerName}`);
      } else {
        alert('¡Pedido enviado a cocina! 🔥');
      }
    }
  };

  const handleGenerateBill = () => {
    // Generar cuenta para cobro en efectivo únicamente
    const billData = {
      tableNumber: table.number,
      items: items,
      subtotal: subtotalAfterDiscount,
      tip: 0,
      discount: discountAmount,
      total: total,
      splitBetween: splitBetween,
      timestamp: new Date(),
      paymentMethod: 'efectivo' // Solo efectivo
    };
    
    alert(`Cuenta generada - Total: $${total.toFixed(2)}\nSe enviará a caja para cobro en EFECTIVO únicamente`);
    // Aquí se enviaría la cuenta al sistema de caja
  };

  const quickDiscountOptions = [0, 5, 10, 15];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="sm" onClick={onBack} className="text-amber-700 hover:bg-amber-100">
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <div>
          <h2 className="text-xl font-medium text-amber-900">Pedido Mesa {table.number}</h2>
          <p className="text-sm text-amber-700">
            {items.length} {items.length === 1 ? 'artículo' : 'artículos'}
          </p>
        </div>
      </div>

      {items.length === 0 ? (
        <Card className="border-amber-200">
          <CardContent className="p-8 text-center">
            <div className="text-amber-700">
              <Receipt className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>No hay artículos en el pedido</p>
              <p className="text-sm">Agrega productos desde el menú</p>
            </div>
          </CardContent>
        </Card>
      ) : (
        <>
          {/* Lista de artículos */}
          <Card className="border-amber-200">
            <CardHeader>
              <CardTitle className="flex justify-between items-center text-amber-900">
                <span>Artículos del Pedido</span>
                <Button 
                  variant="ghost" 
                  size="sm" 
                  onClick={onClearCart}
                  className="text-red-600 hover:text-red-700 hover:bg-red-100"
                >
                  <Trash2 className="h-4 w-4" />
                  Limpiar Todo
                </Button>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              {items.map((item, index) => (
                <div key={index} className="space-y-3">
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <h4 className="font-medium text-amber-900">
                          {item.name}
                          {item.customizations && item.customizations.size && (
                            <span className="text-amber-700"> • {item.customizations.size}</span>
                          )}
                        </h4>
                        {item.hot && <Flame className="h-3 w-3 text-red-500" />}
                        {item.spicy && <span className="text-xs">🌶️</span>}
                      </div>
                      {item.customizations && (
                        <div className="text-sm text-amber-700 space-y-1 mt-1">
                          {item.customizations.quantity > 1 && (
                            <div>Cantidad: {item.customizations.quantity}</div>
                          )}
                          {item.customizations.options && Object.entries(item.customizations.options).map(([key, option]) => (
                            <div key={key}>
                              {key === 'portions' ? 'Porción' : key}: {option.name}
                              {option.price !== 0 && (
                                <span className={option.price > 0 ? "text-orange-600" : "text-green-600"}>
                                  {option.price > 0 ? ' (+$' : ' (-$'}{Math.abs(option.price)})
                                </span>
                              )}
                            </div>
                          ))}
                          {item.customizations.extras && item.customizations.extras.length > 0 && (
                            <div>Extras: {item.customizations.extras.join(', ')}</div>
                          )}
                          {item.customizations.salsa && (
                            <div>Salsa: {item.customizations.salsa.replace('salsa-', '').replace('-', ' ')}</div>
                          )}
                          {item.customizations.size && (
                            <div>Tamaño: {item.customizations.size}</div>
                          )}
                          {item.customizations.notes && (
                            <div className="italic text-amber-600">Nota: {item.customizations.notes}</div>
                          )}
                        </div>
                      )}
                    </div>
                    <div className="flex items-center gap-2 ml-4">
                      <span className="font-medium text-orange-600">${item.price}</span>
                      <Button 
                        variant="ghost" 
                        size="sm"
                        onClick={() => onRemoveItem(item.id)}
                        className="text-red-600 hover:text-red-700 hover:bg-red-100"
                      >
                        <Trash2 className="h-3 w-3" />
                      </Button>
                    </div>
                  </div>
                  {index < items.length - 1 && <Separator className="border-amber-200" />}
                </div>
              ))}
            </CardContent>
          </Card>

          {/* Descuento */}
          <Card className="border-amber-200">
            <CardHeader>
              <CardTitle className="text-amber-900">Descuento</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex gap-2">
                {quickDiscountOptions.map(percentage => (
                  <Button
                    key={percentage}
                    variant={discount === percentage ? "default" : "outline"}
                    size="sm"
                    onClick={() => setDiscount(percentage)}
                    className="flex-1 border-amber-300 data-[state=active]:bg-amber-600"
                  >
                    {percentage}%
                  </Button>
                ))}
              </div>
              <div className="flex items-center gap-2">
                <Label htmlFor="custom-discount" className="text-amber-900">Descuento personalizado (%):</Label>
                <Input
                  id="custom-discount"
                  type="number"
                  value={discount}
                  onChange={(e) => setDiscount(parseFloat(e.target.value) || 0)}
                  className="w-20 border-amber-200 focus:border-amber-500"
                  min="0"
                  max="50"
                />
              </div>
            </CardContent>
          </Card>

          {/* Pedido para llevar */}
          <Card className="border-amber-200">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-amber-900">
                <Package className="h-4 w-4" />
                ¿Solo para llevar?
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <Label htmlFor="takeaway-toggle" className="text-amber-900">
                  ¿Solo para llevar?
                </Label>
                <Switch
                  id="takeaway-toggle"
                  checked={isTakeaway}
                  onCheckedChange={setIsTakeaway}
                />
              </div>
              
              {isTakeaway && (
                <div className="space-y-4 pt-2 border-t border-amber-200">
                  <div className="space-y-2">
                    <Label htmlFor="customer-name" className="text-amber-900">
                      A nombre de <span className="text-red-500">*</span>
                    </Label>
                    <Input
                      id="customer-name"
                      type="text"
                      value={customerName}
                      onChange={(e) => setCustomerName(e.target.value)}
                      placeholder="Nombre del cliente (ej. Jahir)"
                      className="border-amber-200 focus:border-amber-500"
                      required={isTakeaway}
                    />
                  </div>
                  
                  <div className="space-y-2">
                    <Label htmlFor="customer-phone" className="text-amber-900">
                      Teléfono (opcional)
                    </Label>
                    <Input
                      id="customer-phone"
                      type="tel"
                      value={customerPhone}
                      onChange={(e) => setCustomerPhone(e.target.value)}
                      placeholder="55 1234 5678"
                      className="border-amber-200 focus:border-amber-500"
                    />
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* División de cuenta */}
          {!isTakeaway && (
            <Card className="border-amber-200">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-amber-900">
                  <Users className="h-4 w-4" />
                  División de Cuenta
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="flex items-center gap-4">
                  <Label htmlFor="split" className="text-amber-900">Dividir entre:</Label>
                  <div className="flex items-center gap-2">
                    <Button 
                      variant="outline" 
                      size="sm"
                      onClick={() => setSplitBetween(Math.max(1, splitBetween - 1))}
                      disabled={splitBetween <= 1}
                      className="border-amber-300 text-amber-700 hover:bg-amber-100"
                    >
                      -
                    </Button>
                    <Input
                      id="split"
                      type="number"
                      value={splitBetween}
                      onChange={(e) => setSplitBetween(Math.max(1, parseInt(e.target.value) || 1))}
                      className="w-16 text-center border-amber-200 focus:border-amber-500"
                      min="1"
                    />
                    <Button 
                      variant="outline" 
                      size="sm"
                      onClick={() => setSplitBetween(splitBetween + 1)}
                      className="border-amber-300 text-amber-700 hover:bg-amber-100"
                    >
                      +
                    </Button>
                    <span className="text-sm text-amber-700">
                      {splitBetween === 1 ? 'persona' : 'personas'}
                    </span>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Resumen de totales */}
          <Card className="bg-amber-50 border-amber-300">
            <CardContent className="p-4 space-y-3">
              <div className="flex justify-between text-amber-900">
                <span>Subtotal:</span>
                <span>${subtotal.toFixed(2)}</span>
              </div>
              {discount > 0 && (
                <div className="flex justify-between text-green-600">
                  <span>Descuento ({discount}%):</span>
                  <span>-${discountAmount.toFixed(2)}</span>
                </div>
              )}
              <Separator className="border-amber-300" />
              <div className="flex justify-between font-medium text-lg text-amber-900">
                <span>Total:</span>
                <span className="text-orange-600">${total.toFixed(2)}</span>
              </div>
              {splitBetween > 1 && (
                <div className="flex justify-between text-sm text-amber-700">
                  <span>Por persona:</span>
                  <span className="font-medium">${perPerson.toFixed(2)}</span>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Acciones */}
          <div className="space-y-3">
            <Button 
              onClick={handleSendToKitchen}
              className="w-full bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800 text-white shadow-md"
              size="lg"
            >
              <Send className="h-4 w-4 mr-2" />
              Enviar a Cocina
            </Button>
            
            <Button 
              variant="outline"
              onClick={handleGenerateBill}
              className="w-full border-orange-300 text-orange-700 hover:bg-orange-100"
              size="lg"
            >
              <Receipt className="h-4 w-4 mr-2" />
              Cerrar Mesa
            </Button>
          </div>
        </>
      )}
    </div>
  );
}