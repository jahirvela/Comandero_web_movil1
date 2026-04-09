import 'package:flutter/material.dart';

/// Breakpoints alineados con el resto del app (cajero/capitán: 600 / 900).
abstract final class CashUiResponsive {
  static const double tabletMin = 600;
  static const double desktopMin = 900;
  static const double compactMax = 420;

  static bool isTabletOrWider(double width) => width >= tabletMin;
  static bool isDesktopOrWider(double width) => width >= desktopMin;
  static bool isCompactLayout(double width) => width < compactMax;

  /// Ancho máximo para diálogos de apertura/cierre de caja.
  static double dialogMaxWidth(double screenWidth) {
    final inset = screenWidth < 380 ? 10.0 : (screenWidth < 600 ? 20.0 : 40.0);
    final available = screenWidth - inset * 2;
    if (available <= 0) return screenWidth * 0.94;
    const cap = 580.0;
    return available.clamp(280.0, cap);
  }

  static EdgeInsets dialogInsetPadding(double screenWidth) {
    if (screenWidth < 380) {
      return const EdgeInsets.symmetric(horizontal: 10, vertical: 16);
    }
    if (screenWidth < 600) {
      return const EdgeInsets.symmetric(horizontal: 18, vertical: 22);
    }
    return const EdgeInsets.symmetric(horizontal: 40, vertical: 24);
  }

  static double modalPadding(double width) {
    if (width >= desktopMin) return 24;
    if (width >= tabletMin) return 20;
    return 14;
  }

  static double modalTitleSize(double width) {
    if (width >= desktopMin) return 22;
    if (width >= tabletMin) return 20;
    return 17;
  }

  static double modalBodySize(double width) {
    if (width >= desktopMin) return 14;
    if (width >= tabletMin) return 13.5;
    return 12.5;
  }

  /// Diálogos de detalle anchos (p. ej. administración de cierres).
  static double wideDialogMaxWidth(double screenWidth) {
    final pad = dialogInsetPadding(screenWidth);
    final avail = screenWidth - pad.left - pad.right;
    return avail.clamp(300.0, 920.0);
  }
}
