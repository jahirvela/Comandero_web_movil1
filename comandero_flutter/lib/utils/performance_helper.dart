import 'dart:async';
import 'package:flutter/foundation.dart';

/// Helper para optimizar rendimiento en ChangeNotifier
/// Previene múltiples llamadas a notifyListeners en un corto período
class DebounceNotifier {
  Timer? _debounceTimer;
  final Duration debounceDelay;
  VoidCallback? _pendingCallback;

  DebounceNotifier({this.debounceDelay = const Duration(milliseconds: 100)});

  /// Ejecutar callback con debounce
  void debounce(VoidCallback callback) {
    _pendingCallback = callback;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDelay, () {
      final callback = _pendingCallback;
      _pendingCallback = null;
      callback?.call();
    });
  }

  /// Cancelar debounce pendiente
  void cancel() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pendingCallback = null;
  }

  /// Dispose del helper
  void dispose() {
    cancel();
  }
}

/// Mixin para agregar debounce a ChangeNotifier
mixin DebounceChangeNotifier on ChangeNotifier {
  DebounceNotifier? _debouncer;
  
  DebounceNotifier get debouncer {
    _debouncer ??= DebounceNotifier(
      debounceDelay: const Duration(milliseconds: 50), // Muy rápido para UI
    );
    return _debouncer!;
  }

  /// notifyListeners con debounce (para updates frecuentes)
  void notifyListenersDebounced() {
    debouncer.debounce(() {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _debouncer?.dispose();
    super.dispose();
  }
}

