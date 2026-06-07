/// Formats creator-facing labels and strips bad legacy placeholder handles.
abstract final class CreatorDisplay {
  static final _placeholderPattern = RegExp(
    r'user\.id|substring|\$\{|@\{',
    caseSensitive: false,
  );

  static bool isPlaceholderHandle(String? value) {
    if (value == null || value.trim().isEmpty) return true;
    return _placeholderPattern.hasMatch(value);
  }

  /// Primary label for cards and lists (display name preferred).
  static String label({
    String? displayName,
    String? handle,
    String? userId,
  }) {
    final name = displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;

    final h = handle?.trim() ?? '';
    if (h.isNotEmpty && !isPlaceholderHandle(h)) return h;

    if (userId != null && userId.length >= 6) {
      return 'Creator ${userId.substring(0, 6)}';
    }
    return 'Creator';
  }

  /// Secondary @handle line (optional).
  static String? subtitleHandle({
    String? displayName,
    String? handle,
  }) {
    final h = handle?.trim() ?? '';
    if (h.isEmpty || isPlaceholderHandle(h)) return null;
    final name = displayName?.trim() ?? '';
    if (name.isNotEmpty && h.toLowerCase() == name.toLowerCase()) return null;
    return h.startsWith('@') ? h : '@$h';
  }
}
