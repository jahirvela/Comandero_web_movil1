import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';
import '../../../services/configuracion_service.dart';
import '../../../services/impresoras_service.dart';
import '../../../utils/app_colors.dart';

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
              padding: EdgeInsets.all(isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0)),
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
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                                    Icon(Icons.error_outline, color: Colors.red.shade700),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700))),
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
                    _buildImpresorasCard(context, controller, isDesktop, isTablet),
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
                      : () => _showImpresoraDialog(context, controller, isDesktop: isDesktop, isTablet: isTablet),
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
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                        color: p.activo ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    subtitle: Text(
                      '${p.tipo.label} · ${p.paperWidth} mm${p.marcaModelo != null && p.marcaModelo!.isNotEmpty ? " · ${p.marcaModelo}" : ""}\n'
                      'Ticket: ${p.imprimeTicket ? "Sí" : "No"} · Comanda: ${p.imprimeComanda ? "Sí" : "No"}',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Eliminar impresora'),
                                content: Text('¿Eliminar "${p.nombre}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text('Eliminar', style: TextStyle(color: Colors.red.shade700)),
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

  Widget _buildIvaCard(AdminController controller, bool isDesktop, bool isTablet) {
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
    _marcaController = TextEditingController(text: widget.controller.configuracionCajon.marca ?? '');
    _modeloController = TextEditingController(text: widget.controller.configuracionCajon.modelo ?? '');
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
      _modeloController.text = widget.controller.configuracionCajon.modelo ?? '';
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
      'impresoraId': _tipoConexion == CajonTipoConexion.viaImpresora ? _impresoraId : null,
      'marca': _marcaController.text.trim().isEmpty ? null : _marcaController.text.trim(),
      'modelo': _modeloController.text.trim().isEmpty ? null : _modeloController.text.trim(),
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
              : (v) => setState(() => _tipoConexion = v ?? CajonTipoConexion.viaImpresora),
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
              const DropdownMenuItem(value: null, child: Text('— Sin asignar —')),
              ...controller.impresoras
                  .map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre))),
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
              onPressed: controller.isSavingConfiguracion ? null : () => _guardar(),
              icon: controller.isSavingConfiguracion
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save, size: 18),
              label: Text(controller.isSavingConfiguracion ? 'Guardando…' : 'Guardar configuración cajón'),
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
  late bool _activo;

  @override
  void initState() {
    super.initState();
    final p = widget.impresora;
    _nombreController = TextEditingController(text: p?.nombre ?? '');
    _deviceController = TextEditingController(text: p?.device ?? '');
    _hostController = TextEditingController(text: p?.host ?? '');
    _portController = TextEditingController(text: p?.port?.toString() ?? '9100');
    _marcaController = TextEditingController(text: p?.marcaModelo ?? '');
    _tipo = p?.tipo ?? TipoImpresora.usb;
    _paperWidth = p?.paperWidth ?? 80;
    _imprimeTicket = p?.imprimeTicket ?? true;
    _imprimeComanda = p?.imprimeComanda ?? false;
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
      'marcaModelo': _marcaController.text.trim().isEmpty ? null : _marcaController.text.trim(),
    };
    if (_tipo == TipoImpresora.usb || _tipo == TipoImpresora.bluetooth) {
      body['device'] = _deviceController.text.trim().isEmpty ? null : _deviceController.text.trim();
      body['host'] = null;
      body['port'] = null;
    } else if (_tipo == TipoImpresora.tcp) {
      body['device'] = null;
      body['host'] = _hostController.text.trim().isEmpty ? null : _hostController.text.trim();
      body['port'] = _portController.text.trim().isEmpty ? null : (int.tryParse(_portController.text) ?? 9100);
    } else {
      body['device'] = _deviceController.text.trim().isEmpty ? null : _deviceController.text.trim();
      body['host'] = null;
      body['port'] = null;
    }
    if (widget.impresora != null) body['activo'] = _activo;
    return body;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.impresora == null ? 'Agregar impresora' : 'Editar impresora'),
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
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TipoImpresora>(
                value: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo de conexión'),
                items: TipoImpresora.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) => setState(() => _tipo = v ?? TipoImpresora.usb),
              ),
              const SizedBox(height: 12),
              if (_tipo == TipoImpresora.usb || _tipo == TipoImpresora.bluetooth)
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Nombre de impresora (Windows)',
                    hintText: 'Como aparece en Dispositivos e impresoras',
                  ),
                  controller: _deviceController,
                ),
              if (_tipo == TipoImpresora.tcp) ...[
                TextField(
                  decoration: const InputDecoration(labelText: 'IP', hintText: '192.168.1.50'),
                  controller: _hostController,
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(labelText: 'Puerto', hintText: '9100'),
                  controller: _portController,
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
              ),
              const SizedBox(height: 16),
              Theme(
                data: Theme.of(context).copyWith(
                  checkboxTheme: CheckboxThemeData(
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) return AppColors.primary;
                      return null;
                    }),
                    checkColor: WidgetStateProperty.all(Colors.white),
                  ),
                  switchTheme: SwitchThemeData(
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) return AppColors.primary;
                      return null;
                    }),
                    trackColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) return AppColors.primary.withValues(alpha: 0.5);
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
                      onChanged: (v) => setState(() => _imprimeTicket = v ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Imprime comandas (cocina)'),
                      value: _imprimeComanda,
                      onChanged: (v) => setState(() => _imprimeComanda = v ?? false),
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
