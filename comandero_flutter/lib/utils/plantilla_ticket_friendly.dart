/// Convierte la plantilla técnica de la API (`{{CLAVE}}`, `[CENTRAR]`, etc.)
/// a texto simple de edición y viceversa.
abstract final class PlantillaTicketFriendly {
  PlantillaTicketFriendly._();

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
    final out =
        _formatToFriendly.map((e) => (e.$2, e.$1)).toList();
    out.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    return out;
  }();

  /// Placeholders del cuerpo del ticket (orden: más largo primero al reemplazar).
  static final List<(String technical, String friendly)> _contenidoPlaceholders =
      _sortedPlaceholderPairs(<String, String>{
        'NOMBRE_RESTAURANTE': 'campo nombre del restaurante',
        'IVA_LINE': 'campo linea iva',
        'IMPRESO_POR': 'campo impreso por',
        'METODO_PAGO': 'campo metodo de pago',
        'SEPARADOR': 'campo linea separadora',
        'DIRECCION': 'campo direccion',
        'DESCUENTO': 'campo descuento',
        'TELEFONO': 'campo telefono',
        'SUBTOTAL': 'campo subtotal',
        'CLIENTE': 'campo cliente',
        'ITEMS': 'campo lista de productos',
        'GRACIAS': 'campo gracias',
        'VUELVA': 'campo vuelva pronto',
        'TITULO': 'campo titulo',
        'FECHA': 'campo fecha y hora',
        'FOLIO': 'campo folio',
        'MONEDA': 'campo moneda',
        'GUION': 'campo linea guiones',
        'MESA': 'campo mesa',
        'RFC': 'campo rfc',
        'IVA': 'campo iva',
        'TOTAL': 'campo total',
      });

  static final List<(String technical, String friendly)> _lineaPlaceholders =
      _sortedPlaceholderPairs(<String, String>{
        'DESCRIPCION': 'campo descripcion producto',
        'TAMANO': 'campo tamano',
        'MONEDA': 'campo moneda',
        'TOTAL': 'campo total',
        'CANT': 'campo cantidad',
      });

  static List<(String technical, String friendly)> _sortedPlaceholderPairs(
    Map<String, String> keysToLabel,
  ) {
    final out = keysToLabel.entries
        .map((e) => ('{{${e.key}}}', e.value))
        .toList();
    out.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    return out;
  }

  static List<(String friendly, String technical)> _invertPairs(
    List<(String technical, String friendly)> pairs,
  ) {
    final out = pairs.map((e) => (e.$2, e.$1)).toList();
    out.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    return out;
  }

  static final List<(String friendly, String technical)>
      _contenidoPlaceholdersInverted = _invertPairs(_contenidoPlaceholders);

  static final List<(String friendly, String technical)>
      _lineaPlaceholdersInverted = _invertPairs(_lineaPlaceholders);

  static final RegExp _unknownTechnical = RegExp(r'\{\{([^}]+)\}\}');
  static final RegExp _unknownFriendly =
      RegExp(r'campo personalizado:\s*(.+)$', caseSensitive: false);
  static final RegExp _legacyUnknownFriendly =
      RegExp(r'«etiqueta:\s*([^»]+)»');
  static final RegExp _oldFormatFriendly =
      RegExp(r'\b(inicio|fin)\s+(centrado|negrita)\b', caseSensitive: false);

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
      return 'campo personalizado: $key';
    });
    s = s.replaceAll(')(', ') (');
    s = s.replaceAll(')campo ', ') campo ');
    return s;
  }

  /// Contenido del editor convertido a formato API (cuerpo).
  static String contenidoFriendlyATecnico(String friendly) {
    var s = friendly;
    s = s.replaceAllMapped(_oldFormatFriendly, (m) => '(${m.group(0)!.toLowerCase()})');
    for (final e in _contenidoPlaceholdersInverted) {
      s = s.replaceAll(e.$1, e.$2);
    }
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
      return 'campo personalizado: $key';
    });
    s = s.replaceAll(')(', ') (');
    s = s.replaceAll(')campo ', ') campo ');
    return s;
  }

  /// Línea de ítem: editor → API (null si vacío).
  static String? lineaFriendlyATecnica(String? friendly) {
    final t = (friendly ?? '').trim();
    if (t.isEmpty) return null;
    var s = t;
    s = s.replaceAllMapped(_oldFormatFriendly, (m) => '(${m.group(0)!.toLowerCase()})');
    for (final e in _lineaPlaceholdersInverted) {
      s = s.replaceAll(e.$1, e.$2);
    }
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
    final technical =
        tipoDocumento == 'comanda'
            ? _defaultComandaTechnical
            : _defaultTicketTechnical;
    return contenidoTecnicoAFriendly(technical.trimRight());
  }

  /// Línea de ítem base legible (opcional).
  static String lineaItemBaseFriendlyPorTipo(String tipoDocumento) {
    if (tipoDocumento == 'comanda') {
      return 'campo cantidad  campo descripcion producto  Nota: campo personalizado: NOTA';
    }
    return 'campo cantidad  campo descripcion producto  campo moneda campo total';
  }
}
