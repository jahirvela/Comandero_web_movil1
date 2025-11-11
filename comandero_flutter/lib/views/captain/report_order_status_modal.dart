import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';

class ReportOrderStatusModal extends StatefulWidget {
  final String orderId;
  final int? tableNumber;
  final bool isTakeaway;
  final Function(String tipo, String motivo, String? detalles, bool notifyCook)
  onSend;

  const ReportOrderStatusModal({
    super.key,
    required this.orderId,
    this.tableNumber,
    this.isTakeaway = false,
    required this.onSend,
  });

  static Future<void> show(
    BuildContext context, {
    required String orderId,
    int? tableNumber,
    bool isTakeaway = false,
    required Function(
      String tipo,
      String motivo,
      String? detalles,
      bool notifyCook,
    )
    onSend,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ReportOrderStatusModal(
        orderId: orderId,
        tableNumber: tableNumber,
        isTakeaway: isTakeaway,
        onSend: onSend,
      ),
    );
  }

  @override
  State<ReportOrderStatusModal> createState() => _ReportOrderStatusModalState();
}

class _ReportOrderStatusModalState extends State<ReportOrderStatusModal> {
  String? _selectedType;
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _notifyCook = true;

  // Opciones de Tipo
  final List<String> _typeOptions = ['Demora', 'Cancelación', 'Cambio'];

  // Opciones de Motivo según el Tipo
  List<String> get _reasonOptions {
    switch (_selectedType) {
      case 'Demora':
        return [
          'Tiempo de preparación excedido',
          'Falta de ingredientes',
          'Problema en cocina',
          'Pedido muy grande',
          'Otro',
        ];
      case 'Cancelación':
        return [
          'Cliente canceló pedido',
          'Producto agotado',
          'Error en pedido',
          'Problema con cliente',
          'Otro',
        ];
      case 'Cambio':
        return [
          'Cliente cambió productos',
          'Corrección de pedido',
          'Modificación de cantidades',
          'Otro',
        ];
      default:
        return [];
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_selectedType == null || _selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona Tipo y Motivo'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    widget.onSend(
      _selectedType!,
      _selectedReason!,
      _detailsController.text.trim().isEmpty
          ? null
          : _detailsController.text.trim(),
      _notifyCook,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final reasons = _reasonOptions;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 500 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(
                isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLG),
                  topRight: Radius.circular(AppTheme.radiusLG),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reportar estado de orden',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: isTablet
                                    ? AppTheme.fontSizeXL
                                    : AppTheme.fontSizeLG,
                                fontWeight: AppTheme.fontWeightBold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Orden ${widget.orderId}${widget.tableNumber != null
                              ? ' • Mesa ${widget.tableNumber}'
                              : widget.isTakeaway
                              ? ' • Para llevar'
                              : ''}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: isTablet
                                    ? AppTheme.fontSizeSM
                                    : AppTheme.fontSizeXS,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo Tipo
                    Text(
                      'Tipo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: isTablet
                            ? AppTheme.fontSizeBase
                            : AppTheme.fontSizeSM,
                        fontWeight: AppTheme.fontWeightSemibold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: InputDecoration(
                        hintText: 'Seleccionar tipo',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMD,
                          ),
                        ),
                      ),
                      items: [
                        for (final type in _typeOptions)
                          DropdownMenuItem(value: type, child: Text(type)),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                          _selectedReason =
                              null; // Reset motivo al cambiar tipo
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Campo Motivo (solo se muestra si hay un tipo seleccionado)
                    if (_selectedType != null) ...[
                      Text(
                        'Motivo',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: isTablet
                                  ? AppTheme.fontSizeBase
                                  : AppTheme.fontSizeSM,
                              fontWeight: AppTheme.fontWeightSemibold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedReason,
                        decoration: InputDecoration(
                          hintText: 'Seleccionar motivo',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMD,
                            ),
                          ),
                        ),
                        items: [
                          for (final reason in reasons)
                            DropdownMenuItem(
                              value: reason,
                              child: Text(reason),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedReason = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Campo Detalles (opcional)
                    Text(
                      'Detalles (opcional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: isTablet
                            ? AppTheme.fontSizeBase
                            : AppTheme.fontSizeSM,
                        fontWeight: AppTheme.fontWeightSemibold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _detailsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Agregar detalles adicionales...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMD,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Checkbox Notificar al cocinero
                    CheckboxListTile(
                      value: _notifyCook,
                      onChanged: (value) {
                        setState(() {
                          _notifyCook = value ?? true;
                        });
                      },
                      title: Text(
                        'Notificar al cocinero',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: isTablet
                              ? AppTheme.fontSizeBase
                              : AppTheme.fontSizeSM,
                          fontWeight: AppTheme.fontWeightMedium,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacingMD),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'La notificación llegará a Cocina y aparecerá en KDS con prioridad. Esta acción quedará registrada.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: isTablet
                              ? AppTheme.fontSizeXS
                              : AppTheme.fontSizeXS,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer con botones
            Container(
              padding: EdgeInsets.all(
                isTablet ? AppTheme.spacingXL : AppTheme.spacingLG,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.radiusLG),
                  bottomRight: Radius.circular(AppTheme.radiusLG),
                ),
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet
                              ? AppTheme.spacingMD
                              : AppTheme.spacingSM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMD,
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: isTablet
                              ? AppTheme.fontSizeBase
                              : AppTheme.fontSizeSM,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet
                              ? AppTheme.spacingMD
                              : AppTheme.spacingSM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMD,
                          ),
                        ),
                      ),
                      child: Text(
                        'Enviar notificación',
                        style: TextStyle(
                          fontSize: isTablet
                              ? AppTheme.fontSizeBase
                              : AppTheme.fontSizeSM,
                          fontWeight: AppTheme.fontWeightSemibold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
