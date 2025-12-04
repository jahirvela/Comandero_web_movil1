export interface OrdenItemModificadorDetalle {
  id: number;
  ordenItemId: number;
  modificadorOpcionId: number;
  modificadorOpcionNombre: string;
  precioUnitario: number;
}

export interface OrdenItemDetalle {
  id: number;
  ordenId: number;
  productoId: number;
  productoNombre: string;
  productoTamanoId: number | null;
  productoTamanoEtiqueta: string | null;
  cantidad: number;
  precioUnitario: number;
  totalLinea: number;
  nota: string | null;
  modificadores: OrdenItemModificadorDetalle[];
}

export interface OrdenDetalle {
  id: number;
  mesaId: number | null;
  mesaCodigo: string | null;
  clienteId: number | null;
  clienteNombre: string | null;
  clienteTelefono?: string | null;
  subtotal: number;
  descuentoTotal: number;
  impuestoTotal: number;
  propinaSugerida: number | null;
  total: number;
  estadoOrdenId: number;
  estadoNombre: string;
  creadoPorUsuarioId: number | null;
  cerradoPorUsuarioId: number | null;
  creadoEn: Date | string;
  actualizadoEn: Date | string;
  items: OrdenItemDetalle[];
  estimatedTime?: number | null;
  pickupTime?: string | null;
}

