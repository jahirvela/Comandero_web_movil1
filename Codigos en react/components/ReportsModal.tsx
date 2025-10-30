import React, { useState } from 'react';
import { Button } from './ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from './ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Checkbox } from './ui/checkbox';
import { Label } from './ui/label';
import { Input } from './ui/input';
import { FileText, Download, Calendar } from 'lucide-react';
import { toast } from 'sonner@2.0.3';

interface ReportsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

interface ReportSection {
  id: string;
  label: string;
  description: string;
  enabled: boolean;
}

const PERIODS = [
  { value: 'today', label: 'Hoy' },
  { value: 'week', label: 'Última semana' },
  { value: 'biweekly', label: 'Quincena' },
  { value: 'month', label: 'Mes' },
  { value: 'custom', label: 'Personalizado' }
];

export function ReportsModal({ isOpen, onClose }: ReportsModalProps) {
  const [selectedPeriod, setSelectedPeriod] = useState('today');
  const [customStartDate, setCustomStartDate] = useState('');
  const [customEndDate, setCustomEndDate] = useState('');
  const [reportSections, setReportSections] = useState<ReportSection[]>([
    {
      id: 'sales',
      label: 'Ventas',
      description: 'Resumen de ventas por período',
      enabled: true
    },
    {
      id: 'pending',
      label: 'Por cobrar',
      description: 'Cuentas pendientes de pago',
      enabled: true
    },
    {
      id: 'tips',
      label: 'Propinas',
      description: 'Total de propinas recolectadas',
      enabled: true
    },
    {
      id: 'takeaway',
      label: 'Pedidos para llevar',
      description: 'Órdenes de comida para llevar',
      enabled: true
    },
    {
      id: 'inventory',
      label: 'Inventario',
      description: 'Estado actual de inventario',
      enabled: false
    },
    {
      id: 'staff',
      label: 'Personal',
      description: 'Actividad del personal',
      enabled: false
    }
  ]);

  const handleSectionToggle = (sectionId: string) => {
    setReportSections(prev =>
      prev.map(section =>
        section.id === sectionId
          ? { ...section, enabled: !section.enabled }
          : section
      )
    );
  };

  const handleDownloadPDF = () => {
    const enabledSections = reportSections.filter(s => s.enabled);
    if (enabledSections.length === 0) {
      toast.error('Seleccione al menos una sección para el reporte');
      return;
    }

    // Simular descarga
    toast.success('Generando reporte PDF...');
    setTimeout(() => {
      toast.success('Reporte PDF descargado exitosamente');
    }, 2000);
  };

  const handleExportCSV = () => {
    const enabledSections = reportSections.filter(s => s.enabled);
    if (enabledSections.length === 0) {
      toast.error('Seleccione al menos una sección para exportar');
      return;
    }

    // Simular exportación
    toast.success('Generando archivo CSV...');
    setTimeout(() => {
      toast.success('Archivo CSV exportado exitosamente');
    }, 1500);
  };

  const getPeriodLabel = () => {
    const period = PERIODS.find(p => p.value === selectedPeriod);
    return period?.label || 'Período seleccionado';
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-md lg:max-w-lg max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <FileText className="h-5 w-5" />
            Reportes descargables
          </DialogTitle>
          <DialogDescription>
            Genera y descarga reportes del sistema en formato CSV o PDF
          </DialogDescription>
        </DialogHeader>
        
        <div className="space-y-6 py-4">
          {/* Selección de período */}
          <div>
            <Label>Período</Label>
            <Select value={selectedPeriod} onValueChange={setSelectedPeriod}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {PERIODS.map((period) => (
                  <SelectItem key={period.value} value={period.value}>
                    {period.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {/* Fechas personalizadas */}
          {selectedPeriod === 'custom' && (
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Fecha inicio</Label>
                <Input
                  type="date"
                  value={customStartDate}
                  onChange={(e) => setCustomStartDate(e.target.value)}
                />
              </div>
              <div>
                <Label>Fecha fin</Label>
                <Input
                  type="date"
                  value={customEndDate}
                  onChange={(e) => setCustomEndDate(e.target.value)}
                />
              </div>
            </div>
          )}

          {/* Secciones del reporte */}
          <div>
            <Label className="mb-3 block">Secciones a incluir</Label>
            <div className="space-y-3 max-h-48 overflow-y-auto">
              {reportSections.map((section) => (
                <div key={section.id} className="flex items-start space-x-3">
                  <Checkbox
                    id={section.id}
                    checked={section.enabled}
                    onCheckedChange={() => handleSectionToggle(section.id)}
                  />
                  <div className="flex-1">
                    <Label
                      htmlFor={section.id}
                      className="cursor-pointer"
                    >
                      {section.label}
                    </Label>
                    <p className="text-xs text-muted-foreground">
                      {section.description}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Vista previa */}
          <div className="bg-muted p-3 rounded-md">
            <h4 className="font-medium mb-2">Vista previa del reporte</h4>
            <div className="text-sm space-y-1">
              <p><strong>Período:</strong> {getPeriodLabel()}</p>
              <p><strong>Secciones:</strong> {reportSections.filter(s => s.enabled).length}</p>
              {selectedPeriod === 'custom' && customStartDate && customEndDate && (
                <p><strong>Rango:</strong> {customStartDate} a {customEndDate}</p>
              )}
            </div>
          </div>
        </div>

        <DialogFooter className="flex gap-2">
          <Button variant="outline" onClick={onClose}>
            Cancelar
          </Button>
          <Button variant="outline" onClick={handleExportCSV}>
            <Download className="h-4 w-4 mr-2" />
            Exportar CSV
          </Button>
          <Button onClick={handleDownloadPDF}>
            <FileText className="h-4 w-4 mr-2" />
            Descargar PDF
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}