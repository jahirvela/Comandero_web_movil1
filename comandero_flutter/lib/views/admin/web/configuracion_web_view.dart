import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';
import '../../../services/configuracion_service.dart';
import '../../../services/impresoras_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/cash_ui_responsive.dart';
import '../../../utils/plantilla_ticket_friendly.dart';

/// Mensaje legible para errores al generar clave (red, CORS, servidor, etc.).
String _mensajeErrorGenerarClave(Object e) {
  final s = e.toString().toLowerCase();
  if (s.contains('socket') ||
      s.contains('connection') ||
      s.contains('failed')) {
    return 'No se pudo conectar al servidor. Verifica que la API esté en api.comancleth.com (o la URL configurada).';
  }
  if (s.contains('timeout'))
    return 'Tiempo de espera agotado. El servidor no respondió.';
  if (s.contains('404'))
    return 'Ruta no encontrada en el servidor. ¿El backend está actualizado?';
  if (s.contains('500'))
    return 'Error en el servidor. Revisa los logs del backend.';
  if (s.contains('403') || s.contains('401'))
    return 'Sin permiso o sesión expirada. Vuelve a iniciar sesión.';
  return e.toString().replaceFirst('Exception: ', '');
}

/// Vista de configuración del negocio (IVA y futuras opciones). Solo administrador.
class ConfiguracionWebView extends StatefulWidget {
  const ConfiguracionWebView({super.key});

  @override
  State<ConfiguracionWebView> createState() => _ConfiguracionWebViewState();
}

