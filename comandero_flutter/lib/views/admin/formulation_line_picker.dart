import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../../controllers/admin_controller.dart';
import '../../models/admin_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../utils/string_search_utils.dart';

int _formulationPickerCategorySort(String a, String b) {
  bool isOtros(String s) =>
      normalizeForInsensitiveSearch(s) ==
      normalizeForInsensitiveSearch('Otros');
  final ao = isOtros(a);
  final bo = isOtros(b);
  if (ao && !bo) return 1;
  if (!ao && bo) return -1;
  return a.toLowerCase().compareTo(b.toLowerCase());
}

String _categoryLabelForItem(InventoryItem item) =>
    item.category.trim().isEmpty ? 'Otros' : item.category;

/// Selector compacto de un insumo base para la BOM de un producto formulado (solo cliente).
Future<InventoryFormulationLine?> showFormulationLinePicker({
  required BuildContext context,
  required AdminController controller,
  required bool isTablet,
  required Set<String> excludeComponentIds,
}) async {
  return showDialog<InventoryFormulationLine>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _FormulationLinePickerBody(
      controller: controller,
      isTablet: isTablet,
      excludeComponentIds: excludeComponentIds,
    ),
  );
}

class _FormulationLinePickerBody extends StatefulWidget {
  const _FormulationLinePickerBody({
    required this.controller,
    required this.isTablet,
    required this.excludeComponentIds,
  });

  final AdminController controller;
  final bool isTablet;
  final Set<String> excludeComponentIds;

  @override
  State<_FormulationLinePickerBody> createState() =>
      _FormulationLinePickerBodyState();
}

