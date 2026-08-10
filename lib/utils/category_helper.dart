class CategoryReasonResult {
  final String? category;
  final String cleanReason;

  const CategoryReasonResult({
    this.category,
    required this.cleanReason,
  });
}

/// Parses a stored reason string which may contain a `"Category: <name>"` prefix.
CategoryReasonResult parseCategoryAndReason(String? rawReason) {
  if (rawReason == null || rawReason.trim().isEmpty) {
    return const CategoryReasonResult(category: null, cleanReason: '');
  }

  final trimmed = rawReason.trim();

  if (trimmed.startsWith('Category:')) {
    final withoutPrefix = trimmed.substring('Category:'.length).trim();
    final parts = withoutPrefix.split(' | ');

    final category = parts.first.trim();
    final cleanReason =
        parts.length > 1 ? parts.sublist(1).join(' | ').trim() : '';

    return CategoryReasonResult(
      category: category.isNotEmpty ? category : null,
      cleanReason: cleanReason,
    );
  }

  return CategoryReasonResult(
    category: null,
    cleanReason: trimmed,
  );
}

/// Formats category and user note into a stored reason string.
String? formatCategoryAndReason({String? category, String? reason}) {
  final trimmedCat = category?.trim();
  final trimmedReason = reason?.trim();

  final hasCat = trimmedCat != null && trimmedCat.isNotEmpty;
  final hasReason = trimmedReason != null && trimmedReason.isNotEmpty;

  if (hasCat && hasReason) {
    return 'Category: $trimmedCat | $trimmedReason';
  } else if (hasCat) {
    return 'Category: $trimmedCat';
  } else if (hasReason) {
    return trimmedReason;
  }
  return null;
}
