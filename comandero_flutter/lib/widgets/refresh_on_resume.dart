import 'package:flutter/material.dart';

/// Ejecuta una recarga cuando la app vuelve a `resumed` (ej. regresas a la pestaña,
/// desbloqueas el celular o vuelves a la pantalla).
///
/// Esto ayuda a evitar pantallas "vacías" cuando el socket se cae o el token
/// expira mientras la app estuvo en segundo plano.
class RefreshOnResume extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onResume;
  final Duration minPause;
  final bool Function()? shouldRun;

  const RefreshOnResume({
    super.key,
    required this.child,
    required this.onResume,
    this.minPause = const Duration(seconds: 30),
    this.shouldRun,
  });

  @override
  State<RefreshOnResume> createState() => _RefreshOnResumeState();
}

class _RefreshOnResumeState extends State<RefreshOnResume>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;
  bool _isRunning = false;
  bool _hasPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt = DateTime.now();
      _hasPaused = true;
      return;
    }

    if (state != AppLifecycleState.resumed) return;

    if (!_hasPaused) return; // Evitar recarga al abrir por primera vez.

    final shouldRun = widget.shouldRun?.call() ?? true;
    if (!shouldRun) return;

    final pausedAt = _pausedAt;
    final pauseDuration = pausedAt == null
        ? widget.minPause
        : DateTime.now().difference(pausedAt);

    if (pauseDuration < widget.minPause) return;
    _hasPaused = false;
    _run();
  }

  Future<void> _run() async {
    if (_isRunning) return;
    _isRunning = true;
    try {
      await widget.onResume();
    } finally {
      _isRunning = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

