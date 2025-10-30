import React from 'react';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../../ui/table';
import { Badge } from '../../ui/badge';
import { Button } from '../../ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '../../ui/card';
import { Eye, FileDown } from 'lucide-react';

export interface ClosureRecord {
  id: string;
  fecha: string;
  periodo: 'Día' | 'Semana' | 'Mes';
  usuario: string;
  totalNeto: number;
  efectivo: number;
  tarjeta: number;
  propinasTarjeta: number;
  propinasEfectivo: number;
  pedidosParaLlevar: number;
  estado: 'Pendiente verificación' | 'Verificado';
  tipo?: string;
}

interface ClosureTableProps {
  closures: ClosureRecord[];
  onSelectClosure: (closure: ClosureRecord) => void;
  onExportClosure: (closureId: string) => void;
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
  rowsPerPage: number;
  onRowsPerPageChange: (rows: number) => void;
}

export function ClosureTable({
  closures,
  onSelectClosure,
  onExportClosure,
  currentPage,
  totalPages,
  onPageChange,
  rowsPerPage,
  onRowsPerPageChange
}: ClosureTableProps) {
  const formatPeriod = (fecha: string, periodo: string) => {
    if (periodo === 'Semana') {
      return `Semana 38 (${fecha})`;
    }
    return fecha;
  };

  const getStatusBadge = (estado: string) => {
    if (estado === 'Verificado') {
      return (
        <Badge className="bg-green-100 text-green-800 border-green-300">
          Verificado
        </Badge>
      );
    }
    return (
      <Badge className="bg-amber-100 text-amber-800 border-amber-300">
        Pendiente verificación
      </Badge>
    );
  };

  return (
    <Card className="border-amber-200">
      <CardHeader>
        <CardTitle className="text-amber-900">Historial de Cierres</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="overflow-x-auto">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="text-amber-900">Fecha / Periodo</TableHead>
                <TableHead className="text-amber-900">Usuario</TableHead>
                <TableHead className="text-amber-900">Tipo</TableHead>
                <TableHead className="text-amber-900 text-right">Total Neto ($)</TableHead>
                <TableHead className="text-amber-900 text-right">Efectivo ($)</TableHead>
                <TableHead className="text-amber-900 text-right">Tarjeta ($)</TableHead>
                <TableHead className="text-amber-900 text-right">Propinas (Tarjeta) ($)</TableHead>
                <TableHead className="text-amber-900 text-right">Propinas (Efectivo) ($)</TableHead>
                <TableHead className="text-amber-900 text-right">Para llevar ($)</TableHead>
                <TableHead className="text-amber-900">Estado</TableHead>
                <TableHead className="text-amber-900">Acciones</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {closures.map((closure) => (
                <TableRow key={closure.id} className="hover:bg-amber-50">
                  <TableCell className="font-medium">
                    {formatPeriod(closure.fecha, closure.periodo)}
                  </TableCell>
                  <TableCell>{closure.usuario}</TableCell>
                  <TableCell>{closure.periodo}</TableCell>
                  <TableCell className="text-right font-medium">
                    ${closure.totalNeto.toFixed(2)}
                  </TableCell>
                  <TableCell className="text-right">
                    ${closure.efectivo.toFixed(2)}
                  </TableCell>
                  <TableCell className="text-right">
                    ${closure.tarjeta.toFixed(2)}
                  </TableCell>
                  <TableCell className="text-right">
                    ${closure.propinasTarjeta.toFixed(2)}
                  </TableCell>
                  <TableCell className="text-right">
                    ${closure.propinasEfectivo.toFixed(2)}
                  </TableCell>
                  <TableCell className="text-right">
                    ${closure.pedidosParaLlevar.toFixed(2)}
                  </TableCell>
                  <TableCell>
                    {getStatusBadge(closure.estado)}
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => onSelectClosure(closure)}
                        className="border-amber-300 text-amber-700 hover:bg-amber-50"
                      >
                        <Eye className="h-3 w-3 mr-1" />
                        Ver detalle
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => onExportClosure(closure.id)}
                        className="border-amber-300 text-amber-700 hover:bg-amber-50"
                      >
                        <FileDown className="h-3 w-3 mr-1" />
                        Exportar
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>

        {/* Paginación */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 mt-6">
          <div className="flex items-center gap-2">
            <span className="text-sm text-amber-700">Filas por página:</span>
            <select
              value={rowsPerPage}
              onChange={(e) => onRowsPerPageChange(Number(e.target.value))}
              className="border border-amber-200 rounded px-2 py-1 text-sm"
            >
              <option value={10}>10</option>
              <option value={25}>25</option>
              <option value={50}>50</option>
            </select>
          </div>

          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => onPageChange(currentPage - 1)}
              disabled={currentPage === 1}
              className="border-amber-300 text-amber-700"
            >
              Anterior
            </Button>
            <span className="text-sm text-amber-700">
              Página {currentPage} de {totalPages}
            </span>
            <Button
              variant="outline"
              size="sm"
              onClick={() => onPageChange(currentPage + 1)}
              disabled={currentPage === totalPages}
              className="border-amber-300 text-amber-700"
            >
              Siguiente
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}