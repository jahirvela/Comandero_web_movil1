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
      return AppDateUtils.nowCdmx();
    }

    try {
      DateTime parsedDate;

      if (fecha is String) {
        final fechaLimpia = fecha.trim();
        
        if (fechaLimpia.isEmpty) {
          return AppDateUtils.nowCdmx();
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
              if (parsedDate.isUtc) {
                parsedDate = _utcToCdmx(parsedDate);
              }
            } catch (e) {
              print('⚠️ AppDateUtils: Error al parsear fecha ISO: $fechaLimpia, error: $e');
              return AppDateUtils.nowCdmx();
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
        return AppDateUtils.nowCdmx();
      }

      return parsedDate;
    } catch (e) {
      print('⚠️ AppDateUtils: Error al parsear fecha: $fecha, error: $e');
      return AppDateUtils.nowCdmx();
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

  /// Obtiene la fecha/hora actual en zona horaria CDMX (America/Mexico_City).
  /// Siempre devuelve la hora de CDMX con independencia de la zona del dispositivo.
  static DateTime nowCdmx() {
    final utcNow = DateTime.now().toUtc();
    return _utcToCdmx(utcNow);
  }

  /// Obtiene la fecha/hora actual en zona horaria local del sistema (legacy).
  /// Para lógica de negocio y filtros "hoy" usa [nowCdmx].
  static DateTime now() {
    return DateTime.now();
  }
  
  /// Verifica si una fecha UTC está en horario de verano de CDMX
  /// CDMX (America/Mexico_City) actualmente no aplica horario de verano
  /// en operación general; mantener false evita desfases de +1h en reportes.
  static bool _isDaylightSavingTime(DateTime utcDate) {
    return false;
  }
  
  /// Parsea una fecha del backend (UTC) y la convierte a la hora local del dispositivo.
  /// Útil para mostrar "Última actualización" y que coincida con la hora del sistema del usuario.
  static DateTime parseUtcToDeviceLocal(dynamic fecha) {
    if (fecha == null) return nowCdmx();
    try {
      if (fecha is String) {
        final s = fecha.trim();
        if (s.isEmpty) return nowCdmx();
        final parsed = DateTime.parse(s);
        return parsed.isUtc ? parsed.toLocal() : parsed;
      }
      if (fecha is DateTime) {
        return fecha.isUtc ? fecha.toLocal() : fecha;
      }
      if (fecha is int) {
        final utc = fecha > 1000000000000
            ? DateTime.fromMillisecondsSinceEpoch(fecha, isUtc: true)
            : DateTime.fromMillisecondsSinceEpoch(fecha * 1000, isUtc: true);
        return utc.toLocal();
      }
      return nowCdmx();
    } catch (_) {
      return nowCdmx();
    }
  }

  /// Convierte una fecha local a UTC para enviar al backend
  static String toUtcIsoString(DateTime fecha) {
    final utcDate = fecha.isUtc ? fecha : fecha.toUtc();
    return utcDate.toIso8601String();
  }

  /// Reloj de pared en CDMX para mostrar y exportar (CSV/PDF, tickets).
  /// Si [fecha] es UTC (p. ej. tras serialización), convierte con la misma
  /// regla que [nowCdmx]; si ya es hora local/CDMX del parser, no se altera.
  static DateTime toCdmxWallForReport(DateTime fecha) {
    if (fecha.isUtc) return _utcToCdmx(fecha);
    return fecha;
  }

  /// Mismo día calendario en CDMX (filtrar cierres u operaciones "de hoy").
  static bool isSameCalendarDayCdmx(DateTime a, DateTime b) {
    final ca = toCdmxWallForReport(a);
    final cb = toCdmxWallForReport(b);
    return ca.year == cb.year && ca.month == cb.month && ca.day == cb.day;
  }

  /// Formatea una fecha para mostrar en la interfaz
  /// Formato: dd/MM/yyyy HH:mm
  /// Hora en CDMX cuando el instante viene en UTC; si ya es local/CDMX, sin cambio.
  static String formatDateTime(DateTime fecha) {
    final localDate = toCdmxWallForReport(fecha);

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year;
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year $hour:$minute';
  }

  /// Formatea fecha y hora con AM/PM (ej: 13/03/2026 8:30 PM).
  /// CDMX cuando el instante es UTC; coherente con [nowCdmx] y cierres de caja.
  static String formatDateTimeWithAmPm(DateTime fecha) {
    final localDate = toCdmxWallForReport(fecha);
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year;
    final hour12 = localDate.hour == 0
        ? 12
        : localDate.hour > 12
            ? localDate.hour - 12
            : localDate.hour;
    final minute = localDate.minute.toString().padLeft(2, '0');
    final amPm = localDate.hour < 12 ? 'AM' : 'PM';
    return '$day/$month/$year $hour12:$minute $amPm';
  }

  /// Fecha-hora CDMX sin comas (export CSV / pies de archivo): evita columnas
  /// partidas y celdas `###` en Excel cuando el locale inserta comas en fechas.
  static String formatDateTimeCsvSafe(DateTime fecha) {
    final localDate = toCdmxWallForReport(fecha);
    final y = localDate.year;
    final mo = localDate.month.toString().padLeft(2, '0');
    final d = localDate.day.toString().padLeft(2, '0');
    final h = localDate.hour.toString().padLeft(2, '0');
    final mi = localDate.minute.toString().padLeft(2, '0');
    final s = localDate.second.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi:$s';
  }

  /// Formatea solo la fecha (sin hora)
  /// Formato: dd/MM/yyyy
  static String formatDate(DateTime fecha) {
    final localDate = toCdmxWallForReport(fecha);
    
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year;
    
    return '$day/$month/$year';
  }

  /// Formatea solo la hora
  /// Formato: HH:mm
  static String formatTime(DateTime fecha) {
    final localDate = toCdmxWallForReport(fecha);
    
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    
    return '$hour:$minute';
  }

  /// Formatea la hora con segundos
  /// Formato: HH:mm:ss
  static String formatTimeWithSeconds(DateTime fecha) {
    final localDate = toCdmxWallForReport(fecha);
    
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    final second = localDate.second.toString().padLeft(2, '0');
    
    return '$hour:$minute:$second';
  }

  /// Formatea fecha con nombre del día y mes
  /// Formato: Lunes 15 de Enero 2024
  static String formatDateLong(DateTime fecha) {
    final localDate = toCdmxWallForReport(fecha);
    
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
    final localDate = toCdmxWallForReport(fecha);
    
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                   'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    
    final mes = meses[localDate.month - 1];
    
    return '${localDate.day} $mes ${localDate.year}';
  }

  /// Obtiene la diferencia de tiempo en texto legible
  /// Ej: "Hace 5 minutos", "Hace 2 horas", "Hace 3 días"
  /// IMPORTANTE: Usa hora CDMX para cálculos precisos
  static String getTimeAgo(DateTime fecha) {
    final now = AppDateUtils.nowCdmx();
    final localDate = toCdmxWallForReport(fecha);
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

  /// Formato corto unificado para "hace cuánto" en toda la app.
  /// Evita mostrar "1260 min"; convierte a "Hace 21 h" o "Hace X días".
  /// Usa [now] como referencia (default [nowCdmx] para operación en CDMX).
  static String formatTimeAgoShort(DateTime from, {DateTime? now}) {
    final n = now ?? nowCdmx();
    final localFrom = toCdmxWallForReport(from);
    final diff = n.difference(localFrom);
    if (diff.isNegative || diff.inSeconds < 60) return 'Recién';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 30) return 'Hace ${diff.inDays} ${diff.inDays == 1 ? 'día' : 'días'}';
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 8) return 'Hace $weeks ${weeks == 1 ? 'semana' : 'semanas'}';
    return formatDate(localFrom);
  }

  /// Igual que [formatTimeAgoShort] pero a partir de una [Duration].
  /// Útil cuando ya tienes la diferencia calculada (ej. cajero, capitán).
  static String formatDurationShort(Duration d) {
    if (d.isNegative || d.inSeconds < 60) return 'Recién';
    if (d.inMinutes < 60) return 'Hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'Hace ${d.inHours} h';
    if (d.inDays < 30) return 'Hace ${d.inDays} ${d.inDays == 1 ? 'día' : 'días'}';
    final weeks = (d.inDays / 7).floor();
    if (weeks < 8) return 'Hace $weeks ${weeks == 1 ? 'semana' : 'semanas'}';
    return 'Hace ${d.inDays} días';
  }

  /// Verifica si una fecha es de hoy (en zona CDMX)
  static bool isToday(DateTime fecha) {
    return isSameCalendarDayCdmx(fecha, nowCdmx());
  }

  /// Verifica si una fecha es de ayer (en zona CDMX)
  static bool isYesterday(DateTime fecha) {
    final yesterday = nowCdmx().subtract(const Duration(days: 1));
    return isSameCalendarDayCdmx(fecha, yesterday);
  }

  /// Inicio del día calendario (00:00:00) en componentes CDMX.
  static DateTime startOfDay(DateTime fecha) {
    final localDate = toCdmxWallForReport(fecha);
    return DateTime(localDate.year, localDate.month, localDate.day);
  }

  /// Fin del día calendario (23:59:59.999) en componentes CDMX.
  static DateTime endOfDay(DateTime fecha) {
    final localDate = toCdmxWallForReport(fecha);
    return DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      23,
      59,
      59,
      999,
    );
  }

  /// Medianoche del día calendario CDMX como instante **UTC** (negocio en UTC-6 fijo).
  static DateTime cdmxCalendarDayStartUtc(int year, int month, int day) {
    return DateTime.utc(year, month, day, 6, 0, 0, 0);
  }

  /// Último milisegundo del día calendario CDMX como instante **UTC**.
  static DateTime cdmxCalendarDayEndUtc(int year, int month, int day) {
    return cdmxCalendarDayStartUtc(year, month, day)
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
  }

  /// Límites UTC del día calendario CDMX que contiene el reloj de pared [wall].
  static ({DateTime startUtc, DateTime endUtc}) cdmxCalendarDayBoundsUtcFromWall(
    DateTime wall,
  ) {
    final w = toCdmxWallForReport(wall);
    final y = w.year;
    final m = w.month;
    final d = w.day;
    return (
      startUtc: cdmxCalendarDayStartUtc(y, m, d),
      endUtc: cdmxCalendarDayEndUtc(y, m, d),
    );
  }

  /// Convierte un instante descrito como reloj de pared CDMX (componentes) a UTC para el API.
  static DateTime cdmxWallClockToUtc(DateTime wall) {
    final w = toCdmxWallForReport(wall);
    return DateTime.utc(
      w.year,
      w.month,
      w.day,
      w.hour,
      w.minute,
      w.second,
      w.millisecond,
    ).add(const Duration(hours: 6));
  }
}
