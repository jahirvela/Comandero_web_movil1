import 'package:dio/dio.dart';
import 'api_service.dart';

/// Tipo de conexión del cajón: por impresora térmica, por red (IP) o USB directo.
enum CajonTipoConexion {
  viaImpresora,
  red,
  usb,
}

extension CajonTipoConexionExt on CajonTipoConexion {
  String get value {
    switch (this) {
      case CajonTipoConexion.viaImpresora:
        return 'via_impresora';
      case CajonTipoConexion.red:
        return 'red';
      case CajonTipoConexion.usb:
        return 'usb';
    }
  }

  String get label {
    switch (this) {
      case CajonTipoConexion.viaImpresora:
        return 'Vía impresora térmica';
      case CajonTipoConexion.red:
        return 'Red (IP)';
      case CajonTipoConexion.usb:
        return 'USB directo';
    }
  }

  static CajonTipoConexion fromString(String? v) {
    switch (v) {
      case 'red':
        return CajonTipoConexion.red;
      case 'usb':
        return CajonTipoConexion.usb;
      default:
        return CajonTipoConexion.viaImpresora;
    }
  }
}

/// Configuración del cajón de dinero (marca, modelo, tipo conexión, cuándo abrir).
class ConfiguracionCajonModel {
  final bool habilitado;
  final int? impresoraId;
  final bool abrirEnEfectivo;
  final bool abrirEnTarjeta;
  final CajonTipoConexion tipoConexion;
  final String? marca;
  final String? modelo;
  final String? host;
  final int? port;
  final String? device;

  ConfiguracionCajonModel({
    this.habilitado = false,
    this.impresoraId,
    this.abrirEnEfectivo = true,
    this.abrirEnTarjeta = false,
    this.tipoConexion = CajonTipoConexion.viaImpresora,
    this.marca,
    this.modelo,
    this.host,
    this.port,
    this.device,
  });

  factory ConfiguracionCajonModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ConfiguracionCajonModel();
    return ConfiguracionCajonModel(
      habilitado: json['habilitado'] as bool? ?? false,
      impresoraId: json['impresoraId'] as int?,
      abrirEnEfectivo: json['abrirEnEfectivo'] as bool? ?? true,
      abrirEnTarjeta: json['abrirEnTarjeta'] as bool? ?? false,
      tipoConexion: CajonTipoConexionExt.fromString(json['tipoConexion'] as String?),
      marca: json['marca'] as String?,
      modelo: json['modelo'] as String?,
      host: json['host'] as String?,
      port: json['port'] as int?,
      device: json['device'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'habilitado': habilitado,
        if (impresoraId != null) 'impresoraId': impresoraId,
        'abrirEnEfectivo': abrirEnEfectivo,
        'abrirEnTarjeta': abrirEnTarjeta,
        'tipoConexion': tipoConexion.value,
        if (marca != null && marca!.isNotEmpty) 'marca': marca,
        if (modelo != null && modelo!.isNotEmpty) 'modelo': modelo,
        if (host != null && host!.isNotEmpty) 'host': host,
        if (port != null) 'port': port,
        if (device != null && device!.isNotEmpty) 'device': device,
      };
}

/// Turno de caja (horario CDMX).
class CajaTurnoSlotModel {
  final String codigo;
  final String nombre;
  final String inicio;
  final String fin;

  const CajaTurnoSlotModel({
    required this.codigo,
    required this.nombre,
    required this.inicio,
    required this.fin,
  });

  factory CajaTurnoSlotModel.fromJson(Map<String, dynamic> json) {
    return CajaTurnoSlotModel(
      codigo: json['codigo'] as String? ?? 'turno',
      nombre: json['nombre'] as String? ?? json['codigo'] as String? ?? 'Turno',
      inicio: json['inicio'] as String? ?? '09:00',
      fin: json['fin'] as String? ?? '18:00',
    );
  }

  Map<String, dynamic> toJson() => {
        'codigo': codigo,
        'nombre': nombre,
        'inicio': inicio,
        'fin': fin,
      };
}

String _foldAccentosTurno(String s) {
  const map = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o', 'Ú': 'u', 'Ü': 'u', 'Ñ': 'n',
  };
  final b = StringBuffer();
  for (final ch in s.runes) {
    final c = String.fromCharCode(ch);
    b.write(map[c] ?? c);
  }
  return b.toString();
}

