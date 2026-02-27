import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'auth_storage.dart';

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

/// Configuración del negocio (IVA y cajón). México CDMX.
class ConfiguracionModel {
  final bool ivaHabilitado;
  final ConfiguracionCajonModel cajon;

  ConfiguracionModel({
    required this.ivaHabilitado,
    ConfiguracionCajonModel? cajon,
  }) : cajon = cajon ?? ConfiguracionCajonModel();

  factory ConfiguracionModel.fromJson(Map<String, dynamic> json) {
    final cajonJson = json['cajon'];
    return ConfiguracionModel(
      ivaHabilitado: json['ivaHabilitado'] as bool? ?? false,
      cajon: cajonJson is Map ? ConfiguracionCajonModel.fromJson(cajonJson as Map<String, dynamic>) : ConfiguracionCajonModel(),
    );
  }

  Map<String, dynamic> toJson() => {
        'ivaHabilitado': ivaHabilitado,
        'cajon': cajon.toJson(),
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
    final token = await AuthStorage().read('accessToken');
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: _configTimeout,
      receiveTimeout: _configTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ));
    final response = await dio.get('/configuracion');
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
}
