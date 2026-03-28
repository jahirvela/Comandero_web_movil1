/// Normaliza texto para comparaciones de búsqueda (minúsculas y sin tildes).
/// Así "platano" coincide con "Plátano".
String normalizeForInsensitiveSearch(String input) {
  if (input.isEmpty) return '';
  const map = <String, String>{
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'å': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
    'ç': 'c',
  };
  final sb = StringBuffer();
  for (final r in input.toLowerCase().trim().runes) {
    final c = String.fromCharCode(r);
    sb.write(map[c] ?? c);
  }
  return sb.toString();
}