class _ConfiguracionWebViewState extends State<ConfiguracionWebView> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfig();
      context.read<AdminController>().loadImpresoras();
      context.read<AdminController>().loadPlantillaTicket();
    });
  }

  Future<void> _loadConfig() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Breve pausa en web para que el token esté disponible (evitar 401 en primera petición)
      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      }
      final controller = context.read<AdminController>();
      await controller.loadConfiguracion();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = context.read<AdminController>().configuracionError;
        });
      }
    }
  }

  Future<void> _toggleIva(bool value) async {
    final controller = context.read<AdminController>();
    await controller.actualizarIvaHabilitado(value);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 1200;
            final isTablet = constraints.maxWidth > 800;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuración del negocio',
                    style: TextStyle(
                      fontSize: isDesktop ? 24.0 : (isTablet ? 20.0 : 18.0),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Opciones generales para México CDMX. Solo el administrador puede modificar.',
                    style: TextStyle(
                      fontSize: isDesktop ? 14.0 : 12.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_loading) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Cargando configuración...',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Material(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade700,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: _loading ? null : _loadConfig,
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    _buildIvaCard(controller, isDesktop, isTablet),
                    const SizedBox(height: 24),
                    _buildImpresorasCard(
                      context,
                      controller,
                      isDesktop,
                      isTablet,
                    ),
                    const SizedBox(height: 24),
                    _buildPlantillaTicketsCard(
                      context,
                      controller,
                      isDesktop,
                      isTablet,
                    ),
                    const SizedBox(height: 24),
                    _buildCajaConfigCard(
                      context,
                      controller,
                      isDesktop,
                      isTablet,
                    ),
                    const SizedBox(height: 24),
                    _buildCajonCard(context, controller, isDesktop, isTablet),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlantillaTicketsCard(
    BuildContext context,
    AdminController controller,
    bool isDesktop,
    bool isTablet,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
        child: _PlantillaTicketsCardContent(
          controller: controller,
          isDesktop: isDesktop,
          isTablet: isTablet,
          onError: () => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildCajonCard(
    BuildContext context,
    AdminController controller,
    bool isDesktop,
    bool isTablet,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
        child: _CajonCardContent(
          controller: controller,
          isDesktop: isDesktop,
          isTablet: isTablet,
          onError: () => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildImpresorasCard(
    BuildContext context,
    AdminController controller,
    bool isDesktop,
    bool isTablet,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.print, size: 28, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Impresoras térmicas',
                    style: TextStyle(
                      fontSize: isDesktop ? 18.0 : 16.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: controller.isLoadingImpresoras
                      ? null
                      : () => _showImpresoraDialog(
                          context,
                          controller,
                          isDesktop: isDesktop,
                          isTablet: isTablet,
                        ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'USB, red (IP), Bluetooth o simulación. Configure nombre, tipo, tamaño de ticket (58/80 mm) y si imprime ticket y/o comanda.',
              style: TextStyle(
                fontSize: isDesktop ? 14.0 : 13.0,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (controller.impresorasError != null) ...[
              const SizedBox(height: 12),
              Text(
                controller.impresorasError!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            if (controller.isLoadingImpresoras)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.impresoras.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'No hay impresoras configuradas. Agregue una para imprimir tickets y comandas.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.impresoras.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = controller.impresoras[index];
                  return ListTile(
                    leading: Icon(
                      p.activo ? Icons.print : Icons.print_disabled,
                      color: p.activo ? AppColors.primary : Colors.grey,
                    ),
                    title: Text(
                      p.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: p.activo
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    subtitle: Text(
                      '${p.tipo.label} · ${p.paperWidth} mm${p.marcaModelo != null && p.marcaModelo!.isNotEmpty ? " · ${p.marcaModelo}" : ""}\n'
                      'Ticket: ${p.imprimeTicket ? "Sí" : "No"} · Comanda: ${p.imprimeComanda ? "Sí" : "No"}${p.impresionRemota ? " · Remota" : ""}${p.tieneClaveAgente ? " · Clave configurada" : ""}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (p.impresionRemota)
                          IconButton(
                            icon: const Icon(Icons.key),
                            tooltip: 'Generar clave para agente',
                            onPressed: () => _showGenerarClaveAgenteDialog(
                              controller,
                              p,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showImpresoraDialog(
                            context,
                            controller,
                            impresora: p,
                            isDesktop: isDesktop,
                            isTablet: isTablet,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade700,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Eliminar impresora'),
                                content: Text('¿Eliminar "${p.nombre}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(
                                      'Eliminar',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              await controller.deleteImpresora(p.id);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGenerarClaveAgenteDialog(
    AdminController controller,
    ImpresoraModel p,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generar clave para agente'),
        content: Text(
          'Se generará una nueva clave para la impresora "${p.nombre}". '
          'Péguela en el archivo .bat del PC donde está la impresora (variable AGENT_API_KEY). '
          'Si ya había una clave, dejará de funcionar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Generar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    // Mostrar loading mientras se genera la clave (mismo navigator que el cierre en finally)
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Generando clave...'),
          ],
        ),
      ),
    );

    String? clave;
    String? errorParaMostrar;
    try {
      clave = await controller
          .generarClaveAgente(p.id)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(
                'El servidor no respondió a tiempo. Comprueba que el backend esté en marcha (api.comancleth.com o la URL configurada).',
              );
            },
          );
    } on TimeoutException catch (e) {
      errorParaMostrar = e.message ?? 'Tiempo de espera agotado';
      clave = null;
    } catch (e, st) {
      clave = null;
      errorParaMostrar =
          controller.impresorasError ?? _mensajeErrorGenerarClave(e);
      // Log en consola para depurar en producción (pestaña Console de DevTools)
      debugPrint('Error al generar clave agente: $e');
      debugPrint('Stack: $st');
    } finally {
      // Cerrar siempre el diálogo de carga (mismo overlay que showDialog anterior).
      if (mounted) {
        try {
          final nav = Navigator.of(context, rootNavigator: true);
          if (nav.canPop()) nav.pop();
        } catch (_) {}
      }
    }

    if (!mounted) return;
    if (clave == null || clave.isEmpty) {
      final mensaje =
          errorParaMostrar ??
          controller.impresorasError ??
          'No se pudo generar la clave';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    final String claveParaMostrar = clave;
    // Mostrar la clave de forma clara y visible en la interfaz
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.key, color: AppColors.primary, size: 28),
            const SizedBox(width: 8),
            const Text('Clave para el agente'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copie esta clave y péguela en el archivo .bat del PC con la impresora (variable AGENT_API_KEY). No caduca.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: SelectableText(
                  claveParaMostrar,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Impresora: ${p.nombre}',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar al portapapeles'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: claveParaMostrar));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clave copiada al portapapeles')),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImpresoraDialog(
    BuildContext context,
    AdminController controller, {
    ImpresoraModel? impresora,
    required bool isDesktop,
    required bool isTablet,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => _ImpresoraFormDialog(
        impresora: impresora,
        isDesktop: isDesktop,
        isTablet: isTablet,
        onSave: (body) async {
          Navigator.pop(ctx);
          if (impresora != null) {
            await controller.updateImpresora(impresora.id, body);
          } else {
            await controller.createImpresora(body);
          }
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  Widget _buildIvaCard(
    AdminController controller,
    bool isDesktop,
    bool isTablet,
  ) {
    final ivaHabilitado = controller.ivaHabilitado;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, size: 28, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'IVA (México CDMX)',
                  style: TextStyle(
                    fontSize: isDesktop ? 18.0 : 16.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Si está habilitado, en tickets y cobros se calculará y mostrará el IVA (16%).',
              style: TextStyle(
                fontSize: isDesktop ? 14.0 : 13.0,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Switch(
                  value: ivaHabilitado,
                  onChanged: controller.isSavingConfiguracion
                      ? null
                      : (value) => _toggleIva(value),
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  ivaHabilitado ? 'IVA habilitado' : 'IVA deshabilitado',
                  style: TextStyle(
                    fontSize: isDesktop ? 15.0 : 14.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (controller.isSavingConfiguracion) ...[
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCajaConfigCard(
    BuildContext context,
    AdminController controller,
    bool isDesktop,
    bool isTablet,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
        child: _CajaConfigCardContent(
          controller: controller,
          isDesktop: isDesktop,
          isTablet: isTablet,
          onSaved: () {
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }
}

class _TurnoRowControllers {
  final TextEditingController nombre;
  final TextEditingController inicio;
  final TextEditingController fin;

  _TurnoRowControllers({
    required String n,
    required String i,
    required String f,
  })  : nombre = TextEditingController(text: n),
        inicio = TextEditingController(text: i),
        fin = TextEditingController(text: f);

  void dispose() {
    nombre.dispose();
    inicio.dispose();
    fin.dispose();
  }
}

String? _normalizeHoraCaja(String raw) {
  final t = raw.trim();
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(t);
  if (m == null) return null;
  final h = int.tryParse(m.group(1)!) ?? -1;
  final min = int.tryParse(m.group(2)!) ?? -1;
  if (h < 0 || h > 23 || min < 0 || min > 59) return null;
  return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
}

class _CajaConfigCardContent extends StatefulWidget {
  final AdminController controller;
  final bool isDesktop;
  final bool isTablet;
  final VoidCallback onSaved;

  const _CajaConfigCardContent({
    required this.controller,
    required this.isDesktop,
    required this.isTablet,
    required this.onSaved,
  });

  @override
  State<_CajaConfigCardContent> createState() => _CajaConfigCardContentState();
}

class _CajaConfigCardContentState extends State<_CajaConfigCardContent> {
  late String _modo;
  final List<_TurnoRowControllers> _rows = [];

  @override
  void initState() {
    super.initState();
    _loadFromController();
  }

  void _loadFromController() {
    for (final r in _rows) {
      r.dispose();
    }
    _rows.clear();
    final c = widget.controller.configuracionCaja;
    _modo = c.modo == 'turnos' ? 'turnos' : 'diario';
    final src = c.turnos.isNotEmpty
        ? c.turnos
        : (_modo == 'turnos'
            ? ConfiguracionCajaModel.turnosPorDefecto()
            : <CajaTurnoSlotModel>[]);
    for (final t in src) {
      _rows.add(
        _TurnoRowControllers(
          n: t.nombre,
          i: t.inicio,
          f: t.fin,
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_modo == 'turnos') {
      if (_rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agrega al menos un turno')),
        );
        return;
      }
      final turnos = <Map<String, dynamic>>[];
      final codigosGenerados = <String>{};
      for (var idx = 0; idx < _rows.length; idx++) {
        final r = _rows[idx];
        final nombre = r.nombre.text.trim();
        if (nombre.isEmpty) continue;
        final hi = _normalizeHoraCaja(r.inicio.text);
        final hf = _normalizeHoraCaja(r.fin.text);
        if (hi == null || hf == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Horario inválido en turno "$nombre". Usa formato 24h HH:mm (ej. 09:00).',
              ),
            ),
          );
          return;
        }
        final codigo = generarCodigoTurnoCajaUnico(
          nombreVisible: nombre,
          indiceFila: idx,
          codigosUsados: codigosGenerados,
        );
        turnos.add({
          'codigo': codigo,
          'nombre': nombre,
          'inicio': hi,
          'fin': hf,
        });
      }
      if (turnos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Define al menos un turno completo')),
        );
        return;
      }
      await widget.controller.actualizarConfiguracionCaja({
        'modo': 'turnos',
        'turnos': turnos,
      });
    } else {
      await widget.controller.actualizarConfiguracionCaja({'modo': 'diario'});
    }
    if (mounted) {
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración de caja guardada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = widget.isDesktop;
    final saving = widget.controller.isSavingConfiguracion;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final compactTurnos = w < CashUiResponsive.tabletMin;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, size: 28, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Caja: cierre diario o por turnos',
                    style: TextStyle(
                      fontSize: isDesktop ? 18.0 : 16.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'En modo diario hay una sola sesión de caja por día. En turnos, el cajero elige el turno al abrir y el cierre queda ligado a ese turno (horarios referencia CDMX).',
              style: TextStyle(
                fontSize: isDesktop ? 14.0 : 13.0,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'diario', label: Text('Diario')),
                  ButtonSegment(value: 'turnos', label: Text('Por turnos')),
                ],
                selected: {_modo},
                onSelectionChanged: saving
                    ? null
                    : (Set<String> sel) {
                        if (sel.isEmpty) return;
                        setState(() {
                          _modo = sel.first;
                          if (_modo == 'turnos' && _rows.isEmpty) {
                            final c = widget.controller.configuracionCaja;
                            final src = c.turnos.isNotEmpty
                                ? c.turnos
                                : ConfiguracionCajaModel.turnosPorDefecto();
                            for (final t in src) {
                              _rows.add(
                                _TurnoRowControllers(
                                  n: t.nombre,
                                  i: t.inicio,
                                  f: t.fin,
                                ),
                              );
                            }
                          }
                        });
                      },
              ),
            ),
            if (_modo == 'turnos') ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Turnos (máx. 8)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: saving || _rows.length >= 8
                        ? null
                        : () {
                            setState(() {
                              _rows.add(
                                _TurnoRowControllers(
                                  n: '',
                                  i: '09:00',
                                  f: '18:00',
                                ),
                              );
                            });
                          },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              for (var i = 0; i < _rows.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (compactTurnos) ...[
                        TextField(
                          controller: _rows[i].nombre,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del turno',
                            hintText: 'Mañana',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _rows[i].inicio,
                                decoration: const InputDecoration(
                                  labelText: 'Inicio (HH:mm)',
                                  hintText: '07:00',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _rows[i].fin,
                                decoration: const InputDecoration(
                                  labelText: 'Fin (HH:mm)',
                                  hintText: '14:00',
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Quitar turno',
                              onPressed: saving || _rows.length <= 1
                                  ? null
                                  : () {
                                      setState(() {
                                        _rows.removeAt(i).dispose();
                                      });
                                    },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _rows[i].nombre,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre del turno',
                                  hintText: 'Mañana',
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Quitar turno',
                              onPressed: saving || _rows.length <= 1
                                  ? null
                                  : () {
                                      setState(() {
                                        _rows.removeAt(i).dispose();
                                      });
                                    },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _rows[i].inicio,
                                decoration: const InputDecoration(
                                  labelText: 'Inicio (HH:mm)',
                                  hintText: '07:00',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _rows[i].fin,
                                decoration: const InputDecoration(
                                  labelText: 'Fin (HH:mm)',
                                  hintText: '14:00',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 24),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: saving ? null : _guardar,
                icon: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save, size: 20),
                label: Text(saving ? 'Guardando...' : 'Guardar caja'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CajonCardContent extends StatefulWidget {
  final AdminController controller;
  final bool isDesktop;
  final bool isTablet;
  final VoidCallback onError;

  const _CajonCardContent({
    required this.controller,
    required this.isDesktop,
    required this.isTablet,
    required this.onError,
  });

  @override
  State<_CajonCardContent> createState() => _CajonCardContentState();
}

class _CajonCardContentState extends State<_CajonCardContent> {
  late bool _habilitado;
  late int? _impresoraId;
  late bool _abrirEnEfectivo;
  late bool _abrirEnTarjeta;
  late CajonTipoConexion _tipoConexion;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;

  @override
  void initState() {
    super.initState();
    _syncFromController();
    _marcaController = TextEditingController(
      text: widget.controller.configuracionCajon.marca ?? '',
    );
    _modeloController = TextEditingController(
      text: widget.controller.configuracionCajon.modelo ?? '',
    );
  }

  void _syncFromController() {
    final c = widget.controller.configuracionCajon;
    _habilitado = c.habilitado;
    _impresoraId = c.impresoraId;
    _abrirEnEfectivo = c.abrirEnEfectivo;
    _abrirEnTarjeta = c.abrirEnTarjeta;
    _tipoConexion = c.tipoConexion;
  }

  @override
  void didUpdateWidget(covariant _CajonCardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _syncFromController();
      _marcaController.text = widget.controller.configuracionCajon.marca ?? '';
      _modeloController.text =
          widget.controller.configuracionCajon.modelo ?? '';
    }
  }

  @override
  void dispose() {
    _marcaController.dispose();
    _modeloController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final cajon = <String, dynamic>{
      'habilitado': _habilitado,
      'abrirEnEfectivo': _abrirEnEfectivo,
      'abrirEnTarjeta': _abrirEnTarjeta,
      'tipoConexion': _tipoConexion.value,
      'impresoraId': _tipoConexion == CajonTipoConexion.viaImpresora
          ? _impresoraId
          : null,
      'marca': _marcaController.text.trim().isEmpty
          ? null
          : _marcaController.text.trim(),
      'modelo': _modeloController.text.trim().isEmpty
          ? null
          : _modeloController.text.trim(),
    };
    await widget.controller.actualizarConfiguracionCajon(cajon);
    if (mounted) widget.onError();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isDesktop = widget.isDesktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.point_of_sale, size: 28, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cajón de dinero',
                style: TextStyle(
                  fontSize: isDesktop ? 18.0 : 16.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Configure si el cajón se abre en pagos en efectivo o con tarjeta. Tipo de conexión: vía impresora térmica, red o USB. Marca y modelo son opcionales.',
          style: TextStyle(
            fontSize: isDesktop ? 14.0 : 13.0,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'Habilitar cajón',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                fontSize: isDesktop ? 15.0 : 14.0,
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: _habilitado,
              onChanged: controller.isSavingConfiguracion
                  ? null
                  : (v) => setState(() => _habilitado = v),
              activeColor: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CajonTipoConexion>(
          value: _tipoConexion,
          decoration: const InputDecoration(
            labelText: 'Tipo de conexión',
            border: OutlineInputBorder(),
          ),
          items: CajonTipoConexion.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
          onChanged: controller.isSavingConfiguracion
              ? null
              : (v) => setState(
                  () => _tipoConexion = v ?? CajonTipoConexion.viaImpresora,
                ),
        ),
        if (_tipoConexion == CajonTipoConexion.viaImpresora) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _impresoraId,
            decoration: const InputDecoration(
              labelText: 'Impresora térmica asociada',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('— Sin asignar —'),
              ),
              ...controller.impresoras.map(
                (p) => DropdownMenuItem(value: p.id, child: Text(p.nombre)),
              ),
            ],
            onChanged: controller.isSavingConfiguracion
                ? null
                : (v) => setState(() => _impresoraId = v),
          ),
        ],
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Abrir cajón en pagos en efectivo'),
          value: _abrirEnEfectivo,
          onChanged: controller.isSavingConfiguracion
              ? null
              : (v) => setState(() => _abrirEnEfectivo = v ?? true),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primary,
        ),
        CheckboxListTile(
          title: const Text('Abrir cajón en pagos con tarjeta'),
          value: _abrirEnTarjeta,
          onChanged: controller.isSavingConfiguracion
              ? null
              : (v) => setState(() => _abrirEnTarjeta = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primary,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _marcaController,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          decoration: const InputDecoration(
            labelText: 'Marca (opcional)',
            hintText: 'Ej: ZKTECO, Epson',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _modeloController,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          decoration: const InputDecoration(
            labelText: 'Modelo (opcional)',
            hintText: 'Ej: CD-01, T88',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            FilledButton.icon(
              onPressed: controller.isSavingConfiguracion
                  ? null
                  : () => _guardar(),
              icon: controller.isSavingConfiguracion
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, size: 18),
              label: Text(
                controller.isSavingConfiguracion
                    ? 'Guardando…'
                    : 'Guardar configuración cajón',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ImpresoraFormDialog extends StatefulWidget {
  final ImpresoraModel? impresora;
  final bool isDesktop;
  final bool isTablet;
  final Future<void> Function(Map<String, dynamic> body) onSave;
  final VoidCallback onCancel;

  const _ImpresoraFormDialog({
    this.impresora,
    required this.isDesktop,
    required this.isTablet,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_ImpresoraFormDialog> createState() => _ImpresoraFormDialogState();
}

class _ImpresoraFormDialogState extends State<_ImpresoraFormDialog> {
  late final TextEditingController _nombreController;
  late final TextEditingController _deviceController;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _marcaController;

  late TipoImpresora _tipo;
  late int _paperWidth;
  late bool _imprimeTicket;
  late bool _imprimeComanda;
  late bool _impresionRemota;
  late bool _activo;

  @override
  void initState() {
    super.initState();
    final p = widget.impresora;
    _nombreController = TextEditingController(text: p?.nombre ?? '');
    _deviceController = TextEditingController(text: p?.device ?? '');
    _hostController = TextEditingController(text: p?.host ?? '');
    _portController = TextEditingController(
      text: p?.port?.toString() ?? '9100',
    );
    _marcaController = TextEditingController(text: p?.marcaModelo ?? '');
    _tipo = p?.tipo ?? TipoImpresora.usb;
    _paperWidth = p?.paperWidth ?? 80;
    _imprimeTicket = p?.imprimeTicket ?? true;
    _imprimeComanda = p?.imprimeComanda ?? false;
    _impresionRemota = p?.impresionRemota ?? false;
    _activo = p?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _deviceController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _marcaController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildBody() {
    final body = <String, dynamic>{
      'nombre': _nombreController.text.trim(),
      'tipo': _tipo.value,
      'paperWidth': _paperWidth,
      'imprimeTicket': _imprimeTicket,
      'imprimeComanda': _imprimeComanda,
      'impresionRemota': _impresionRemota,
      'marcaModelo': _marcaController.text.trim().isEmpty
          ? null
          : _marcaController.text.trim(),
    };
    if (_tipo == TipoImpresora.usb || _tipo == TipoImpresora.bluetooth) {
      body['device'] = _deviceController.text.trim().isEmpty
          ? null
          : _deviceController.text.trim();
      body['host'] = null;
      body['port'] = null;
    } else if (_tipo == TipoImpresora.tcp) {
      body['device'] = null;
      body['host'] = _hostController.text.trim().isEmpty
          ? null
          : _hostController.text.trim();
      body['port'] = _portController.text.trim().isEmpty
          ? null
          : (int.tryParse(_portController.text) ?? 9100);
    } else {
      body['device'] = _deviceController.text.trim().isEmpty
          ? null
          : _deviceController.text.trim();
      body['host'] = null;
      body['port'] = null;
    }
    if (widget.impresora != null) body['activo'] = _activo;
    return body;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.impresora == null ? 'Agregar impresora' : 'Editar impresora',
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: widget.isDesktop ? 420 : 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej: Caja 1, Cocina',
                ),
                controller: _nombreController,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TipoImpresora>(
                value: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de conexión',
                ),
                items: TipoImpresora.values
                    .map(
                      (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _tipo = v ?? TipoImpresora.usb),
              ),
              const SizedBox(height: 12),
              if (_tipo == TipoImpresora.usb ||
                  _tipo == TipoImpresora.bluetooth)
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Nombre de impresora (Windows)',
                    hintText: 'Como aparece en Dispositivos e impresoras',
                  ),
                  controller: _deviceController,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
              if (_tipo == TipoImpresora.tcp) ...[
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'IP',
                    hintText: '192.168.1.50',
                  ),
                  controller: _hostController,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Puerto',
                    hintText: '9100',
                  ),
                  controller: _portController,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  keyboardType: TextInputType.number,
                ),
              ],
              if (_tipo == TipoImpresora.simulation)
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Carpeta (simulación)',
                    hintText: 'ruta/carpeta',
                  ),
                  controller: _deviceController,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: kPaperWidths.contains(_paperWidth) ? _paperWidth : 80,
                decoration: const InputDecoration(labelText: 'Ancho de papel'),
                items: const [
                  DropdownMenuItem(value: 57, child: Text('57 mm')),
                  DropdownMenuItem(value: 58, child: Text('58 mm')),
                  DropdownMenuItem(value: 72, child: Text('72 mm')),
                  DropdownMenuItem(value: 80, child: Text('80 mm')),
                ],
                onChanged: (v) => setState(() => _paperWidth = v ?? 80),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Marca / modelo (opcional)',
                  hintText: 'Ej: Epson TM-T20, ZKTECO',
                ),
                controller: _marcaController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),
              const SizedBox(height: 16),
              Theme(
                data: Theme.of(context).copyWith(
                  checkboxTheme: CheckboxThemeData(
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected))
                        return AppColors.primary;
                      return null;
                    }),
                    checkColor: WidgetStateProperty.all(Colors.white),
                  ),
                  switchTheme: SwitchThemeData(
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected))
                        return AppColors.primary;
                      return null;
                    }),
                    trackColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected))
                        return AppColors.primary.withValues(alpha: 0.5);
                      return null;
                    }),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      title: const Text('Imprime tickets de cobro'),
                      value: _imprimeTicket,
                      onChanged: (v) =>
                          setState(() => _imprimeTicket = v ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Imprime comandas (cocina)'),
                      value: _imprimeComanda,
                      onChanged: (v) =>
                          setState(() => _imprimeComanda = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Impresión remota'),
                      subtitle: const Text(
                        'Cuando el servidor está en la nube y la impresora es USB en un PC: activar y ejecutar el agente en ese PC.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _impresionRemota,
                      onChanged: (v) =>
                          setState(() => _impresionRemota = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (widget.impresora != null)
                      SwitchListTile(
                        title: const Text('Activa'),
                        value: _activo,
                        onChanged: (v) => setState(() => _activo = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            if (_nombreController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('El nombre es obligatorio')),
              );
              return;
            }
            await widget.onSave(_buildBody());
          },
          child: Text(widget.impresora == null ? 'Agregar' : 'Guardar'),
        ),
      ],
    );
  }
}

class _PlantillaTicketsCardContent extends StatefulWidget {
  final AdminController controller;
  final bool isDesktop;
  final bool isTablet;
  final VoidCallback onError;

  const _PlantillaTicketsCardContent({
    required this.controller,
    required this.isDesktop,
    required this.isTablet,
    required this.onError,
  });

  @override
  State<_PlantillaTicketsCardContent> createState() =>
      _PlantillaTicketsCardContentState();
}

class _PlantillaTicketsCardContentState
    extends State<_PlantillaTicketsCardContent> {
  late final TextEditingController _contenidoController;
  late final TextEditingController _lineaItemController;
  bool _initialized = false;
  String _lastTipo = '';
  String _lastPlantillaTipo = '';

  @override
  void initState() {
    super.initState();
    _contenidoController = TextEditingController();
    _lineaItemController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant _PlantillaTicketsCardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final c = widget.controller;
    if (c.selectedTipoPlantilla != _lastTipo) {
      _lastTipo = c.selectedTipoPlantilla;
      _initialized = false;
    }
    final p = c.plantillaTicket;
    if (p != null &&
        !c.isLoadingPlantillaTicket &&
        !_initialized &&
        p.tipoDocumento == c.selectedTipoPlantilla) {
      _initialized = true;
      _lastPlantillaTipo = p.tipoDocumento;
      _contenidoController.text =
          PlantillaTicketFriendly.contenidoTecnicoAFriendly(p.contenido);
      _lineaItemController.text = PlantillaTicketFriendly.lineaTecnicaAFriendly(
        p.plantillaLineaItem,
      );
    }
  }

  @override
  void dispose() {
    _contenidoController.dispose();
    _lineaItemController.dispose();
    super.dispose();
  }

  void _syncFromPlantilla(PlantillaImpresionModel? p) {
    if (p == null || _initialized) return;
    _initialized = true;
    _lastPlantillaTipo = p.tipoDocumento;
    _contenidoController.text =
        PlantillaTicketFriendly.contenidoTecnicoAFriendly(p.contenido);
    _lineaItemController.text = PlantillaTicketFriendly.lineaTecnicaAFriendly(
      p.plantillaLineaItem,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final isDesktop = widget.isDesktop;
    if (c.selectedTipoPlantilla != _lastTipo) {
      _lastTipo = c.selectedTipoPlantilla;
      _initialized = false;
      _lastPlantillaTipo = '';
    }
    final p = c.plantillaTicket;
    if (p != null &&
        !c.isLoadingPlantillaTicket &&
        p.tipoDocumento == c.selectedTipoPlantilla &&
        _lastPlantillaTipo != p.tipoDocumento) {
      _syncFromPlantilla(p);
    }
    final labelActual =
        AdminController.tiposPlantilla.firstWhere(
          (e) => e['tipo'] == c.selectedTipoPlantilla,
          orElse: () => {
            'tipo': c.selectedTipoPlantilla,
            'label': c.selectedTipoPlantilla,
          },
        )['label'] ??
        c.selectedTipoPlantilla;
    if (c.isLoadingPlantillaTicket && c.plantillaTicket == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plantillas de tickets y comandas',
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.receipt_long, size: 28, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Plantillas de tickets y comandas',
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Elija el tipo de ticket (cobro general, mesa, para llevar, etc.). Si no hay plantilla guardada para ese tipo, se usa la de cobro general.',
          style: TextStyle(
            fontSize: isDesktop ? 14 : 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: c.selectedTipoPlantilla,
          decoration: InputDecoration(
            labelText: 'Tipo de plantilla',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: AdminController.tiposPlantilla
              .map(
                (e) => DropdownMenuItem(
                  value: e['tipo'],
                  child: Text(e['label']!),
                ),
              )
              .toList(),
          onChanged: (String? value) {
            if (value != null) c.setSelectedTipoPlantilla(value);
          },
        ),
        if (c.plantillaTicketError != null) ...[
          const SizedBox(height: 12),
          Text(
            c.plantillaTicketError!,
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _contenidoController,
          maxLines: 22,
          minLines: 12,
          decoration: InputDecoration(
            labelText: 'Contenido: $labelActual',
            hintText:
                'Escriba texto normal. Para datos del sistema use comillas: "Nombre del restaurante", "Total", etc.',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            alignLabelWithHint: true,
          ),
          style: TextStyle(fontSize: isDesktop ? 14 : 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _lineaItemController,
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(
            labelText: 'Formato línea de ítem (opcional)',
            hintText:
                'Ejemplo: "Cantidad"  "Descripción del producto"  "Moneda" "Total"',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          style: TextStyle(fontSize: isDesktop ? 14 : 13),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cómo funciona',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Lo que escriba fuera de comillas se imprime tal cual. '
                'Entre comillas va un nombre reservado: el sistema lo sustituye por el dato real al imprimir. '
                'Puede copiar los textos de las listas de abajo y pegarlos en la plantilla. '
                'También se acepta el formato antiguo (campo nombre del restaurante, etc.).',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Marcadores del contenido del ticket',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                PlantillaTicketFriendly.ayudaListaMarcadoresContenido(),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  fontFamily: 'monospace',
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Marcadores para la línea de cada producto',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                PlantillaTicketFriendly.ayudaListaMarcadoresLinea(),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  fontFamily: 'monospace',
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Formato de texto (sin comillas)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              const SelectableText(
                '(inicio centrado)  …  (fin centrado)\n'
                '(inicio negrita)  …  (fin negrita)',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Campo personalizado del sistema: "Personalizado: NOMBRE_CLAVE" (se guarda como {{NOMBRE_CLAVE}}). '
                'Formato antiguo: campo personalizado: NOMBRE_CLAVE.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: c.isSavingPlantillaTicket
                  ? null
                  : () {
                      final tipo = c.selectedTipoPlantilla;
                      _contenidoController.text =
                          PlantillaTicketFriendly.contenidoBaseFriendlyPorTipo(
                            tipo,
                          );
                      _lineaItemController.text =
                          PlantillaTicketFriendly.lineaItemBaseFriendlyPorTipo(
                            tipo,
                          );
                    },
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('Cargar base legible'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: c.isSavingPlantillaTicket
                    ? null
                    : () async {
                        _initialized = true;
                        final ok = await c.savePlantillaTicket(
                          PlantillaTicketFriendly.contenidoFriendlyATecnico(
                            _contenidoController.text,
                          ),
                          PlantillaTicketFriendly.lineaFriendlyATecnica(
                            _lineaItemController.text,
                          ),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok ? 'Plantilla guardada' : 'Error al guardar',
                              ),
                            ),
                          );
                        }
                      },
                icon: c.isSavingPlantillaTicket
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save, size: 20),
                label: Text(
                  c.isSavingPlantillaTicket ? 'Guardando...' : 'Guardar plantilla',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
