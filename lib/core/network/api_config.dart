class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.1.104.82:81/Online-application/public/api',
  );

  static String get baseImageUrl => baseUrl.replaceFirst('/api', '');

  static Uri uri(String path, [Map<String, dynamic>? query]) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final filteredQuery = <String, String>{};
    query?.forEach((key, value) {
      final text = value?.toString() ?? '';
      if (text.isNotEmpty) filteredQuery[key] = text;
    });

    return Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters: filteredQuery.isEmpty ? null : filteredQuery,
    );
  }
}

class ApiEndpoints {
  const ApiEndpoints._();

  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String categories = '/getCategories';
  static const String sections = '/getSections';
  static const String productsByCategory = '/getProducts';
  static const String productDetails = '/getProductDetails';
  static const String addToCart = '/addToCart';
  static const String getCart = '/getCart';
  static const String removeFromCart = '/removeFromCart';
  static const String placeOrder = '/placeOrder';
  static const String getOrders = '/getOrders';
  static const String getOrderDetails = '/getOrderDetails';
  static const String getUserOrdersHistory = '/getUserOrdersHistory';
  static const String cancelOrder = '/cancelOrder';
  static const String getTarget = '/getTarget';
  static const String addToFavourites = '/addToFavourites';
  static const String removeFromFavourites = '/removeFromFavourites';
  static const String getFavourites = '/getFavourites';
  static const String changePassword = '/changePassword';
  static const String getLatestOffers = '/getLatestOffers';
}
