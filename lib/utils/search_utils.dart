import '../models/api_item.dart';

bool matchesSearchQuery(String query, Iterable<Object?> values) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) return true;

  return values.any(
    (value) => value?.toString().toLowerCase().contains(keyword) ?? false,
  );
}

bool matchesApiItemSearch(ApiItem item, String query) {
  return matchesSearchQuery(query, [
    item.id,
    item.title,
    item.subtitle,
    item.description,
    item.price,
  ]);
}
