import React, { useState, useEffect } from 'react';
import { CashCloseFilterBar } from './cash-close/CashCloseFilterBar';
import { ClosureSummaryCards } from './cash-close/ClosureSummaryCards';
import { ClosureTable } from './cash-close/ClosureTable';
import { ClosureDetailPanel } from './cash-close/ClosureDetailPanel';
import { mockClosureRecords, getClosuresByPreset, calculateSummaryTotals } from './cash-close/mockData';
import { toast } from 'sonner@2.0.3';
import type { ClosureRecord } from './cash-close/ClosureTable';

interface NewCashCloseProps {
  userRole?: 'admin' | 'cajero';
  userId?: string;
}

export function NewCashClose({ userRole = 'admin', userId }: NewCashCloseProps) {
  // Estados principales
  const [currentPreset, setCurrentPreset] = useState('today');
  const [dateRange, setDateRange] = useState({ from: '2025-09-22', to: '2025-09-22' });
  const [showVerifiedOnly, setShowVerifiedOnly] = useState(false);
  const [filteredClosures, setFilteredClosures] = useState<ClosureRecord[]>([]);
  const [selectedClosure, setSelectedClosure] = useState<ClosureRecord | null>(null);
  const [isDetailPanelOpen, setIsDetailPanelOpen] = useState(false);
  
  // Estados de paginación
  const [currentPage, setCurrentPage] = useState(1);
  const [rowsPerPage, setRowsPerPage] = useState(10);

  // Detectar si es mobile
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth < 768);
    };
    
    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  // Actualizar datos filtrados cuando cambian los filtros
  useEffect(() => {
    let closures = getClosuresByPreset(currentPreset, showVerifiedOnly);
    
    // Si es cajero, solo mostrar sus propios cierres
    if (userRole === 'cajero' && userId) {
      closures = closures.filter(closure => closure.usuario === userId);
    }
    
    setFilteredClosures(closures);
    setCurrentPage(1); // Reset página al cambiar filtros
  }, [currentPreset, showVerifiedOnly, userRole, userId]);

  // Calcular paginación
  const totalPages = Math.ceil(filteredClosures.length / rowsPerPage);
  const startIndex = (currentPage - 1) * rowsPerPage;
  const paginatedClosures = filteredClosures.slice(startIndex, startIndex + rowsPerPage);

  // Calcular totales para el resumen
  const summaryTotals = calculateSummaryTotals(filteredClosures);

  // Handlers
  const handlePresetChange = (preset: string) => {
    setCurrentPreset(preset);
    toast("Cierres actualizados");
  };

  const handleDateRangeChange = (range: { from: string; to: string }) => {
    setDateRange(range);
  };

  const handleToggleVerified = (show: boolean) => {
    setShowVerifiedOnly(show);
  };

  const handleExportCSV = () => {
    toast("Exportación lista");
    // Simular descarga
    setTimeout(() => {
      console.log('Exportando CSV con datos:', filteredClosures);
    }, 1000);
  };

  const handleExportPDF = () => {
    toast("Exportación lista");
    // Simular descarga
    setTimeout(() => {
      console.log('Exportando PDF con datos:', filteredClosures);
    }, 1000);
  };

  const handleSelectClosure = (closure: ClosureRecord) => {
    setSelectedClosure(closure);
    setIsDetailPanelOpen(true);
  };

  const handleExportClosure = (closureId: string) => {
    const closure = filteredClosures.find(c => c.id === closureId);
    if (closure) {
      toast("Exportación lista");
      console.log('Exportando cierre:', closure);
    }
  };

  const handleMarkVerified = (closureId: string) => {
    // En una app real, esto haría una llamada a la API
    const closureIndex = mockClosureRecords.findIndex(c => c.id === closureId);
    if (closureIndex !== -1) {
      mockClosureRecords[closureIndex].estado = 'Verificado';
      setFilteredClosures(prev => 
        prev.map(c => c.id === closureId ? { ...c, estado: 'Verificado' as const } : c)
      );
    }
  };

  const handleRequestClarification = (closureId: string) => {
    console.log('Solicitando aclaración para cierre:', closureId);
    // En una app real, esto enviaría una notificación al cajero
  };

  const handlePrintDetail = (closureId: string) => {
    console.log('Imprimiendo detalle del cierre:', closureId);
    // En una app real, esto abriría el diálogo de impresión
  };

  const handlePageChange = (page: number) => {
    setCurrentPage(page);
  };

  const handleRowsPerPageChange = (rows: number) => {
    setRowsPerPage(rows);
    setCurrentPage(1);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl text-amber-900 mb-2">
          Cierre de Caja {userRole === 'cajero' ? '— Panel del Cajero' : ''}
        </h1>
        <p className="text-amber-700">
          {userRole === 'admin' 
            ? 'Gestión y verificación de cierres de caja del sistema'
            : 'Historial de tus cierres de caja'
          }
        </p>
      </div>

      {/* Barra de filtros */}
      <CashCloseFilterBar
        currentPreset={currentPreset}
        onPresetChange={handlePresetChange}
        dateRange={dateRange}
        onDateRangeChange={handleDateRangeChange}
        showVerifiedOnly={showVerifiedOnly}
        onToggleVerified={handleToggleVerified}
        onExportCSV={handleExportCSV}
        onExportPDF={handleExportPDF}
      />

      {/* Cards de resumen */}
      <ClosureSummaryCards data={summaryTotals} />

      {/* Tabla de cierres */}
      <ClosureTable
        closures={paginatedClosures}
        onSelectClosure={handleSelectClosure}
        onExportClosure={handleExportClosure}
        currentPage={currentPage}
        totalPages={totalPages}
        onPageChange={handlePageChange}
        rowsPerPage={rowsPerPage}
        onRowsPerPageChange={handleRowsPerPageChange}
      />

      {/* Panel de detalle */}
      <ClosureDetailPanel
        closure={selectedClosure}
        isOpen={isDetailPanelOpen}
        onClose={() => setIsDetailPanelOpen(false)}
        onMarkVerified={handleMarkVerified}
        onRequestClarification={handleRequestClarification}
        onPrintDetail={handlePrintDetail}
        isMobile={isMobile}
        userRole={userRole}
      />
    </div>
  );
}