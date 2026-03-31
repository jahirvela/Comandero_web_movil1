/// Convierte la plantilla técnica de la API (`{{CLAVE}}`, `[CENTRAR]`, etc.)
/// a texto simple con marcadores entre comillas, y viceversa.
///
/// Formato editable: `"Nombre del restaurante"`, `"Total"`, etc.
/// Compatibilidad: sigue aceptando el formato antiguo `campo nombre del restaurante`.
abstract final class PlantillaTicketFriendly {
  PlantillaTicketFriendly._();

  static String _q(String inner) => '"$inner"';

  static final List<(String technical, String friendly)> _formatToFriendly = () {
    const pairs = <(String, String)>[
      ('[/CENTRAR]', '(fin centrado)'),
      ('[/NEGRITA]', '(fin negrita)'),
      ('[CENTRAR]', '(inicio centrado)'),
      ('[NEGRITA]', '(inicio negrita)'),
    ];
    final sorted = [...pairs];
    sorted.sort((a, b) => a.$1.length.compareTo(b.$1.length));
    return sorted.reversed.toList();
  }();

  static final List<(String friendly, String technical)> _formatToTechnical = () {
    final out = _formatToFriendly.map((e) => (e.$2, e.$1)).toList();
    out.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    return out;
  }();

  /// Cuerpo: clave API → texto entre comillas (visible en el editor).
  static final Map<String, String> _bodyKeyToQuotedInner = <String, String>{
    'NOMBRE_RESTAURANTE': 'Nombre del restaurante',
    'IVA_LINE': 'Línea IVA',
    'IMPRESO_POR': 'Impreso por',
    'METODO_PAGO': 'Método de pago',
    'SEPARADOR': 'Línea separadora',
    'DIRECCION': 'Dirección',
    'DESCUENTO': 'Descuento',
    'TELEFONO': 'Teléfono',
    'SUBTOTAL': 'Subtotal',
    'CLIENTE': 'Cliente',
    'ITEMS': 'Lista de productos',
    'GRACIAS': 'Gracias',
    'VUELVA': 'Vuelva pronto',
    'TITULO': 'Título del documento',
    'FECHA': 'Fecha y hora',
    'FOLIO': 'Folio',
    'MONEDA': 'Moneda',
    'GUION': 'Línea guiones',
    'MESA': 'Mesa',
    'RFC': 'RFC',
    'IVA': 'IVA',
    'TOTAL': 'Total',
  };

  static final List<(String technical, String friendly)> _contenidoPlaceholders =
      _sortedBodyPairs();

  static List<(String technical, String friendly)> _sortedBodyPairs() {
    final out = _bodyKeyToQuotedInner.entries
        .map((e) => ('{{${e.key}}}', _q(e.value)))
        .toList();
    out.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    return out;
  }

  /// Línea de ítem.
  static final Map<String, String> _lineaKeyToQuotedInner = <String, String>{
    'DESCRIPCION': 'Descripción del producto',
    'TAMANO': 'Tamaño',
    'MONEDA': 'Moneda',
    'TOTAL': 'Total',
    'CANT': 'Cantidad',
  };

  static final List<(String technical, String friendly)> _lineaPlaceholders =
      () {
    final out = _lineaKeyToQuotedInner.entries
        .map((e) => ('{{${e.key}}}', _q(e.value)))
        .toList();
    out.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    return out;
  }();

  static List<(String friendly, String technical)> _invertPairs(
    List<(String technical, String friendly)> pairs,
  ) {
    final out = pairs.map((e) => (e.$2, e.$1)).toList();
    out.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    return out;
  }

  static final List<(String friendly, String technical)>
      _contenidoQuotedInverted = _invertPairs(_contenidoPlaceholders);

  static final List<(String friendly, String technical)>
      _lineaQuotedInverted = _invertPairs(_lineaPlaceholders);

  /// Formato antiguo `campo ...` → `{{CLAVE}}` (orden: más largo primero).
  static final List<(String legacyCampo, String technical)>
      _legacyContenidoCampo = () {
    const m = <String, String>{
      'campo nombre del restaurante': '{{NOMBRE_RESTAURANTE}}',
      'campo linea iva': '{{IVA_LINE}}',
      'campo impreso por': '{{IMPRESO_POR}}',
      'campo metodo de pago': '{{METODO_PAGO}}',
      'campo linea separadora': '{{SEPARADOR}}',
      'campo direccion': '{{DIRECCION}}',
      'campo descuento': '{{DESCUENTO}}',
      'campo telefono': '{{TELEFONO}}',
      'campo subtotal': '{{SUBTOTAL}}',
      'campo cliente': '{{CLIENTE}}',
      'campo lista de productos': '{{ITEMS}}',
      'campo gracias': '{{GRACIAS}}',
      'campo vuelva pronto': '{{VUELVA}}',
      'campo titulo': '{{TITULO}}',
      'campo fecha y hora': '{{FECHA}}',
      'campo folio': '{{FOLIO}}',
      'campo moneda': '{{MONEDA}}',
      'campo linea guiones': '{{GUION}}',
      'campo mesa': '{{MESA}}',
      'campo rfc': '{{RFC}}',
      'campo iva': '{{IVA}}',
      'campo total': '{{TOTAL}}',
    };
    final out = m.entries.map((e) => (e.key, e.value)).toList();
    out.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    return out;
  }();

