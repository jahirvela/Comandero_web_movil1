// Utilidades RFC 4180 para CSV legible en Excel (comillas y escapes).

String csvEscapeCell(String raw) {
  final s = raw
      .replaceAll('\r\n', ' ')
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ');
  return '"${s.replaceAll('"', '""')}"';
}

String csvJoinRow(List<String> cells) => cells.map(csvEscapeCell).join(',');