class _FormulationLinePickerBodyState
    extends State<_FormulationLinePickerBody> {
  final _search = TextEditingController();
  final _quantity = TextEditingController();
  final _unit = TextEditingController();
  InventoryItem? _selected;
  bool _refreshPending = false;
  /// `null` = todas las categorías entre insumos elegibles.
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshInventoryInBackground());
  }

  Future<void> _refreshInventoryInBackground() async {
    setState(() => _refreshPending = true);
    try {
      await widget.controller.loadInventory();
    } finally {
      if (mounted) {
        setState(() => _refreshPending = false);
      }
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _quantity.dispose();
    _unit.dispose();
    super.dispose();
  }

  static String _digitsOnly(String s) =>
      s.replaceAll(RegExp(r'\D'), '');

  bool _matchesSearch(InventoryItem item, String rawQuery) {
    final trimmed = rawQuery.trim();
    if (trimmed.isEmpty) return true;

    final qNorm = normalizeForInsensitiveSearch(trimmed);
    final nameNorm = normalizeForInsensitiveSearch(item.name);
    final catNorm = normalizeForInsensitiveSearch(item.category);

    if (nameNorm.contains(qNorm) || catNorm.contains(qNorm)) return true;

    final cb = item.codigoBarras?.trim();
    if (cb != null && cb.isNotEmpty) {
      final cbNorm = normalizeForInsensitiveSearch(cb);
      if (cbNorm.contains(qNorm)) return true;

      final qDigits = _digitsOnly(trimmed);
      final cbDigits = _digitsOnly(cb);
      if (qDigits.isNotEmpty &&
          cbDigits.startsWith(qDigits)) {
        return true;
      }
    }

    return false;
  }

  List<InventoryItem> _eligibleBaseItems() {
    return widget.controller.inventory.where((item) {
      if (item.status == InventoryStatus.expired) return false;
      if (item.isFormulated) return false;
      if (widget.excludeComponentIds.contains(item.id)) return false;
      return true;
    }).toList();
  }

  List<InventoryItem> _visible() {
    final raw = _search.text;
    final eligible = _eligibleBaseItems();

    final categoryNames = <String>{};
    for (final item in eligible) {
      categoryNames.add(_categoryLabelForItem(item));
    }
    final effectiveCategoryFilter =
        _categoryFilter != null && categoryNames.contains(_categoryFilter!)
            ? _categoryFilter
            : null;

    Iterable<InventoryItem> candidates = eligible;
    if (effectiveCategoryFilter != null) {
      candidates = eligible.where(
        (item) => _categoryLabelForItem(item) == effectiveCategoryFilter,
      );
    }

    final list = candidates
        .where((item) => _matchesSearch(item, raw))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final narrow = mq.size.width < 440;
    final shortestSide = mq.size.shortestSide;
    final tabletLike = widget.isTablet || shortestSide >= 600 || mq.size.width >= 600;
    final chipFontSize = narrow ? 13.0 : (tabletLike ? 14.5 : 13.5);
    final chipVerticalPad = narrow ? 10.0 : 8.0;
    final chipHorizontalPad = narrow ? 12.0 : 11.0;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final eligible = _eligibleBaseItems();
        final eligibleCount = eligible.length;
        final categoryNames = <String>{};
        for (final item in eligible) {
          categoryNames.add(_categoryLabelForItem(item));
        }
        final sortedCategoryChips = categoryNames.toList()
          ..sort(_formulationPickerCategorySort);
        final effectiveCategoryFilter =
            _categoryFilter != null && categoryNames.contains(_categoryFilter!)
                ? _categoryFilter
                : null;

        final list = _visible();
        final searching = _search.text.trim().isNotEmpty;

        return AlertDialog(
          title: Text(
            'Agregar componente',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: widget.isTablet ? 560 : mq.size.width * 0.92,
            height: mq.size.height * (narrow ? 0.74 : 0.68),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    hintText: 'Nombre, categoría o código…',
                    suffixIcon: _refreshPending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {
                    final t = _search.text;
                    final sel = _selected;
                    if (sel != null && !_matchesSearch(sel, t)) {
                      _selected = null;
                    }
                  }),
                ),
                SizedBox(height: AppTheme.spacingSM),
                Text(
                  'Categoría',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: AppTheme.fontWeightSemibold,
                        fontSize: narrow ? 15 : null,
                      ),
                ),
                SizedBox(height: AppTheme.spacingXS),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.only(bottom: narrow ? 6 : 2),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: AppTheme.spacingXS),
                        child: FilterChip(
                          label: Text(
                            'Todos',
                            style: TextStyle(
                              color: effectiveCategoryFilter == null
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: chipFontSize,
                            ),
                          ),
                          selected: effectiveCategoryFilter == null,
                          onSelected: (_) => setState(() {
                            _categoryFilter = null;
                          }),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color: AppColors.textSecondary.withValues(alpha: 0.35),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: chipHorizontalPad,
                            vertical: chipVerticalPad,
                          ),
                          materialTapTargetSize: narrow
                              ? MaterialTapTargetSize.padded
                              : MaterialTapTargetSize.shrinkWrap,
                          visualDensity: narrow
                              ? VisualDensity.standard
                              : VisualDensity.compact,
                        ),
                      ),
                      ...sortedCategoryChips.map(
                        (cat) => Padding(
                          padding:
                              const EdgeInsets.only(right: AppTheme.spacingXS),
                          child: FilterChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                color: effectiveCategoryFilter == cat
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: chipFontSize,
                              ),
                            ),
                            selected: effectiveCategoryFilter == cat,
                            onSelected: (_) => setState(() {
                              _categoryFilter = cat;
                              final sel = _selected;
                              if (sel != null &&
                                  _categoryLabelForItem(sel) != cat) {
                                _selected = null;
                              }
                            }),
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surface,
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: AppColors.textSecondary.withValues(alpha: 0.35),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: chipHorizontalPad,
                              vertical: chipVerticalPad,
                            ),
                            materialTapTargetSize: narrow
                                ? MaterialTapTargetSize.padded
                                : MaterialTapTargetSize.shrinkWrap,
                            visualDensity: narrow
                                ? VisualDensity.standard
                                : VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppTheme.spacingSM),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: list.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.spacingMD),
                              child: Text(
                                eligibleCount == 0
                                    ? 'No hay insumos base disponibles para agregar '
                                        '(solo se usan ítems que no son productos formulados).'
                                    : searching || effectiveCategoryFilter != null
                                        ? 'Ningún resultado (prueba otra categoría o búsqueda).'
                                        : 'No hay insumos disponibles (revisa filtros).',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        : Theme(
                            data: Theme.of(context).copyWith(
                              radioTheme: RadioThemeData(
                                fillColor:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return AppColors.primary;
                                  }
                                  return null;
                                }),
                              ),
                            ),
                            child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final item = list[index];
                              return RadioListTile<InventoryItem>(
                                value: item,
                                groupValue: _selected,
                                toggleable: true,
                                dense: !widget.isTablet,
                                selectedTileColor: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                onChanged: (v) => setState(() => _selected = v),
                                title: Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    item.category,
                                    item.unit,
                                    if (item.codigoBarras != null &&
                                        item.codigoBarras!.trim().isNotEmpty)
                                      'CB: ${item.codigoBarras}',
                                  ].join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                          ),
                  ),
                ),
                SizedBox(height: AppTheme.spacingSM),
                if (narrow)
                  Column(
                    children: [
                      TextField(
                        controller: _quantity,
                        decoration: const InputDecoration(
                          labelText:
                              'Cantidad por 1 unidad del producto formulado',
                          border: OutlineInputBorder(),
                          hintText: 'Ej: 200',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingSM),
                      TextField(
                        controller: _unit,
                        decoration: const InputDecoration(
                          labelText: 'Unidad',
                          border: OutlineInputBorder(),
                          hintText: 'g, ml, pza…',
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _quantity,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad por 1 unidad del formulado',
                            border: OutlineInputBorder(),
                            hintText: 'Ej: 200',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      SizedBox(width: AppTheme.spacingSM),
                      Expanded(
                        child: TextField(
                          controller: _unit,
                          decoration: const InputDecoration(
                            labelText: 'Unidad',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final sel = _selected;
                if (sel == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selecciona un insumo'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                final q = double.tryParse(_quantity.text.replaceAll(',', '.'));
                final u = _unit.text.trim();
                if (q == null || q <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Indica una cantidad mayor a 0'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                if (u.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Indica la unidad'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(
                  InventoryFormulationLine(
                    id: 'fc_${DateTime.now().microsecondsSinceEpoch}',
                    componentInventoryItemId: sel.id,
                    name: sel.name,
                    unit: u,
                    quantity: q,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }
}
