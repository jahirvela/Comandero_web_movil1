import React from 'react';
import { Button } from '../../ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../../ui/select';
import { Input } from '../../ui/input';
import { Calendar } from 'lucide-react';

interface CashCloseFilterBarProps {
  currentPreset: string;
  onPresetChange: (preset: string) => void;
  dateRange: { from: string; to: string };
  onDateRangeChange: (range: { from: string; to: string }) => void;
  showVerifiedOnly: boolean;
  onToggleVerified: (show: boolean) => void;
  onExportCSV: () => void;
  onExportPDF: () => void;
}

const presets = [
  { value: 'today', label: 'Hoy' },
  { value: 'yesterday', label: 'Ayer' },
  { value: 'last-week', label: 'Última semana' },
  { value: 'current-month', label: 'Mes actual' },
  { value: 'custom', label: 'Rango personalizado' }
];

export function CashCloseFilterBar({
  currentPreset,
  onPresetChange,
  dateRange,
  onDateRangeChange,
  showVerifiedOnly,
  onToggleVerified,
  onExportCSV,
  onExportPDF
}: CashCloseFilterBarProps) {
  return (
    <div className="bg-white border border-amber-200 rounded-lg p-4 mb-6">
      <div className="flex flex-col lg:flex-row gap-4 items-start lg:items-center justify-between">
        {/* Preset buttons - izquierda */}
        <div className="flex flex-wrap gap-2">
          {presets.map((preset) => (
            <Button
              key={preset.value}
              variant={currentPreset === preset.value ? "default" : "outline"}
              size="sm"
              onClick={() => onPresetChange(preset.value)}
              className={
                currentPreset === preset.value
                  ? "bg-amber-600 hover:bg-amber-700 text-white"
                  : "border-amber-300 text-amber-700 hover:bg-amber-50"
              }
            >
              {preset.label}
            </Button>
          ))}
        </div>

        {/* Date range picker - centro */}
        {currentPreset === 'custom' && (
          <div className="flex items-center gap-2">
            <Calendar className="h-4 w-4 text-amber-600" />
            <Input
              type="date"
              value={dateRange.from}
              onChange={(e) => onDateRangeChange({ ...dateRange, from: e.target.value })}
              className="border-amber-200 focus:border-amber-500 w-40"
            />
            <span className="text-amber-700">hasta</span>
            <Input
              type="date"
              value={dateRange.to}
              onChange={(e) => onDateRangeChange({ ...dateRange, to: e.target.value })}
              className="border-amber-200 focus:border-amber-500 w-40"
            />
            <Button
              size="sm"
              onClick={() => {/* Aplicar filtro personalizado */}}
              className="bg-amber-600 hover:bg-amber-700"
            >
              Aplicar
            </Button>
          </div>
        )}

        {/* Export actions y toggle - derecha */}
        <div className="flex items-center gap-2">
          {/* Toggle mostrar solo verificados */}
          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="show-verified"
              checked={showVerifiedOnly}
              onChange={(e) => onToggleVerified(e.target.checked)}
              className="rounded border-amber-300 text-amber-600 focus:ring-amber-500"
            />
            <label htmlFor="show-verified" className="text-sm text-amber-700">
              Mostrar solo verificados
            </label>
          </div>

          {/* Export buttons */}
          <Button
            variant="outline"
            size="sm"
            onClick={onExportCSV}
            className="border-amber-300 text-amber-700 hover:bg-amber-50"
          >
            Exportar CSV
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={onExportPDF}
            className="border-amber-300 text-amber-700 hover:bg-amber-50"
          >
            Generar PDF
          </Button>
        </div>
      </div>
    </div>
  );
}