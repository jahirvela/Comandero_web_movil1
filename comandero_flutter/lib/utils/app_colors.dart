import 'package:flutter/material.dart';

/// Colores del sistema basados en las imágenes de referencia PNG
/// Esquema de colores para restaurante tipo barbacoa
class AppColors {
  // Colores principales basados en las imágenes de referencia
  static const Color primary = Color(
    0xFFFF6B35,
  ); // Naranja principal de las imágenes
  static const Color secondary = Color(0xFFF3E8D8); // Ámbar claro
  static const Color accent = Color(0xFFFF6B35); // Naranja principal

  // Colores de fondo
  static const Color background = Color(0xFFFEF9F5); // Fondo principal
  static const Color surface = Color(0xFFFFFFFF); // Superficie de cards
  static const Color inputBackground = Color(0xFFF9F5F1); // Fondo de inputs

  // Colores de texto
  static const Color textPrimary = Color(0xFF3C2317); // Texto principal
  static const Color textSecondary = Color(0xFF8D6E63); // Texto secundario
  static const Color textMuted = Color(0xFF8D6E63); // Texto atenuado

  // Colores de estado basados en las imágenes
  static const Color success = Color(
    0xFF4CAF50,
  ); // Verde para "Listo", "Verificado"
  static const Color error = Color(
    0xFFF44336,
  ); // Rojo para "Retrasado", "Urgente"
  static const Color warning = Color(
    0xFFFF9800,
  ); // Naranja para "Pendiente", "En preparación"
  static const Color info = Color(0xFF2196F3); // Azul para "Enviado al Cajero"

  // Colores de roles actualizados
  static const Color mesero = Color(0xFFFF6B35); // Naranja principal
  static const Color cocinero = Color(0xFFFF6B35); // Naranja principal
  static const Color admin = Color(0xFF4CAF50); // Verde
  static const Color cajero = Color(0xFF2196F3); // Azul
  static const Color capitan = Color(0xFF8B5CF6); // Morado

  // Colores de borde actualizados
  static const Color border = Color(0x26FF6B35); // Naranja con opacidad
  static const Color borderFocus = Color(0xFFFF6B35); // Naranja sólido

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Colores de sombra actualizados
  static Color shadowColor = primary.withValues(alpha: 0.3);
}
