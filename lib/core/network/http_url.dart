/// Ensures [raw] is a valid absolute http(s) URL for [Uri.parse] / Dio.
String normalizeHttpUrl(String raw, {String fieldName = 'URL'}) {
  var value = raw.trim();
  if (value.isEmpty) {
    throw FormatException('$fieldName is empty');
  }
  if (!value.contains('://')) {
    value = 'https://$value';
  }
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw FormatException('Invalid $fieldName: $raw');
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw FormatException('$fieldName must use http or https: $raw');
  }
  return uri.toString();
}

Uri parseHttpUri(String raw, {String fieldName = 'URL'}) {
  return Uri.parse(normalizeHttpUrl(raw, fieldName: fieldName));
}