/// Slug para [codigo] en API: solo letras minúsculas, números y guiones bajos.
String slugCodigoDesdeNombreTurno(String nombreVisible) {
  var s = _foldAccentosTurno(nombreVisible.toLowerCase().trim());
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  s = s.replaceAll(RegExp(r'_+'), '_');
  s = s.replaceAll(RegExp(r'^_|_$'), '');
  return s;
}

/// Código interno único para guardar el turno (máx. 32 caracteres, p. ej. cierres en BD).
/// El usuario solo configura nombre y horario; el cajero ve el nombre en el desplegable.
String generarCodigoTurnoCajaUnico({
  required String nombreVisible,
  required int indiceFila,
  required Set<String> codigosUsados,
}) {
  var base = slugCodigoDesdeNombreTurno(nombreVisible);
  if (base.isEmpty) {
    base = 'turno${indiceFila + 1}';
  }
  if (base.length > 32) {
    base = base.substring(0, 32);
  }
  var candidato = base;
  var n = 2;
  while (codigosUsados.contains(candidato)) {
    final suf = '_$n';
    final maxLen = 32 - suf.length;
    final b = base.length > maxLen ? base.substring(0, maxLen) : base;
    candidato = '$b$suf';
    n++;
  }
  codigosUsados.add(candidato);
  return candidato;
}

/// Modo diario vs por turnos (un solo modo activo por restaurante).
class ConfiguracionCajaModel {
  final String modo; // diario | turnos
  final List<CajaTurnoSlotModel> turnos;

  ConfiguracionCajaModel({
    this.modo = 'diario',
    List<CajaTurnoSlotModel>? turnos,
  }) : turnos = turnos ?? const [];

  factory ConfiguracionCajaModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ConfiguracionCajaModel();
    }
    final m = json['modo'] as String? ?? 'diario';
    final t = json['turnos'];
    List<CajaTurnoSlotModel> list = [];
    if (t is List) {
      for (final e in t) {
        if (e is Map<String, dynamic>) {
          list.add(CajaTurnoSlotModel.fromJson(e));
        }
      }
    }
    return ConfiguracionCajaModel(modo: m == 'turnos' ? 'turnos' : 'diario', turnos: list);
  }

  Map<String, dynamic> toJson() => {
        'modo': modo,
        'turnos': turnos.map((e) => e.toJson()).toList(),
      };

  static List<CajaTurnoSlotModel> turnosPorDefecto() => const [
        CajaTurnoSlotModel(
          codigo: 'manana',
          nombre: 'Mañana',
          inicio: '07:00',
          fin: '12:00',
        ),
        CajaTurnoSlotModel(
          codigo: 'tarde',
          nombre: 'Tarde',
          inicio: '12:00',
          fin: '20:00',
        ),
      ];
}

/// Configuración del negocio (IVA y cajón). México CDMX.
class ConfiguracionModel {
  final bool ivaHabilitado;
  final ConfiguracionCajonModel cajon;
  final ConfiguracionCajaModel caja;

  ConfiguracionModel({
    required this.ivaHabilitado,
    ConfiguracionCajonModel? cajon,
    ConfiguracionCajaModel? caja,
  })  : cajon = cajon ?? ConfiguracionCajonModel(),
        caja = caja ?? ConfiguracionCajaModel();

  factory ConfiguracionModel.fromJson(Map<String, dynamic> json) {
    final cajonJson = json['cajon'];
    final cajaJson = json['caja'];
    return ConfiguracionModel(
      ivaHabilitado: json['ivaHabilitado'] as bool? ?? false,
      cajon: cajonJson is Map ? ConfiguracionCajonModel.fromJson(cajonJson as Map<String, dynamic>) : ConfiguracionCajonModel(),
      caja: cajaJson is Map
          ? ConfiguracionCajaModel.fromJson(cajaJson as Map<String, dynamic>)
          : ConfiguracionCajaModel(),
    );
  }