  static final List<(String legacyCampo, String technical)> _legacyLineaCampo =
      () {
    const m = <String, String>{
      'campo descripcion producto': '{{DESCRIPCION}}',
      'campo tamano': '{{TAMANO}}',
      'campo cantidad': '{{CANT}}',
      'campo moneda': '{{MONEDA}}',
      'campo total': '{{TOTAL}}',
    };
    final out = m.entries.map((e) => (e.key, e.value)).toList();
    out.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    return out;
  }();

  static final RegExp _unknownTechnical = RegExp(r'\{\{([^}]+)\}\}');
  static final RegExp _unknownFriendly =
      RegExp(r'campo personalizado:\s*(.+)$', multiLine: true, caseSensitive: false);
  static final RegExp _legacyUnknownFriendly =
      RegExp(r'«etiqueta:\s*([^»]+)»');
  /// Solo convierte `inicio centrado` suelto (sin paréntesis); si ya está como
  /// `(inicio centrado)`, no tocar — evita duplicar paréntesis al guardar.
  static final RegExp _oldFormatFriendly = RegExp(
    r'(?<!\()\b(inicio|fin)\s+(centrado|negrita)\b(?!\))',
    caseSensitive: false,
  );

  /// Colapsa `(((inicio centrado)))` y variantes a un solo `(inicio centrado)`.
  static String _collapseFriendlyFormatTags(String s) {
    var t = s;
    const pairs = <(String pattern, String replacement)>[
      (r'\(\(+inicio\s+centrado\s*\)+', '(inicio centrado)'),
      (r'\(\(+fin\s+centrado\s*\)+', '(fin centrado)'),
      (r'\(\(+inicio\s+negrita\s*\)+', '(inicio negrita)'),
      (r'\(\(+fin\s+negrita\s*\)+', '(fin negrita)'),
    ];
    for (final e in pairs) {
      t = t.replaceAll(RegExp(e.$1, caseSensitive: false), e.$2);
    }
    return t;
  }
  /// `"Personalizado: CLAVE"` → `{{CLAVE}}` (CLAVE sin comillas internas).
  static final RegExp _quotedPersonalizado =
      RegExp(r'"Personalizado:\s*([^"]+)"');

  static const String _defaultTicketTechnical = '''
[CENTRAR][NEGRITA]{{NOMBRE_RESTAURANTE}}[/NEGRITA][/CENTRAR]
{{DIRECCION}}
Tel: {{TELEFONO}}
RFC: {{RFC}}

{{SEPARADOR}}
[CENTRAR][NEGRITA]{{TITULO}}[/NEGRITA][/CENTRAR]
{{SEPARADOR}}

Folio: {{FOLIO}}
Fecha: {{FECHA}}
Mesa: {{MESA}}
Cuenta de: {{CLIENTE}}
Impreso por: {{IMPRESO_POR}}
Método de pago: {{METODO_PAGO}}
{{GUION}}
[NEGRITA]CANT DESCRIPCION TOTAL MXN[/NEGRITA]
{{GUION}}
{{ITEMS}}
{{GUION}}
Subtotal:       {{MONEDA}}{{SUBTOTAL}}
Descuento:      {{MONEDA}}{{DESCUENTO}}
{{IVA_LINE}}
[NEGRITA]TOTAL:          {{MONEDA}}{{TOTAL}}[/NEGRITA]
{{SEPARADOR}}
[CENTRAR]{{GRACIAS}}[/CENTRAR]
[CENTRAR]{{VUELVA}}[/CENTRAR]
''';

  static const String _defaultComandaTechnical = '''
{{SEPARADOR}}
[CENTRAR][NEGRITA]COMANDA[/NEGRITA][/CENTRAR]
{{SEPARADOR}}

Folio: {{FOLIO}}
Fecha: {{FECHA}}
Mesa: {{MESA}}
Cliente: {{CLIENTE}}
{{GUION}}
[NEGRITA]CANT  DESCRIPCION          NOTAS[/NEGRITA]
{{GUION}}
{{ITEMS}}
{{SEPARADOR}}
''';

