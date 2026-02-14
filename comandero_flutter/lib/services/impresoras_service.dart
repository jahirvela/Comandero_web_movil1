import 'package:dio/dio.dart';
import 'api_service.dart';

/// Anchos de papel soportados (mm).
const List<int> kPaperWidths = [57, 58, 72, 80];

int _normalizePaperWidth(dynamic value) {
  if (value == null) return 80;
  final n = value is int ? value : (int.tryParse(value.toString()) ?? 80);
  return kPaperWidths.contains(n) ? n : 80;
}

/// Tipos de conexión de impresora térmica.
enum TipoImpresora {
  usb,
  tcp,
  bluetooth,
  simulation,
}

extension TipoImpresoraExt on TipoImpresora {
  String get label {
    switch (this) {
      case TipoImpresora.usb:
        return 'USB (alámbrica)';
      case TipoImpresora.tcp:
        return 'Red (IP)';
      case TipoImpresora.bluetooth:
        return 'Bluetooth';
      case TipoImpresora.simulation:
        return 'Simulación';
    }
  }

  static TipoImpresora fromString(String? v) {
    switch (v?.toLowerCase()) {
      case 'usb':
        return TipoImpresora.usb;
      case 'tcp':
        return TipoImpresora.tcp;
      case 'bluetooth':
        return TipoImpresora.bluetooth;
      case 'simulation':
        return TipoImpresora.simulation;
      default:
        return TipoImpresora.usb;
    }
  }

  String get value => name;
}

class ImpresoraModel {
  final int id;
  final String nombre;
  final TipoImpresora tipo;
  final String? device;
  final String? host;
  final int? port;
  final int paperWidth;
  final bool imprimeTicket;
  final bool imprimeComanda;
  final int orden;
  final bool activo;
  final String? marcaModelo;

  ImpresoraModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.device,
    this.host,
    this.port,
    this.paperWidth = 80,
    this.imprimeTicket = true,
    this.imprimeComanda = false,
    this.orden = 0,
    this.activo = true,
    this.marcaModelo,
  });

  factory ImpresoraModel.fromJson(Map<String, dynamic> json) {
    return ImpresoraModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      tipo: TipoImpresoraExt.fromString(json['tipo'] as String?),
      device: json['device'] as String?,
      host: json['host'] as String?,
      port: json['port'] as int?,
      paperWidth: _normalizePaperWidth(json['paperWidth']),
      imprimeTicket: json['imprimeTicket'] as bool? ?? true,
      imprimeComanda: json['imprimeComanda'] as bool? ?? false,
      orden: json['orden'] as int? ?? 0,
      activo: json['activo'] as bool? ?? true,
      marcaModelo: json['marcaModelo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'tipo': tipo.value,
        'device': device,
        'host': host,
        'port': port,
        'paperWidth': paperWidth,
        'imprimeTicket': imprimeTicket,
        'imprimeComanda': imprimeComanda,
        'orden': orden,
        'activo': activo,
        'marcaModelo': marcaModelo,
      };
}

class ImpresorasService {
  final ApiService _api = ApiService();

  Future<List<ImpresoraModel>> getImpresoras() async {
    final response = await _api.get('/impresoras');
    if (response.statusCode != 200) return [];
    final data = response.data;
    if (data is! List) return [];
    return (data as List).map((e) => ImpresoraModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ImpresoraModel?> getImpresora(int id) async {
    final response = await _api.get('/impresoras/$id');
    if (response.statusCode != 200 || response.data == null) return null;
    return ImpresoraModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ImpresoraModel?> createImpresora(Map<String, dynamic> body) async {
    final response = await _api.post('/impresoras', data: body);
    if (response.statusCode != 201 || response.data == null) return null;
    return ImpresoraModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ImpresoraModel?> updateImpresora(int id, Map<String, dynamic> body) async {
    final response = await _api.put('/impresoras/$id', data: body);
    if (response.statusCode != 200 || response.data == null) return null;
    return ImpresoraModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<bool> deleteImpresora(int id) async {
    final response = await _api.delete('/impresoras/$id');
    return response.statusCode == 204;
  }
}
