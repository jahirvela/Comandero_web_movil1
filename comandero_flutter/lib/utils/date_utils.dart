/// Utilidades para manejo de fechas y zonas horarias
/// Optimizado para zona horaria de México (CDMX - America/Mexico_City)
class AppDateUtils {
  /// Offset de CDMX (UTC-6 en invierno, UTC-5 en verano/horario de verano)
  /// Flutter usa la zona horaria del sistema, pero esta constante ayuda para debugging
  static const String cdmxTimezone = 'America/Mexico_City';
  
  /// Convierte una fecha UTC (ISO string) a la zona horaria local (CDMX)
  /// 
  /// IMPORTANTE: Las fechas del backend están en UTC, aunque no tengan 'Z' al final.
  /// Este método asume que TODAS las fechas con formato ISO del backend son UTC
  /// y las convierte a hora local.
  /// 
  /// Soporta formatos:
  /// - ISO 8601 con Z (UTC): "2024-01-15T10:30:00.000Z"
  /// - ISO 8601 con offset: "2024-01-15T10:30:00-06:00"
  /// - ISO 8601 sin zona: "2024-01-15T10:30:00" (ASUME UTC, convierte a local)
  /// - Solo fecha: "2024-01-15" (asume inicio del día local)
  /// - Timestamp (int): milisegundos o segundos desde epoch (UTC)
  static DateTime parseToLocal(dynamic fecha) {
    if (fecha == null) {
      return DateTime.now();
    }

    try {
      DateTime parsedDate;

      if (fecha is String) {
        final fechaLimpia = fecha.trim();
        
        if (fechaLimpia.isEmpty) {
          return DateTime.now();
        }

        // Verificar si es solo fecha (sin hora) - formato YYYY-MM-DD
        final soloFecha = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(fechaLimpia);
        if (soloFecha) {
          // Solo fecha, asumir inicio del día en hora local
          parsedDate = DateTime.parse(fechaLimpia);
          return parsedDate; // Ya está en hora local
        }

        // Parsear la fecha con hora
        // Si termina en 'Z', es explícitamente UTC
        if (fechaLimpia.endsWith('Z')) {
          parsedDate = DateTime.parse(fechaLimpia).toLocal();
        } else if (fechaLimpia.contains('+') || 
                   (fechaLimpia.length > 19 && fechaLimpia.substring(19).contains('-'))) {
          // Tiene offset de zona horaria explícito (ej: +00:00 o -06:00)
          parsedDate = DateTime.parse(fechaLimpia).toLocal();
        } else {
          // NO tiene indicador de zona horaria
          // IMPORTANTE: Asumir que el backend envía UTC sin 'Z'
          // Parsear como UTC y convertir a local
          parsedDate = DateTime.parse(fechaLimpia);
          // Crear como UTC y convertir a local
          parsedDate = DateTime.utc(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
            parsedDate.hour,
            parsedDate.minute,
            parsedDate.second,
            parsedDate.millisecond,
          ).toLocal();
        }
      } else if (fecha is DateTime) {
        // Si es DateTime, asegurarse de que esté en zona local
        parsedDate = fecha.isUtc ? fecha.toLocal() : fecha;
      } else if (fecha is int) {
        // Timestamp en milisegundos o segundos (siempre UTC)
        final timestamp = fecha;
        parsedDate = timestamp > 1000000000000
            ? DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true).toLocal()
            : DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true).toLocal();
      } else {
        return DateTime.now();
      }