  /// Texto del editor a partir de lo que devuelve la API (cuerpo).
  static String contenidoTecnicoAFriendly(String technical) {
    var s = technical;
    for (final e in _formatToFriendly) {
      s = s.replaceAll(e.$1, e.$2);
    }
    for (final e in _contenidoPlaceholders) {
      s = s.replaceAll(e.$1, e.$2);
    }
    s = s.replaceAllMapped(_unknownTechnical, (m) {
      final key = m.group(1)?.trim() ?? '';
      return _q('Personalizado: $key');
    });
    s = s.replaceAll(')(', ') (');
    return s;
  }

  /// Contenido del editor convertido a formato API (cuerpo).
  static String contenidoFriendlyATecnico(String friendly) {
    var s = friendly;
    s = _collapseFriendlyFormatTags(s);
    s = s.replaceAllMapped(_oldFormatFriendly, (m) => '(${m.group(0)!.toLowerCase()})');
    for (final e in _legacyContenidoCampo) {
      s = s.replaceAll(e.$1, e.$2);
    }
    for (final e in _contenidoQuotedInverted) {
      s = s.replaceAll(e.$1, e.$2);
    }
    s = s.replaceAllMapped(_quotedPersonalizado, (m) {
      final key = m.group(1)?.trim() ?? '';
      return '{{$key}}';
    });
    for (final e in _formatToTechnical) {
      s = s.replaceAll(e.$1, e.$2);
    }
    s = s.replaceAllMapped(_unknownFriendly, (m) {
      final key = m.group(1)?.trim() ?? '';
      return '{{$key}}';
    });
    s = s.replaceAllMapped(_legacyUnknownFriendly, (m) {
      final key = m.group(1)?.trim() ?? '';
      return '{{$key}}';
    });
    return s;
  }

  /// Línea de ítem opcional: API → editor.
  static String lineaTecnicaAFriendly(String? technical) {
    if (technical == null || technical.isEmpty) return '';
    var s = technical;
    for (final e in _formatToFriendly) {
      s = s.replaceAll(e.$1, e.$2);
    }
    for (final e in _lineaPlaceholders) {
      s = s.replaceAll(e.$1, e.$2);
    }
    s = s.replaceAllMapped(_unknownTechnical, (m) {
      final key = m.group(1)?.trim() ?? '';
      return _q('Personalizado: $key');
    });
    s = s.replaceAll(')(', ') (');
    return s;
  }

  /// Línea de ítem: editor → API (null si vacío).
  static String? lineaFriendlyATecnica(String? friendly) {
    final t = (friendly ?? '').trim();
    if (t.isEmpty) return null;
    var s = t;
    s = _collapseFriendlyFormatTags(s);
    s = s.replaceAllMapped(_oldFormatFriendly, (m) => '(${m.group(0)!.toLowerCase()})');
    for (final e in _legacyLineaCampo) {
      s = s.replaceAll(e.$1, e.$2);
    }
    for (final e in _lineaQuotedInverted) {
      s = s.replaceAll(e.$1, e.$2);
    }
    s = s.replaceAllMapped(_quotedPersonalizado, (m) {
      final key = m.group(1)?.trim() ?? '';
      return '{{$key}}';
    });
    for (final e in _formatToTechnical) {
      s = s.replaceAll(e.$1, e.$2);
    }
    s = s.replaceAllMapped(_unknownFriendly, (m) {
      final key = m.group(1)?.trim() ?? '';
      return '{{$key}}';
    });
    s = s.replaceAllMapped(_legacyUnknownFriendly, (m) {
      final key = m.group(1)?.trim() ?? '';
      return '{{$key}}';
    });
    return s;
  }

  /// Devuelve una plantilla base legible para editar por tipo.
  static String contenidoBaseFriendlyPorTipo(String tipoDocumento) {
    final technical = tipoDocumento == 'comanda'
        ? _defaultComandaTechnical
        : _defaultTicketTechnical;
    return contenidoTecnicoAFriendly(technical.trimRight());
  }

  /// Línea de ítem base legible (opcional).
  static String lineaItemBaseFriendlyPorTipo(String tipoDocumento) {
    if (tipoDocumento == 'comanda') {
      return '${_q('Cantidad')}  ${_q('Descripción del producto')}  Nota: ${_q('Personalizado: NOTA')}';
    }
    return '${_q('Cantidad')}  ${_q('Descripción del producto')}  ${_q('Moneda')} ${_q('Total')}';
  }

  /// Texto de ayuda: lista de marcadores entre comillas (contenido).
  static String ayudaListaMarcadoresContenido() {
    final inners = _bodyKeyToQuotedInner.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return inners.map(_q).join('\n');
  }

  /// Texto de ayuda: marcadores línea de ítem.
  static String ayudaListaMarcadoresLinea() {
    final inners = _lineaKeyToQuotedInner.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return inners.map(_q).join('\n');
  }
}
