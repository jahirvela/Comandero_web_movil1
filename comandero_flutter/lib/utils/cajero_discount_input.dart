import 'package:flutter/material.dart';

/// Modo de descuento al cobrar (cajero / gerente-cajero).
enum CajeroDiscountInputMode {
  percent,
  fixed,
}

double cajeroParseDiscountInput(String text) {
  final t = text.trim().replaceAll(',', '');
  return double.tryParse(t) ?? 0.0;
}

/// [billTotalForDiscount] = total a cobrar antes de aplicar este descuento (p. ej. [BillModel.calculatedTotal]).
double cajeroDiscountAmount({
  required double billTotalForDiscount,
  required CajeroDiscountInputMode mode,
  required double rawInput,
}) {
  if (billTotalForDiscount <= 0) return 0;
  if (rawInput <= 0) return 0;
  switch (mode) {
    case CajeroDiscountInputMode.percent:
      return billTotalForDiscount * (rawInput.clamp(0, 100) / 100);
    case CajeroDiscountInputMode.fixed:
      return rawInput.clamp(0, billTotalForDiscount);
  }
}

/// Texto que va en [PaymentModel.reference] para que el backend persista [orden.descuento_total].
String? cajeroDiscountPaymentReference({
  required CajeroDiscountInputMode mode,
  required double rawInput,
  required double billTotalForDiscount,
}) {
  final amt = cajeroDiscountAmount(
    billTotalForDiscount: billTotalForDiscount,
    mode: mode,
    rawInput: rawInput,
  );
  if (amt <= 0) return null;
  switch (mode) {
    case CajeroDiscountInputMode.percent:
      return 'Descuento aplicado: ${rawInput.clamp(0, 100).toStringAsFixed(0)}%';
    case CajeroDiscountInputMode.fixed:
      return 'Descuento fijo: \$${amt.toStringAsFixed(2)}';
  }
}

/// Selector % / \$ compacto para modales de cobro.
Widget cajeroDiscountModeSelector({
  required CajeroDiscountInputMode mode,
  required ValueChanged<CajeroDiscountInputMode> onChanged,
}) {
  return SegmentedButton<CajeroDiscountInputMode>(
    segments: const [
      ButtonSegment<CajeroDiscountInputMode>(
        value: CajeroDiscountInputMode.percent,
        label: Text('%'),
        tooltip: 'Descuento por porcentaje sobre el total',
      ),
      ButtonSegment<CajeroDiscountInputMode>(
        value: CajeroDiscountInputMode.fixed,
        label: Text(r'$'),
        tooltip: 'Descuento por cantidad fija (MXN)',
      ),
    ],
    selected: {mode},
    onSelectionChanged: (Set<CajeroDiscountInputMode> next) {
      if (next.isNotEmpty) onChanged(next.first);
    },
  );
}
