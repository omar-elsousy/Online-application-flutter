import '../core/network/api_config.dart';

class ApiItem {
  const ApiItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    this.price,
    this.raw = const {},
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final double? price;
  final Map<String, dynamic> raw;

  bool get hasValidPrice => (price ?? 0) > 0;

  factory ApiItem.fromJson(Map<String, dynamic> json) {
    final id =
        _first(json, [
          'action_id',
          'company_id',
          'product_id',
          'id',
          'order_id',
          'family_id',
          'code',
          'item_id',
        ]) ??
        '';
    final titleValue =
        _first(json, [
          'name',
          'title',
          'product_name',
          'item_name',
          'category_name',
          'description_ar',
        ]) ??
        'Details'; // تغيير القيمة الافتراضية لتكون عامة واحترافية

    // تصحيح أسماء الشركات والكاتيجوريز التقنية
    String title = titleValue.toString();
    if (title == 'ITG_loose_tobacco' || title == 'Loose Tobacco') {
      title = 'Tobacco';
    } else if (title == 'Davidoff Evolve') {
      title = 'Evolve';
    } else {
      title = title.replaceAll('_', ' '); // استبدال أي _ بمسافة عامةً
    }
    final subtitle = _first(json, [
      'status',
      'category',
      'brand',
      'short_description',
      'created_at',
    ]);
    final description = _first(json, ['description', 'details', 'notes']);
    var imageUrl = _first(json, [
      'image',
      'image_url',
      'photo',
      'thumbnail',
    ])?.toString();
    final priceValue = _first(json, [
      'price',
      'sell_price',
      'unit_price',
      'pricelist_carton',
      'carton_price',
      'amount',
      'final_price',
      'total_price',
    ]);

    if (imageUrl != null && (imageUrl.isEmpty || imageUrl == 'null')) {
      imageUrl = null;
    }

    if (imageUrl != null) {
      if (imageUrl.startsWith('//')) {
        imageUrl = 'http:$imageUrl';
      }
      if (imageUrl.contains('localhost') || imageUrl.contains('127.0.0.1')) {
        imageUrl = imageUrl.replaceFirst(
          RegExp(r'https?://(localhost|127\.0\.0\.1)(:\d+)?'),
          ApiConfig.baseImageUrl,
        );
      } else if (!imageUrl.startsWith('http')) {
        final base = ApiConfig.baseImageUrl;
        final separator = imageUrl.startsWith('/') ? '' : '/';
        imageUrl = '$base$separator$imageUrl';
      }
    }

    return ApiItem(
      id: id.toString(),
      title: title.toString(),
      subtitle: subtitle?.toString(),
      description: description?.toString(),
      imageUrl: imageUrl,
      price: double.tryParse(priceValue?.toString() ?? ''),
      raw: json,
    );
  }

  static dynamic _first(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) return value;
    }
    return null;
  }
}

List<ApiItem> parseItems(dynamic payload) {
  final list = _extractList(payload);
  return list
      .whereType<Map>()
      .map((item) => ApiItem.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

List<dynamic> _extractList(dynamic payload) {
  if (payload is List) return payload;
  if (payload is Map<String, dynamic>) {
    final queue = [payload];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final key in ['data', 'items', 'products', 'categories', 'orders']) {
        final value = current[key];
        if (value is List) return value;
        if (value is Map<String, dynamic>) {
          queue.add(value);
        }
      }
      // إذا لم نجد الكلمات المفتاحية، نبحث في أي List موجودة
      for (final value in current.values) {
        if (value is List) return value;
      }
    }
  }
  return const [];
}
