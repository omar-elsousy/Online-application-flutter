import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/api_item.dart';
import '../models/cart_line.dart';

class AppState extends ChangeNotifier {
  AppState({ApiClient? apiClient}) : apiClient = apiClient ?? ApiClient();

  final ApiClient apiClient;
  final List<ApiItem> companies = [];
  final List<ApiItem> categories = [];
  final List<ApiItem> sections = [];
  final List<ApiItem> latestOffers = [];
  final List<ApiItem> orders = [];
  final List<ApiItem> ordersHistory = [];
  final List<ApiItem> favourites = [];
  final List<CartLine> cart = [];

  bool isLoading = false;
  bool isBootstrapped = false;
  bool _isFetching = false;
  String? error;
  String? userMobile;
  
  double serverCartTotal = 0;
  int serverCartCount = 0;

  double targetAchieved = 0;
  double targetSales = 0;

  bool get isAuthenticated => apiClient.isAuthenticated;
  int get cartCount => serverCartCount;
  double get cartTotal => serverCartTotal;

  bool isFavourite(String productId) {
    return favourites.any((p) => p.id == productId);
  }

  bool isInCart(String productId) {
    return cart.any((line) => line.product.id == productId);
  }

  int getProductQuantity(String productId) {
    final index = cart.indexWhere((l) => l.product.id == productId);
    return index != -1 ? cart[index].quantity : 0;
  }

  void clearError() {
    if (error != null) {
      error = null;
      notifyListeners();
    }
  }

  Future<void> login({required String mobile, required String password}) async {
    await _guard(() async {
      final payload = await apiClient.post(
        ApiEndpoints.login,
        body: {'mobile': mobile, 'password': password},
      );
      final token = _extractToken(payload);
      apiClient.setToken(token);
      userMobile = mobile;
      isBootstrapped = false;
      await loadHome();
    });
  }

