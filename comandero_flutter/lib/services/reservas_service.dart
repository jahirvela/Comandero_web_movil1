import 'api_service.dart';
import '../utils/date_utils.dart' as date_utils;

class ReservaModel {
  final int id;
  final int mesaId;
  final int? mesaNumero;
  final String? nombreCliente;
  final String? telefono;
  final DateTime fechaHoraInicio;
  final DateTime? fechaHoraFin;
  final String estado;
  final int? creadoPorUsuarioId;
  final String? creadoPorUsuarioNombre;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  ReservaModel({
    required this.id,
    required this.mesaId,
    this.mesaNumero,
    this.nombreCliente,
    this.telefono,
    required this.fechaHoraInicio,
    this.fechaHoraFin,
    required this.estado,
    this.creadoPorUsuarioId,
    this.creadoPorUsuarioNombre,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  factory ReservaModel.fromJson(Map<String, dynamic> json) {
    return ReservaModel(
      id: json['id'] as int,
      mesaId: json['mesaId'] as int,
      mesaNumero: json['mesaNumero'] as int?,
      nombreCliente: json['nombreCliente'] as String?,
      telefono: json['telefono'] as String?,
      fechaHoraInicio: date_utils.AppDateUtils.parseToLocal(json['fechaHoraInicio']),
      fechaHoraFin: json['fechaHoraFin'] != null
          ? date_utils.AppDateUtils.parseToLocal(json['fechaHoraFin'])
          : null,
      estado: json['estado'] as String,
      creadoPorUsuarioId: json['creadoPorUsuarioId'] as int?,
      creadoPorUsuarioNombre: json['creadoPorUsuarioNombre'] as String?,
      creadoEn: date_utils.AppDateUtils.parseToLocal(json['creadoEn']),
      actualizadoEn: date_utils.AppDateUtils.parseToLocal(json['actualizadoEn']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mesaId': mesaId,
      'mesaNumero': mesaNumero,
      'nombreCliente': nombreCliente,
      'telefono': telefono,
      'fechaHoraInicio': fechaHoraInicio.toIso8601String(),
      'fechaHoraFin': fechaHoraFin?.toIso8601String(),
      'estado': estado,
      'creadoPorUsuarioId': creadoPorUsuarioId,
      'creadoPorUsuarioNombre': creadoPorUsuarioNombre,
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }
}

class ReservasService {
  final ApiService _api = ApiService();

  /// Lista todas las reservas con filtros opcionales
  Future<List<ReservaModel>> listarReservas({
    int? mesaId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? estado,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (mesaId != null) {
        queryParams['mesaId'] = mesaId.toString();
      }
      if (fechaInicio != null) {
        queryParams['fechaInicio'] = fechaInicio.toIso8601String();
      }
      if (fechaFin != null) {
        queryParams['fechaFin'] = fechaFin.toIso8601String();
      }
      if (estado != null) {
        queryParams['estado'] = estado;
      }

      final response = await _api.get('/reservas', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        return data.map((item) => ReservaModel.fromJson(item as Map<String, dynamic>)).toList();
      }

      return [];
    } catch (e) {
      print('Error al listar reservas: $e');
      return [];
    }
  }

  /// Obtiene una reserva por ID
  Future<ReservaModel?> obtenerReserva(int id) async {
    try {
      final response = await _api.get('/reservas/$id');

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ReservaModel.fromJson(data);
        }
      }

      return null;
    } catch (e) {
      print('Error al obtener reserva: $e');
      return null;
    }
  }

  /// Crea una nueva reserva
  Future<ReservaModel?> crearReserva({
    required int mesaId,
    String? nombreCliente,
    String? telefono,
    required DateTime fechaHoraInicio,
    DateTime? fechaHoraFin,
    String estado = 'pendiente',
  }) async {
    try {
      final response = await _api.post(
        '/reservas',
        data: {
          'mesaId': mesaId,
          'nombreCliente': nombreCliente,
          'telefono': telefono,
          'fechaHoraInicio': fechaHoraInicio.toIso8601String(),
          'fechaHoraFin': fechaHoraFin?.toIso8601String(),
          'estado': estado,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ReservaModel.fromJson(data);
        }
      }

      return null;
    } catch (e) {
      print('Error al crear reserva: $e');
      rethrow;
    }
  }

  /// Actualiza una reserva existente
  Future<ReservaModel?> actualizarReserva({
    required int id,
    int? mesaId,
    String? nombreCliente,
    String? telefono,
    DateTime? fechaHoraInicio,
    DateTime? fechaHoraFin,
    String? estado,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (mesaId != null) data['mesaId'] = mesaId;
      if (nombreCliente != null) data['nombreCliente'] = nombreCliente;
      if (telefono != null) data['telefono'] = telefono;
      if (fechaHoraInicio != null) data['fechaHoraInicio'] = fechaHoraInicio.toIso8601String();
      if (fechaHoraFin != null) data['fechaHoraFin'] = fechaHoraFin.toIso8601String();
      if (estado != null) data['estado'] = estado;

      final response = await _api.put('/reservas/$id', data: data);

      if (response.statusCode == 200) {
        final responseData = response.data['data'] as Map<String, dynamic>?;
        if (responseData != null) {
          return ReservaModel.fromJson(responseData);
        }
      }

      return null;
    } catch (e) {
      print('Error al actualizar reserva: $e');
      rethrow;
    }
  }

  /// Elimina una reserva
  Future<bool> eliminarReserva(int id) async {
    try {
      final response = await _api.delete('/reservas/$id');
      return response.statusCode == 204;
    } catch (e) {
      print('Error al eliminar reserva: $e');
      return false;
    }
  }

  /// Confirma una reserva (cambia estado a 'confirmada')
  Future<ReservaModel?> confirmarReserva(int id) async {
    return await actualizarReserva(id: id, estado: 'confirmada');
  }

  /// Cancela una reserva (cambia estado a 'cancelada')
  Future<ReservaModel?> cancelarReserva(int id) async {
    return await actualizarReserva(id: id, estado: 'cancelada');
  }
}

