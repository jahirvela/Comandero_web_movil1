import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Separator } from '../ui/separator';
import { Badge } from '../ui/badge';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '../ui/alert-dialog';
import { 
  Calculator, 
  DollarSign, 
  FileDown, 
  Printer,
  CheckCircle,
  AlertCircle,
  TrendingUp,
  X
} from 'lucide-react';

export function CashClose() {
  // Estados para el resumen de cierre enviado por cajero
  const [cashierSummary] = useState({
    cashCounted: 3180,
    cardTotal: 850,
    cardTips: 120,
    otherIncome: 50,
    cashierNote: 'Conteo realizado a las 22:30. Todo correcto, solo sobraron $30 en monedas.',
    isVerified: false,
    submittedAt: '2024-09-22T22:30:00'
  });

  const [adminForm, setAdminForm] = useState({
    cashCounted: cashierSummary.cashCounted,
    cardTotal: cashierSummary.cardTotal,
    cardTips: cashierSummary.cardTips,
    otherIncome: cashierSummary.otherIncome,
    adminNotes: ''
  });

  const [showVerificationDialog, setShowVerificationDialog] = useState(false);
  const [isVerified, setIsVerified] = useState(cashierSummary.isVerified);

  // Datos mock del día
  const mockDayData = {
    ventasLocal: 2150,
    ventasParaLlevar: 1100,
    ventasEfectivo: 3250, // suma de local + para llevar
    porCobrar: 373.05,
    totalNeto: 3623.05,
    
    // Desglose detallado
    detalleVentas: [
      { concepto: 'Ventas en Local (Mesas)', cantidad: 18, subtotal: 2150 },
      { concepto: 'Para llevar', cantidad: 6, subtotal: 1100 },
      { concepto: 'Total en efectivo', cantidad: 24, subtotal: 3250 }
    ],
    
    // Gastos operativos
    gastos: [
      { concepto: 'Compra de ingredientes', monto: 450 },
      { concepto: 'Gas', monto: 85 },
      { concepto: 'Otros gastos', monto: 35 }
    ]
  };

  const handleAdminFormChange = (field, value) => {
    setAdminForm(prev => ({
      ...prev,
      [field]: parseFloat(value) || 0
    }));
  };

  const handleVerifyClose = () => {
    setIsVerified(true);
    setShowVerificationDialog(false);
    alert('Cierre de caja verificado exitosamente');
  };

  const handleRejectClose = () => {
    alert('Cierre rechazado. Se solicitará aclaración al cajero.');
  };

  const handleExportReport = () => {
    alert('Exportando reporte de cierre de caja...');
  };

  const handlePrintReport = () => {
    alert('Imprimiendo reporte de cierre...');
  };

  const totalDeclared = adminForm.cashCounted + adminForm.cardTotal + adminForm.otherIncome;
  const expectedTotal = mockDayData.ventasEfectivo + adminForm.cardTotal;
  const difference = totalDeclared - expectedTotal;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl text-amber-900 mb-2">Cierre de Caja</h1>
        <p className="text-amber-700">Resumen de ventas y conteo de efectivo del día</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Resumen de Ventas */}
        <Card className="border-amber-200">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-amber-900">
              <TrendingUp className="h-5 w-5" />
              Resumen de Ventas del Día
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Cards de resumen */}
            <div className="grid grid-cols-1 gap-3">
              <Card className="border-green-200 bg-green-50">
                <CardContent className="p-4">
                  <div className="flex justify-between items-center">
                    <span className="text-green-700">Ventas en Local</span>
                    <span className="text-xl font-medium text-green-800">${mockDayData.ventasLocal}</span>
                  </div>
                  <p className="text-xs text-green-600">18 órdenes de mesa</p>
                </CardContent>
              </Card>

              <Card className="border-blue-200 bg-blue-50">
                <CardContent className="p-4">
                  <div className="flex justify-between items-center">
                    <span className="text-blue-700">Ventas Para llevar</span>
                    <span className="text-xl font-medium text-blue-800">${mockDayData.ventasParaLlevar}</span>
                  </div>
                  <p className="text-xs text-blue-600">6 órdenes para llevar</p>
                </CardContent>
              </Card>

              <Separator className="my-2" />

              <Card className="border-amber-200 bg-amber-50">
                <CardContent className="p-4">
                  <div className="flex justify-between items-center">
                    <span className="text-amber-700">Ventas Efectivo</span>
                    <span className="text-xl font-medium text-amber-800">${mockDayData.ventasEfectivo}</span>
                  </div>
                  <p className="text-xs text-amber-600">Basado en ventas en efectivo: ${mockDayData.ventasEfectivo} (local + para llevar)</p>
                </CardContent>
              </Card>

              <Card className="border-red-200 bg-red-50">
                <CardContent className="p-4">
                  <div className="flex justify-between items-center">
                    <span className="text-red-700">Por cobrar</span>
                    <span className="text-xl font-medium text-red-800">${mockDayData.porCobrar}</span>
                  </div>
                  <p className="text-xs text-red-600">Cuentas pendientes</p>
                </CardContent>
              </Card>

              <Card className="border-purple-200 bg-purple-50">
                <CardContent className="p-4">
                  <div className="flex justify-between items-center">
                    <span className="text-purple-700">Total Neto</span>
                    <span className="text-xl font-medium text-purple-800">${mockDayData.totalNeto}</span>
                  </div>
                  <p className="text-xs text-purple-600">Ventas + Por cobrar</p>
                </CardContent>
              </Card>
            </div>

            {/* Detallle de gastos */}
            <div className="mt-6">
              <h4 className="font-medium text-amber-900 mb-3">Gastos del Día</h4>
              <div className="space-y-2">
                {mockDayData.gastos.map((gasto, index) => (
                  <div key={index} className="flex justify-between text-sm">
                    <span className="text-amber-700">{gasto.concepto}</span>
                    <span className="text-amber-800">-${gasto.monto}</span>
                  </div>
                ))}
                <Separator />
                <div className="flex justify-between font-medium">
                  <span className="text-amber-900">Total Gastos</span>
                  <span className="text-red-600">-${mockDayData.gastos.reduce((sum, g) => sum + g.monto, 0)}</span>
                </div>
              </div>
            </div>

            {/* Ganancia neta */}
            <Card className="border-green-200 bg-green-50">
              <CardContent className="p-4">
                <div className="flex justify-between items-center">
                  <span className="text-green-700 font-medium">Ganancia Neta del Día</span>
                  <span className="text-2xl font-medium text-green-800">
                    ${mockDayData.ventasEfectivo - mockDayData.gastos.reduce((sum, g) => sum + g.monto, 0)}
                  </span>
                </div>
              </CardContent>
            </Card>
          </CardContent>
        </Card>

        {/* Resumen de cierre enviado por Cajero */}
        <Card className="border-blue-200">
          <CardHeader>
            <CardTitle className="flex items-center justify-between text-blue-900">
              <div className="flex items-center gap-2">
                <Calculator className="h-5 w-5" />
                Resumen de cierre enviado por Cajero
              </div>
              {!isVerified && (
                <Badge className="bg-orange-100 text-orange-800 border-orange-300">
                  Pendiente verificación
                </Badge>
              )}
              {isVerified && (
                <Badge className="bg-green-100 text-green-800 border-green-300">
                  Verificado
                </Badge>
              )}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Resumen del cajero */}
            <div className="p-3 bg-blue-50 border border-blue-200 rounded">
              <h4 className="font-medium text-blue-900 mb-3">Datos enviados por cajero:</h4>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-blue-700">Efectivo contado:</span>
                  <span className="text-blue-900 font-medium">${cashierSummary.cashCounted}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-blue-700">Total tarjeta:</span>
                  <span className="text-blue-900 font-medium">${cashierSummary.cardTotal}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-blue-700">Propinas (tarjeta):</span>
                  <span className="text-blue-900 font-medium">${cashierSummary.cardTips}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-blue-700">Otros ingresos:</span>
                  <span className="text-blue-900 font-medium">${cashierSummary.otherIncome}</span>
                </div>
              </div>
              {cashierSummary.cashierNote && (
                <div className="mt-3 p-2 bg-white rounded border border-blue-200">
                  <p className="text-xs text-blue-700">Nota del cajero:</p>
                  <p className="text-sm text-blue-900">{cashierSummary.cashierNote}</p>
                </div>
              )}
            </div>

            {/* Formulario editable para admin */}
            <div className="space-y-3">
              <h4 className="font-medium text-blue-900">Verificación administrativa:</h4>
              
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label htmlFor="admin-cash" className="text-blue-700">Efectivo contado hoy</Label>
                  <Input
                    id="admin-cash"
                    type="number"
                    step="0.01"
                    value={adminForm.cashCounted}
                    onChange={(e) => handleAdminFormChange('cashCounted', e.target.value)}
                    className="border-blue-200 focus:border-blue-500"
                  />
                </div>

                <div>
                  <Label htmlFor="admin-card" className="text-blue-700">Total tarjeta</Label>
                  <Input
                    id="admin-card"
                    type="number"
                    step="0.01"
                    value={adminForm.cardTotal}
                    onChange={(e) => handleAdminFormChange('cardTotal', e.target.value)}
                    className="border-blue-200 focus:border-blue-500"
                  />
                </div>

                <div>
                  <Label htmlFor="admin-tips" className="text-blue-700">Propinas (tarjeta)</Label>
                  <Input
                    id="admin-tips"
                    type="number"
                    step="0.01"
                    value={adminForm.cardTips}
                    onChange={(e) => handleAdminFormChange('cardTips', e.target.value)}
                    className="border-blue-200 focus:border-blue-500"
                  />
                </div>

                <div>
                  <Label htmlFor="admin-other" className="text-blue-700">Otros ingresos / gastos</Label>
                  <Input
                    id="admin-other"
                    type="number"
                    step="0.01"
                    value={adminForm.otherIncome}
                    onChange={(e) => handleAdminFormChange('otherIncome', e.target.value)}
                    className="border-blue-200 focus:border-blue-500"
                  />
                </div>
              </div>

              <div>
                <Label htmlFor="admin-notes" className="text-blue-700">Nota del cajero</Label>
                <Textarea
                  id="admin-notes"
                  value={adminForm.adminNotes}
                  onChange={(e) => setAdminForm(prev => ({...prev, adminNotes: e.target.value}))}
                  placeholder="Observaciones administrativas..."
                  className="border-blue-200 focus:border-blue-500"
                  rows={3}
                />
              </div>
            </div>

            <Separator />

            {/* Total calculado */}
            <div className="p-3 bg-green-50 border border-green-200 rounded">
              <div className="flex justify-between items-center">
                <span className="text-green-900 font-medium">Total declarado</span>
                <span className="text-xl font-medium text-green-800">${totalDeclared.toFixed(2)}</span>
              </div>
            </div>

            {/* Diferencia */}
            <div className={`p-3 border rounded ${
              Math.abs(difference) <= 10 
                ? 'bg-green-50 border-green-200' 
                : Math.abs(difference) <= 50 
                ? 'bg-yellow-50 border-yellow-200'
                : 'bg-red-50 border-red-200'
            }`}>
              <div className="flex justify-between items-center">
                <span className={`font-medium ${
                  Math.abs(difference) <= 10 
                    ? 'text-green-900' 
                    : Math.abs(difference) <= 50 
                    ? 'text-yellow-900'
                    : 'text-red-900'
                }`}>
                  Diferencia vs esperado
                </span>
                <span className={`text-xl font-medium ${
                  Math.abs(difference) <= 10 
                    ? 'text-green-800' 
                    : Math.abs(difference) <= 50 
                    ? 'text-yellow-800'
                    : 'text-red-800'
                }`}>
                  {difference >= 0 ? '+' : ''}${difference.toFixed(2)}
                </span>
              </div>
            </div>

            {/* Botones de acción */}
            {!isVerified && (
              <div className="flex gap-2">
                <Button 
                  variant="outline" 
                  onClick={handleRejectClose}
                  className="flex-1 border-red-300 text-red-700 hover:bg-red-50"
                >
                  <X className="h-4 w-4 mr-2" />
                  Rechazar / Solicitar aclaración
                </Button>
                
                <AlertDialog open={showVerificationDialog} onOpenChange={setShowVerificationDialog}>
                  <AlertDialogTrigger asChild>
                    <Button 
                      className="flex-1 bg-green-600 hover:bg-green-700"
                    >
                      <CheckCircle className="h-4 w-4 mr-2" />
                      Marcar verificado
                    </Button>
                  </AlertDialogTrigger>
                  <AlertDialogContent>
                    <AlertDialogHeader>
                      <AlertDialogTitle>¿Confirmar verificación del cierre de caja?</AlertDialogTitle>
                      <AlertDialogDescription>
                        Una vez verificado, el cierre será marcado como aprobado y se registrará en el sistema.
                      </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                      <AlertDialogCancel>Cancelar</AlertDialogCancel>
                      <AlertDialogAction onClick={handleVerifyClose}>Confirmar</AlertDialogAction>
                    </AlertDialogFooter>
                  </AlertDialogContent>
                </AlertDialog>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Acciones */}
      <Card className="border-amber-200">
        <CardContent className="p-6">
          <div className="flex flex-col sm:flex-row gap-4 justify-between">
            <div className="flex gap-2">
              <Button 
                variant="outline" 
                onClick={handleExportReport}
                className="border-amber-300 text-amber-700"
              >
                <FileDown className="h-4 w-4 mr-2" />
                Exportar Reporte
              </Button>
              <Button 
                variant="outline" 
                onClick={handlePrintReport}
                className="border-amber-300 text-amber-700"
              >
                <Printer className="h-4 w-4 mr-2" />
                Imprimir
              </Button>
            </div>
            
            <Button 
              onClick={handleExportReport}
              className="bg-green-600 hover:bg-green-700"
              disabled={!isVerified}
            >
              <CheckCircle className="h-4 w-4 mr-2" />
              {isVerified ? 'Cierre Verificado' : 'Pendiente Verificación'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}