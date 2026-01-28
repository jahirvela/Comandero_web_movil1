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
      return AppDateUtils.now();
    }

    try {
      DateTime parsedDate;

      if (fecha is String) {
        final fechaLimpia = fecha.trim();
        
        if (fechaLimpia.isEmpty) {
          return AppDateUtils.now();
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
          // Es UTC, convertir a CDMX
          final utcDate = DateTime.parse(fechaLimpia);
          parsedDate = _utcToCdmx(utcDate);
        } else if (fechaLimpia.contains('+') || 
                   (fechaLimpia.length > 19 && fechaLimpia.substring(19).contains('-'))) {
          // Tiene offset de zona horaria explícito (ej: +00:00 o -06:00)
          // IMPORTANTE: DateTime.parse() convierte automáticamente a UTC internamente,
          // por lo que debemos extraer los componentes de la cadena original
          
          // Verificar si el offset es de CDMX (-06:00 o -05:00)
          final offsetMatch = RegExp(r'([+-])(\d{2}):(\d{2})$').firstMatch(fechaLimpia);
          if (offsetMatch != null) {
            final offsetSign = offsetMatch.group(1);
            final offsetHours = int.parse(offsetMatch.group(2)!);
            
            // CDMX es UTC-6 (horario estándar) o UTC-5 (horario de verano)
            if (offsetSign == '-' && (offsetHours == 6 || offsetHours == 5)) {
              // La fecha ya está en CDMX, extraer componentes de la cadena original
              // NO usar DateTime.parse() porque convierte a UTC
              final dateTimeMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?').firstMatch(fechaLimpia);
              if (dateTimeMatch != null) {
                final year = int.parse(dateTimeMatch.group(1)!);
                final month = int.parse(dateTimeMatch.group(2)!);
                final day = int.parse(dateTimeMatch.group(3)!);
                final hour = int.parse(dateTimeMatch.group(4)!);
                final minute = int.parse(dateTimeMatch.group(5)!);
                final second = int.parse(dateTimeMatch.group(6)!);
                final millisStr = dateTimeMatch.group(7);
                final millis = millisStr != null 
                    ? int.parse(millisStr.padRight(3, '0').substring(0, 3))
                    : 0;
                
                // Crear DateTime local con los valores originales (ya en CDMX)
                parsedDate = DateTime(year, month, day, hour, minute, second, millis);
              } else {
                // Fallback: usar DateTime.parse y luego extraer como local
                final parsed = DateTime.parse(fechaLimpia);
                parsedDate = DateTime(
                  parsed.year,
                  parsed.month,
                  parsed.day,
                  parsed.hour,
                  parsed.minute,
                  parsed.second,
                  parsed.millisecond,
                );
              }
            } else {
              // Es otra zona horaria, convertir a CDMX
              // Primero convertir a UTC y luego a CDMX
              final parsed = DateTime.parse(fechaLimpia);
              final utcDate = parsed.toUtc();
              parsedDate = _utcToCdmx(utcDate);
            }
          } else {
            // No se pudo determinar el offset, asumir UTC y convertir a CDMX
            final parsed = DateTime.parse(fechaLimpia);
            final utcDate = parsed.toUtc();
            parsedDate = _utcToCdmx(utcDate);
          }
        } else {
          // NO tiene indicador de zona horaria
          // IMPORTANTE: El backend usa utcToMxISO que convierte fechas UTC de MySQL a CDMX
          // y devuelve un ISO string en hora local (CDMX) sin 'Z'
          // Por lo tanto, estas fechas YA están en hora local y NO deben convertirse de UTC
          
          // Si tiene espacio en lugar de 'T', es formato MySQL datetime
          // El backend ya lo convirtió a CDMX, así que parsearlo como hora local directamente
          if (fechaLimpia.contains(' ') && !fechaLimpia.contains('T')) {
            // Formato MySQL datetime: "2025-12-09 15:15:20.000" (ya en CDMX local)
            // Parsear manualmente y crear como DateTime local directamente
            final mysqlFormat = RegExp(r'^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?$');
            final match = mysqlFormat.firstMatch(fechaLimpia);
            if (match != null) {
              final year = int.parse(match.group(1)!);
              final month = int.parse(match.group(2)!);
              final day = int.parse(match.group(3)!);
              final hour = int.parse(match.group(4)!);
              final minute = int.parse(match.group(5)!);
              final second = int.parse(match.group(6)!);
              final millis = match.group(7) != null 
                  ? int.parse(match.group(7)!.substring(0, match.group(7)!.length > 3 ? 3 : match.group(7)!.length))
                  : 0;
              
              // CRÍTICO: Crear como DateTime LOCAL (no UTC)
              // El backend ya convirtió a CDMX, así que esta fecha ya está en hora local
              parsedDate = DateTime(
                year,
                month,
                day,
                hour,
                minute,
                second,
                millis,
              ); // Sin isUtc: true = hora local
            } else {
              // Si no coincide el formato MySQL, intentar parseo ISO estándar
              final fechaNormalizada = fechaLimpia.replaceFirst(' ', 'T');
              parsedDate = DateTime.parse(fechaNormalizada);
            }
          } else {
            // Formato ISO sin 'Z' - el backend ya lo convirtió a CDMX
            // Parsear como hora local directamente
            try {
              parsedDate = DateTime.parse(fechaLimpia);
              // Asegurar que sea hora local (no UTC)
              if (parsedDate.isUtc) {
                parsedDate = parsedDate.toLocal();
              }
            } catch (e) {
              print('⚠️ AppDateUtils: Error al parsear fecha ISO: $fechaLimpia, error: $e');
              return AppDateUtils.now();
            }
          }
        }
      } else if (fecha is DateTime) {
        // Si es DateTime, convertir a CDMX
        parsedDate = fecha.isUtc ? _utcToCdmx(fecha) : fecha;
      } else if (fecha is int) {
        // Timestamp en milisegundos o segundos (siempre UTC)
        final timestamp = fecha;
        final utcDate = timestamp > 1000000000000
            ? DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true)
            : DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);
        parsedDate = _utcToCdmx(utcDate);
      } else {
        return AppDateUtils.now();
      }

      return parsedDate;
    } catch (e) {
      print('⚠️ AppDateUtils: Error al parsear fecha: $fecha, error: $e');
      return AppDateUtils.now();
    }
  }

  /// Convierte una fecha UTC a CDMX
  /// IMPORTANTE: Esta función calcula el offset correcto de CDMX
  static DateTime _utcToCdmx(DateTime utcDate) {
    if (!utcDate.isUtc) {
      // Si no es UTC, convertir primero
      final utc = utcDate.toUtc();
      return _utcToCdmx(utc);
    }
    
    // Calcular si estamos en horario de verano en CDMX
    final isDaylightSaving = _isDaylightSavingTime(utcDate);
    final offsetHours = isDaylightSaving ? -5 : -6;
    
    // Aplicar offset de CDMX
    return utcDate.add(Duration(hours: offsetHours));
  }

  /// Obtiene la fecha/hora actual en zona horaria CDMX (America/Mexico_City)
  /// IMPORTANTE: Calcula el offset correcto de CDMX considerando horario de verano
  /// CDMX: UTC-6 en invierno, UTC-5 en verano (horario de verano)
  /// 
  /// Horario de verano en México (aproximado):
  /// - Comienza: primer domingo de abril a las 2:00 AM
  /// - Termina: último domingo de octubre a las 2:00 AM
  /// Obtiene la fecha/hora actual en zona horaria local del sistema
  /// Si el sistema está configurado con zona horaria de México, devuelve hora de CDMX
  /// Si no, devuelve la hora local del sistema
  static DateTime now() {
    // Usar DateTime.now() directamente que usa la zona horaria del sistema
    // Si el sistema está configurado con zona horaria de México, ya será correcta
    return DateTime.now();
  }
  
  /// Verifica si una fecha UTC está en horario de verano de CDMX
  /// Horario de verano: aproximadamente de abril a octubre
  static bool _isDaylightSavingTime(DateTime utcDate) {
    final year = utcDate.year;
    final month = utcDate.month;
    
    // Reglas de horario de verano en México:
    // - Comienza: primer domingo de abril a las 2:00 AM CDMX (8:00 AM UTC)
    // - Termina: último domingo de octubre a las 2:00 AM CDMX (7:00 AM UTC el día anterior)
    
    if (month < 4 || month > 10) {
      // Noviembre a marzo: definitivamente horario estándar
      return false;
    } else if (month > 4 && month < 10) {
      // Mayo a septiembre: definitivamente horario de verano
      return true;
    } else if (month == 4) {
      // Abril: verificar si ya pasó el primer domingo
      final firstSunday = _getFirstSundayOfMonth(year, 4);
      // 2:00 AM CDMX = 8:00 AM UTC (UTC-6) o 7:00 AM UTC (UTC-5)
      // Usar 8:00 AM UTC como referencia (antes del cambio a horario de verano)
      final dstStart = DateTime.utc(year, 4, firstSunday, 8);
      return utcDate.isAfter(dstStart) || utcDate.isAtSameMomentAs(dstStart);
    } else { // month == 10
      // Octubre: verificar si aún no ha pasado el último domingo
      final lastSunday = _getLastSundayOfMonth(year, 10);
      // 2:00 AM CDMX = 7:00 AM UTC (antes del cambio de vuelta a estándar)
      final dstEnd = DateTime.utc(year, 10, lastSunday, 7);
      return utcDate.isBefore(dstEnd);
    }
  }
  
  /// Obtiene el primer domingo de un mes
  static int _getFirstSundayOfMonth(int year, int month) {
    final firstDay = DateTime.utc(year, month, 1);
    final weekday = firstDay.weekday; // 1 = lunes, 7 = domingo
    // Calcular días hasta el primer domingo
    // Si es domingo (7), el primer domingo es el día 1
    // Si es lunes (1), el primer domingo es el día 7
    // Si es martes (2), el primer domingo es el día 6
    // etc.
    if (weekday == 7) {
      return 1; // El día 1 es domingo
    } else {
      return 8 - weekday; // Días hasta el siguiente domingo
    }
  }
  
  /// Obtiene el último domingo de un mes
  static int _getLastSundayOfMonth(int year, int month) {
    // Obtener el último día del mes
    final lastDay = DateTime.utc(year, month + 1, 0);
    final weekday = lastDay.weekday; // 1 = lunes, 7 = domingo
    // Retroceder hasta el domingo
    // Si es domingo (7), ese es el último domingo
    // Si es lunes (1), retroceder 1 día
    // Si es martes (2), retroceder 2 días
    // etc.
    if (weekday == 7) {
      return lastDay.day; // El último día es domingo
    } else {
      return lastDay.day - weekday; // Retroceder hasta el domingo anterior
    }
  }

  /// Convierte una fecha local a UTC para enviar al backend
  static String toUtcIsoString(DateTime fecha) {
    final utcDate = fecha.isUtc ? fecha : fecha.toUtc();
    return utcDate.toIso8601String();
  }

  /// Formatea una fecha para mostrar en la interfaz
  /// Formato: dd/MM/yyyy HH:mm
  /// Siempre muestra la hora en zona local (CDMX)
  static String formatDateTime(DateTime fecha) {
    // Si la fecha es UTC, convertir a hora local del sistema
    // Si ya es local, usar directamente
    DateTime localDate;
    if (fecha.isUtc) {
      // Convertir de UTC a hora local del sistema
      localDate = fecha.toLocal();
    } else {
      // Ya es hora local, usar directamente
      localDate = fecha;
    }
    
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
  /// IMPORTANTE: Usa hora CDMX para cálculos precisos
  static String getTimeAgo(DateTime fecha) {
    final now = AppDateUtils.now(); // Usar hora CDMX
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

  /// Verifica si una fecha es de hoy (en zona CDMX)
  static bool isToday(DateTime fecha) {
    final now = AppDateUtils.now(); // Usar hora CDMX
    final localDate = fecha.isUtc ? fecha.toLocal() : fecha;
    return localDate.year == now.year && 
           localDate.month == now.month && 
           localDate.day == now.day;
  }

  /// Verifica si una fecha es de ayer (en zona CDMX)
  static bool isYesterday(DateTime fecha) {
    final now = AppDateUtils.now(); // Usar hora CDMX
    final yesterday = now.subtract(const Duration(days: 1));
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