  Map<String, dynamic> toJson() => {
        'ivaHabilitado': ivaHabilitado,
        'cajon': cajon.toJson(),
        'caja': caja.toJson(),
      };
}

/// Servicio para obtener y actualizar la configuración (solo admin puede actualizar).
class ConfiguracionService {
  final ApiService _api = ApiService();

  /// Timeout corto para no bloquear la pantalla de configuración (evitar 45s de espera).
  static const Duration _configTimeout = Duration(seconds: 12);

  /// Obtener configuración actual. Cualquier rol autenticado puede leer.
  /// Usa timeout de 12s para que la pantalla no espere 45s si el servidor no responde.
  Future<ConfiguracionModel> getConfiguracion() async {
    final response = await _api.get(
      '/configuracion',
      options: Options(
        receiveTimeout: _configTimeout,
      ),
    );
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data is Map ? response.data as Map<String, dynamic> : null;
      if (data != null) return ConfiguracionModel.fromJson(data);
    }
    return ConfiguracionModel(ivaHabilitado: false);
  }

  /// Actualizar IVA habilitado. Solo administrador.
  Future<ConfiguracionModel> actualizarIvaHabilitado(bool ivaHabilitado) async {
    final response = await _api.patch('/configuracion', data: {'ivaHabilitado': ivaHabilitado});
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data is Map ? response.data as Map<String, dynamic> : null;
      if (data != null) return ConfiguracionModel.fromJson(data);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
    );
  }

  /// Actualizar configuración del cajón. Solo administrador.
  Future<ConfiguracionModel> actualizarConfiguracionCajon(Map<String, dynamic> cajon) async {
    final response = await _api.patch('/configuracion', data: {'cajon': cajon});
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data is Map ? response.data as Map<String, dynamic> : null;
      if (data != null) return ConfiguracionModel.fromJson(data);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
    );
  }

  /// Modo de caja (diario / turnos) y plantillas de turno. Solo administrador.
  Future<ConfiguracionModel> actualizarConfiguracionCaja(Map<String, dynamic> caja) async {
    final response = await _api.patch('/configuracion', data: {'caja': caja});
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data is Map ? response.data as Map<String, dynamic> : null;
      if (data != null) return ConfiguracionModel.fromJson(data);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
    );
  }

  /// Obtener plantilla de impresión (ticket_cobro, comanda).
  Future<PlantillaImpresionModel> getPlantillaImpresion(String tipo) async {
    final response = await _api.get('/configuracion/plantillas-impresion/$tipo');
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data is Map ? response.data as Map<String, dynamic> : null;
      if (data != null) return PlantillaImpresionModel.fromJson(data);
    }
    return PlantillaImpresionModel(tipoDocumento: tipo, contenido: '', plantillaLineaItem: null, actualizadoEn: null);
  }

  /// Guardar plantilla de impresión. Solo administrador.
  Future<PlantillaImpresionModel> putPlantillaImpresion(
    String tipo,
    String contenido, [
    String? plantillaLineaItem,
  ]) async {
    final response = await _api.put(
      '/configuracion/plantillas-impresion/$tipo',
      data: {'contenido': contenido, 'plantillaLineaItem': plantillaLineaItem},
    );
    if (response.statusCode == 200 && response.data != null) {
      final data = response.data is Map ? response.data as Map<String, dynamic> : null;
      if (data != null) return PlantillaImpresionModel.fromJson(data);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
    );
  }
}

/// Plantilla editable para impresión (ticket de cobro, comanda).
class PlantillaImpresionModel {
  final String tipoDocumento;
  final String contenido;
  final String? plantillaLineaItem;
  final String? actualizadoEn;

  PlantillaImpresionModel({
    required this.tipoDocumento,
    required this.contenido,
    this.plantillaLineaItem,
    this.actualizadoEn,
  });

  factory PlantillaImpresionModel.fromJson(Map<String, dynamic> json) {
    return PlantillaImpresionModel(
      tipoDocumento: json['tipoDocumento'] as String? ?? '',
      contenido: json['contenido'] as String? ?? '',
      plantillaLineaItem: json['plantillaLineaItem'] as String?,
      actualizadoEn: json['actualizadoEn'] as String?,
    );
  }
}