      return parsedDate;
    } catch (e) {
      print('⚠️ AppDateUtils: Error al parsear fecha: $fecha, error: $e');
      return DateTime.now();
    }
  }

  /// Obtiene la fecha/hora actual en zona horaria local (CDMX)
  static DateTime now() {
    return DateTime.now();
  }

  /// Convierte una fecha local a UTC para enviar al backend
  static String toUtcIsoString(DateTime fecha) {
    final utcDate = fecha.isUtc ? fecha : fecha.toUtc();
    return utcDate.toIso8601String();
  }

  /// Formatea una fecha para mostrar en la interfaz
  /// Formato: dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime fecha) {
    // Asegurar que la fecha esté en hora local
    final localDate = fecha.isUtc ? fecha.toLocal() : fecha;
    
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year;
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year $hour:$minute';
  }

  /// Formatea solo la fecha (sin hora)
  /// Formato: dd/MM/yyyy
  static String formatDate(DateTime fecha) {
    // Asegurar que la fecha esté en hora local
    final localDate = fecha.isUtc ? fecha.toLocal() : fecha;
    
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year;
    
    return '$day/$month/$year';
  }

  /// Formatea solo la hora
  /// Formato: HH:mm
  static String formatTime(DateTime fecha) {
    // Asegurar que la fecha esté en hora local
    final localDate = fecha.isUtc ? fecha.toLocal() : fecha;
    
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    
    return '$hour:$minute';
  }

  /// Formatea la hora con segundos
  /// Formato: HH:mm:ss
  static String formatTimeWithSeconds(DateTime fecha) {
    // Asegurar que la fecha esté en hora local
    final localDate = fecha.isUtc ? fecha.toLocal() : fecha;
    
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    final second = localDate.second.toString().padLeft(2, '0');
    
    return '$hour:$minute:$second';
  }

  /// Formatea fecha con nombre del día y mes
  /// Formato: Lunes 15 de Enero 2024
  static String formatDateLong(DateTime fecha) {
    // Asegurar que la fecha esté en hora local
    final localDate = fecha.isUtc ? fecha.toLocal() : fecha;
    
    final diasSemana = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    final meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 
                   'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    
    final diaSemana = diasSemana[localDate.weekday % 7];
    final mes = meses[localDate.month - 1];
    
    return '$diaSemana ${localDate.day} de $mes ${localDate.year}';
  }

  /// Formatea fecha con nombre del mes corto
  /// Formato: 15 Ene 2024
  static String formatDateShort(DateTime fecha) {
    // Asegurar que la fecha esté en hora local
    final localDate = fecha.isUtc ? fecha.toLocal() : fecha;
    
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                   'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    
    final mes = meses[localDate.month - 1];
    
    return '${localDate.day} $mes ${localDate.year}';
  }

  /// Obtiene la diferencia de tiempo en texto legible
  /// Ej: "Hace 5 minutos", "Hace 2 horas", "Hace 3 días"
  static String getTimeAgo(DateTime fecha) {
    final now = DateTime.now();
    final localDate = fecha.isUtc ? fecha.toLocal() : fecha;
    final difference = now.difference(localDate);

    if (difference.isNegative) {
      // Si la fecha es futura (posible error de zona horaria)
      return 'Recién';
    } else if (difference.inSeconds < 60) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return 'Hace $mins ${mins == 1 ? 'minuto' : 'minutos'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Hace $hours ${hours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'Hace $days ${days == 1 ? 'día' : 'días'}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Hace $weeks ${weeks == 1 ? 'semana' : 'semanas'}';
    } else {
      return formatDate(localDate);
    }
  }

  /// Verifica si una fecha es de hoy
  static bool isToday(DateTime fecha) {
    final now = DateTime.now();
    final localDate = fecha.isUtc ? fecha.toLocal() : fecha;
    return localDate.year == now.year && 
           localDate.month == now.month && 
           localDate.day == now.day;
  }

  /// Verifica si una fecha es de ayer
  static bool isYesterday(DateTime fecha) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final localDate = fecha.isUtc ? fecha.toLocal() : fecha;
    return localDate.year == yesterday.year && 
           localDate.month == yesterday.month && 
           localDate.day == yesterday.day;
  }

  /// Obtiene el inicio del día (00:00:00) en hora local
  static DateTime startOfDay(DateTime fecha) {
    final localDate = fecha.isUtc ? fecha.toLocal() : fecha;
    return DateTime(localDate.year, localDate.month, localDate.day);
  }

  /// Obtiene el fin del día (23:59:59) en hora local
  static DateTime endOfDay(DateTime fecha) {
    final localDate = fecha.isUtc ? fecha.toLocal() : fecha;
    return DateTime(localDate.year, localDate.month, localDate.day, 23, 59, 59, 999);
  }
}

