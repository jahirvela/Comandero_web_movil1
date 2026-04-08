import '../models/admin_model.dart';

/// Coincide con [PIEZA_UNITS] del backend (`inventario.service.ts`).
bool inventarioUnidadEsPieza(String unit) {
  final u = unit.trim().toLowerCase();
  if (u.isEmpty) return false;
  const set = {
    'pza',
    'pzas',
    'pieza',
    'piezas',
    'unidad',
    'unidades',
    'ud',
    'uds',
  };
  return set.contains(u);
}

/// Unidades del desplegable «contenido por envase» cuando el ítem va por pieza
/// (masa, volumen o recuento: kg, g, L, ml, Piezas, Unidades).
const List<String> kInventarioUnidadContenidoOpciones = [
  'kg',
  'g',
  'L',
  'ml',
  'Piezas',
  'Unidades',
];

String inventarioFormatCantidad(double value) {
  final stockValue = value < 0 ? 0.0 : value;
  if (stockValue == stockValue.toInt()) {
    return stockValue.toInt().toString();
  }
  return stockValue
      .toStringAsFixed(1)
      .replaceAll(RegExp(r'0*$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

bool _casiUno(double v) => (v - 1.0).abs() < 1e-6;

/// Texto principal de stock (ej. `12 piezas` o `3.5 kg`).
String inventarioStockDisplay(InventoryItem item) {
  final raw = item.currentStock < 0 ? 0.0 : item.currentStock;
  final n = inventarioFormatCantidad(item.currentStock);
  if (inventarioUnidadEsPieza(item.unit)) {
    return '$n ${_casiUno(raw) ? 'pieza' : 'piezas'}';
  }
  final u = item.unit.trim();
  return u.isEmpty ? n : '$n $u';
}

/// Stock mínimo / máximo con la misma convención.
String inventarioMinStockDisplay(InventoryItem item) {
  final v = item.minStock < 0 ? 0.0 : item.minStock;
  final n = inventarioFormatCantidad(item.minStock);
  if (inventarioUnidadEsPieza(item.unit)) {
    return '$n ${_casiUno(v) ? 'pieza' : 'piezas'}';
  }
  final u = item.unit.trim();
  return u.isEmpty ? n : '$n $u';
}

String inventarioMaxStockDisplay(InventoryItem item) {
  final v = item.maxStock < 0 ? 0.0 : item.maxStock;
  final n = inventarioFormatCantidad(item.maxStock);
  if (inventarioUnidadEsPieza(item.unit)) {
    return '$n ${_casiUno(v) ? 'pieza' : 'piezas'}';
  }
  final u = item.unit.trim();
  return u.isEmpty ? n : '$n $u';
}

/// Línea secundaria: contenido total (kg, L, piezas, etc.) cuando hay `contenidoPorPieza`.
String? inventarioEquivTotalLine(InventoryItem item) {
  if (!inventarioUnidadEsPieza(item.unit)) return null;
  final c = item.contenidoPorPieza;
  final uc = item.unidadContenido?.trim();
  if (c == null || c <= 0 || uc == null || uc.isEmpty) return null;
  final stock = item.currentStock < 0 ? 0.0 : item.currentStock;
  final total = stock * c;
  if (total <= 0) return null;
  return '≈ ${inventarioFormatCantidad(total)} $uc en total';
}

String? inventarioEquivMinimoLine(InventoryItem item) {
  if (!inventarioUnidadEsPieza(item.unit)) return null;
  final c = item.contenidoPorPieza;
  final uc = item.unidadContenido?.trim();
  if (c == null || c <= 0 || uc == null || uc.isEmpty) return null;
  final total = item.minStock * c;
  if (total <= 0) return null;
  return '≈ ${inventarioFormatCantidad(total)} $uc (mín. acumulado)';
}

/// Textos para listas/tarjetas: si el ítem va por pieza/envase, siempre incluye
/// la línea de contenido declarado o un aviso si falta; opcionalmente equivalentes.
List<String> inventarioContenidoEnvaseLines(InventoryItem item) {
  if (!inventarioUnidadEsPieza(item.unit)) return const [];
  final c = item.contenidoPorPieza;
  final uc = item.unidadContenido?.trim();
  final lines = <String>[];
  if (c != null && c > 0 && uc != null && uc.isNotEmpty) {
    lines.add('Contenido por envase: ${inventarioFormatCantidad(c)} $uc');
    final totalLine = inventarioEquivTotalLine(item);
    if (totalLine != null) lines.add(totalLine);
    final minLine = inventarioEquivMinimoLine(item);
    if (minLine != null) lines.add(minLine);
  } else {
    lines.add(
      'Contenido por envase: no indicado (edita el ítem para definirlo)',
    );
  }
  return lines;
}

/// Opciones del desplegable de unidad de contenido, conservando un valor guardado
/// aunque no esté en la lista fija (p. ej. datos legacy).
List<String> inventarioUnidadContenidoOpcionesConActual(String? actual) {
  final a = actual?.trim();
  if (a == null || a.isEmpty) {
    return List<String>.from(kInventarioUnidadContenidoOpciones);
  }
  if (kInventarioUnidadContenidoOpciones.contains(a)) {
    return List<String>.from(kInventarioUnidadContenidoOpciones);
  }
  return [...kInventarioUnidadContenidoOpciones, a];
}

/// Sufijo en campos de ajuste (piezas vs unidad literal).
String inventarioUnidadSuffixAjuste(InventoryItem item) {
  if (inventarioUnidadEsPieza(item.unit)) return 'piezas';
  final u = item.unit.trim();
  return u.isEmpty ? 'ud' : u;
}

/// Etiqueta para costo unitario: `/pieza` o `/kg`, etc.
String inventarioEtiquetaUnidadCosto(String unit) {
  if (inventarioUnidadEsPieza(unit)) return '/pieza';
  final u = unit.trim();
  return u.isEmpty ? '' : '/$u';
}