  Future<void> register({
    required String mobile,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _guard(() async {
      await apiClient.post(
        ApiEndpoints.register,
        body: {
          'mobile': mobile,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
    });
  }

  Future<void> loadHome() async {
    if (_isFetching) return;
    _isFetching = true;
    
    await _guard(() async {
      final results = await Future.wait([
        apiClient.get(ApiEndpoints.sections).catchError((_) => []),
        apiClient.get(ApiEndpoints.categories).catchError((_) => []),
        apiClient.get(ApiEndpoints.getCart).catchError((_) => {'data': {}}),
        apiClient.get(ApiEndpoints.getOrders).catchError((_) => []),
        apiClient.get(ApiEndpoints.getUserOrdersHistory).catchError((_) => []),
        apiClient.get(ApiEndpoints.getTarget).catchError((_) => {'data': {}}),
        apiClient.get(ApiEndpoints.getFavourites).catchError((_) => []),
        apiClient.get(ApiEndpoints.getLatestOffers).catchError((_) => []),
        apiClient.get(ApiEndpoints.companies).catchError((_) => []),
      ]);

      sections..clear()..addAll(parseItems(results[0]));
      categories..clear()..addAll(parseItems(results[1]));

      final cartData = results[2]['data'];
      if (cartData != null) {
        serverCartTotal = double.tryParse(cartData['final_price']?.toString() ?? '0') ?? 0;
        serverCartCount = int.tryParse(cartData['number_of_products']?.toString() ?? '0') ?? 0;
        final List<dynamic> items = cartData['items'] ?? [];
        cart.clear();
        for (var item in items) {
          cart.add(CartLine(product: ApiItem.fromJson(item), quantity: int.tryParse(item['quantity']?.toString() ?? '1') ?? 1));
        }
      }

      orders..clear()..addAll(parseItems(results[3]));
      ordersHistory..clear()..addAll(parseItems(results[4]));

      final targetData = results[5]['data'];
      if (targetData != null) {
        targetAchieved = double.tryParse(targetData['achieved']?.toString() ?? '0') ?? 0;
        targetSales = double.tryParse(targetData['target_sales']?.toString() ?? '0') ?? 0;
      }

      favourites..clear()..addAll(parseItems(results[6]));
      latestOffers..clear()..addAll(parseItems(results[7]));
      companies..clear()..addAll(parseItems(results[8]));
    });
    
    _isFetching = false;
  }

  Future<void> loadOrders() async {
    if (_isFetching) return;
    _isFetching = true;
    await _guard(() async {
      final results = await Future.wait([
        apiClient.get(ApiEndpoints.getOrders).catchError((_) => []),
        apiClient.get(ApiEndpoints.getUserOrdersHistory).catchError((_) => []),
      ]);
      orders..clear()..addAll(parseItems(results[0]));
      ordersHistory..clear()..addAll(parseItems(results[1]));
    });
    _isFetching = false;
  }

  Future<void> cancelOrder(String orderId) async {
    await _guard(() async {
      await apiClient.post('${ApiEndpoints.cancelOrder}/$orderId');
      
      // 1. إزالته من القائمة النشطة (Active)
      orders.removeWhere((o) => o.id == orderId);
      
      // 2. تحديث حالته في قائمة السجل (History) محلياً قبل التحديث من السيرفر
      final index = ordersHistory.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final oldOrder = ordersHistory[index];
        final Map<String, dynamic> newRaw = Map.from(oldOrder.raw);
        newRaw['status'] = 'cancelled';
        ordersHistory[index] = ApiItem.fromJson(newRaw);
      }
      
      notifyListeners();
      
      // 3. مزامنة البيانات النهائية من السيرفر
      await _loadOrdersInternal();
    });
  }

  Future<void> _loadOrdersInternal() async {
    final activePayload = await apiClient.get(ApiEndpoints.getOrders).catchError((_) => []);
    final historyPayload = await apiClient.get(ApiEndpoints.getUserOrdersHistory).catchError((_) => []);
    orders..clear()..addAll(parseItems(activePayload));
    ordersHistory..clear()..addAll(parseItems(historyPayload));
  }

  Future<void> loadTarget() async {
    await _guard(() async {
      final payload = await apiClient.get(ApiEndpoints.getTarget).catchError((_) => {'data': {}});
      final data = payload['data'];
      if (data != null) {
        targetAchieved = double.tryParse(data['achieved']?.toString() ?? '0') ?? 0;
        targetSales = double.tryParse(data['target_sales']?.toString() ?? '0') ?? 0;
      }
    });
  }

  Future<void> addToFavourites(ApiItem product) async {
    await _guard(() async {
      await apiClient.post('${ApiEndpoints.addToFavourites}/${product.id}');
      await loadFavourites();
    });
  }

  Future<void> removeFromFavourites(ApiItem product) async {
    await _guard(() async {
      await apiClient.delete('${ApiEndpoints.removeFromFavourites}/${product.id}');
      // إزالة محلية فورية لتحسين سرعة الاستجابة في الـ UI
      favourites.removeWhere((p) => p.id == product.id);
      notifyListeners();
      // تحديث نهائي من السيرفر للتأكد
      await loadFavourites();
    });
  }

  Future<void> loadFavourites() async {
    final payload = await apiClient.get(ApiEndpoints.getFavourites).catchError((_) => []);
    favourites..clear()..addAll(parseItems(payload));
    notifyListeners();
  }

  Future<void> syncCart() async {
    if (_isFetching) return;
    try {
      final payload = await apiClient.get(ApiEndpoints.getCart);
      final data = payload['data'];
      if (data != null) {
        serverCartTotal = double.tryParse(data['final_price']?.toString() ?? '0') ?? 0;
        serverCartCount = int.tryParse(data['number_of_products']?.toString() ?? '0') ?? 0;
        final List<dynamic> items = data['items'] ?? [];
        cart.clear();
        for (var item in items) {
          cart.add(CartLine(product: ApiItem.fromJson(item), quantity: int.tryParse(item['quantity']?.toString() ?? '1') ?? 1));
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Cart sync error: $e');
    }
  }

  Future<List<ApiItem>> loadProductsByCategory(ApiItem category) async {
    final payload = await apiClient.get('${ApiEndpoints.productsByCategory}/${category.id}');
    return parseItems(payload);
  }

  Future<List<ApiItem>> loadCategoriesByCompany(String companyId) async {
    final payload = await apiClient.get('${ApiEndpoints.companyCategories}/$companyId/categories');
    return parseItems(payload);
  }

  Future<ApiItem> loadProductDetails(String productId) async {
    final payload = await apiClient.get('${ApiEndpoints.productDetails}/$productId');
    final data = payload['data'] as Map<String, dynamic>;
    return ApiItem.fromJson(data);
  }

  Future<void> addToCart(ApiItem product, {int quantity = 1}) async {
    _optimisticUpdate(product, quantity);
    try {
      await apiClient.post('${ApiEndpoints.addToCart}/${product.id}', body: {'quantity': quantity});
      await syncCart();
    } catch (e) {
      error = e.toString();
      await syncCart();
    }
  }

  Future<void> updateCartQuantity(ApiItem product, int delta) async {
    int currentQty = 0;
    int index = cart.indexWhere((l) => l.product.id == product.id);
    if (index != -1) currentQty = cart[index].quantity;

    _optimisticUpdate(product, delta);

    try {
      if (delta == 1) {
        await apiClient.post('${ApiEndpoints.addToCart}/${product.id}', body: {'quantity': 1});
      } else if (delta == -1) {
        await apiClient.delete('${ApiEndpoints.removeFromCart}/${product.id}');
        if (currentQty > 1) {
          await apiClient.post('${ApiEndpoints.addToCart}/${product.id}', body: {'quantity': currentQty - 1});
        }
      }
      await syncCart();
    } catch (e) {
      error = e.toString();
      await syncCart();
    }
  }

  Future<void> setCartQuantity(ApiItem product, int newQty) async {
    _optimisticSet(product, newQty);
    try {
      await apiClient.delete('${ApiEndpoints.removeFromCart}/${product.id}');
      if (newQty > 0) {
        await apiClient.post('${ApiEndpoints.addToCart}/${product.id}', body: {'quantity': newQty});
      }
      await syncCart();
    } catch (e) {
      error = e.toString();
      await syncCart();
    }
  }

  void _optimisticUpdate(ApiItem product, int delta) {
    final index = cart.indexWhere((l) => l.product.id == product.id);
    if (index != -1) {
      final newQty = cart[index].quantity + delta;
      if (newQty <= 0) {
        cart.removeAt(index);
      } else {
        cart[index] = cart[index].copyWith(quantity: newQty);
      }
      notifyListeners();
    }
  }

  void _optimisticSet(ApiItem product, int newQty) {
    final index = cart.indexWhere((l) => l.product.id == product.id);
    if (newQty <= 0) {
      if (index != -1) cart.removeAt(index);
    } else {
      if (index != -1) cart[index] = cart[index].copyWith(quantity: newQty);
    }
    notifyListeners();
  }

  Future<void> removeFromCart(ApiItem product) async {
    final index = cart.indexWhere((l) => l.product.id == product.id);
    if (index != -1) {
      cart.removeAt(index);
      notifyListeners();
    }
    try {
      await apiClient.delete('${ApiEndpoints.removeFromCart}/${product.id}');
      await syncCart();
    } catch (e) {
      error = e.toString();
      await syncCart();
    }
  }

  // الآن ترجع رقم الطلب عند النجاح
  Future<String?> checkout() async {
    if (cart.isEmpty || isLoading) return null;
    String? orderId;
    await _guard(() async {
      final payload = await apiClient.post(ApiEndpoints.placeOrder);
      if (payload['order_id'] != null) {
        orderId = payload['order_id'].toString();
        cart.clear();
        serverCartTotal = 0;
        serverCartCount = 0;
        notifyListeners();
      }
    });
    return orderId;
  }

  Future<Map<String, dynamic>> loadOrderDetails(String orderId) async {
    final payload = await apiClient.get('${ApiEndpoints.getOrderDetails}/$orderId');
    return payload['data'] ?? {};
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _guard(() async {
      final payload = await apiClient.post(
        ApiEndpoints.changePassword,
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        },
      );
      // إذا نجح الطلب، السيرفر يرجع البيانات الجديدة أو رسالة نجاح
      // نضع رسالة نجاح في الـ error (أو متغير مخصص) ليتمكن الـ UI من عرضها
      error = payload['message'] ?? 'Password changed successfully';
    });
  }

  Future<void> logout() async {
    await _guard(() async {
      await apiClient.post(ApiEndpoints.logout).catchError((_) => null);
      apiClient.setToken(null);
      userMobile = null;
      categories.clear();
      sections.clear();
      orders.clear();
      cart.clear();
      serverCartTotal = 0;
      serverCartCount = 0;
      isBootstrapped = false;
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (isLoading) return; 
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await action();
      // إذا اكتمل التحميل الأساسي بنجاح أو حتى جزئياً نعتبره bootstrapped
      // لمنع المحاولات اللانهائية فيdidChangeDependencies
      isBootstrapped = true;
    } catch (e) {
      error = e.toString();
      debugPrint('Error in AppState: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String? _extractToken(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      for (final key in ['token', 'access_token', 'api_token']) {
        final value = payload[key];
        if (value is String && value.isNotEmpty) return value;
      }
      final data = payload['data'];
      if (data is Map<String, dynamic>) return _extractToken(data);
      final user = payload['user'];
      if (user is Map<String, dynamic>) return _extractToken(user);
    }
    return null;
  }
}
