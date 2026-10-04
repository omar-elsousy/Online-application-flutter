import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/api_item.dart';
import '../models/cart_line.dart';
import '../models/point_models.dart';
import '../models/app_notification.dart';
import '../core/services/notification_service.dart';

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
  final List<PointsGift> pointsGifts = [];
  final List<PointsHistoryItem> pointsHistory = [];
  final List<AppNotification> notifications = [];

  int userPoints = 0;
  int unreadNotificationsCount = 0;
  PointsSummary? pointsSummary;

  bool isLoading = false;
  bool isBootstrapped = false;
  bool isHomeLoading = false;
  bool hasLoadedHome = false;
  bool _isFetching = false;
  int _cartStateRevision = 0;
  int _cartPricingOperationCount = 0;
  bool isCartPricingLoading = false;
  bool isCartDataRefreshing = false;
  bool isCartPreviewReady = false;
  bool isWalletCreditsReady = false;
  String? cartPricingError;
  String? _updatingWalletCreditKey;
  String? error;
  String? userMobile;

  double serverCartTotal = 0;
  Map<String, dynamic> cartTotals = const {};
  List<Map<String, dynamic>> cartGiftItems = const [];
  final Set<int> removedGiftIncentiveIds = {};
  final Map<String, String> cartIncentiveBanners = {};
  List<Map<String, dynamic>> walletCredits = const [];
  int serverCartCount = 0;
  final List<Map<String, dynamic>> selectedWalletCredits = [];

  double targetAchieved = 0;
  double targetSales = 0;

  bool get isAuthenticated => apiClient.isAuthenticated;
  int get cartCount => serverCartCount;
  double get cartTotal => serverCartTotal;

  bool isWalletCreditUpdating(Map<String, dynamic> credit) =>
      _updatingWalletCreditKey == _walletCreditKey(credit);

  String _walletCreditKey(Map<String, dynamic> credit) =>
      '${credit['incentive_type_id']}|${credit['from_date']}|${credit['to_date']}';

  void _beginCartPricing({bool refreshWalletCredits = false}) {
    if (_cartPricingOperationCount++ == 0) {
      isCartPricingLoading = true;
      isCartPreviewReady = false;
      cartPricingError = null;
      cartTotals = const {};
      serverCartTotal = 0;
      cartGiftItems = const [];
      cartIncentiveBanners.clear();
      if (refreshWalletCredits) {
        isWalletCreditsReady = false;
        isCartDataRefreshing = true;
      }
    }
    notifyListeners();
  }

  void _endCartPricing() {
    if (_cartPricingOperationCount > 0) _cartPricingOperationCount--;
    if (_cartPricingOperationCount == 0) {
      isCartPricingLoading = false;
      isCartDataRefreshing = false;
    }
    notifyListeners();
  }

  bool isFavourite(String productId) {
    return favourites.any((p) => p.id == productId);
  }

  bool isInCart(String productId) {
    return cart.any((line) => line.product.id == productId);
  }

  double getProductQuantity(String productId) {
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
      hasLoadedHome = false;
    });

    if (isAuthenticated) {
      NotificationService.instance.syncDeviceToken(apiClient);
      await loadHome();
    }
  }

  Future<List<Map<String, dynamic>>> loadRegistrationCustomers(
    String mobile,
  ) async {
    final payload = await apiClient.post(
      ApiEndpoints.registrationCustomers,
      body: {'mobile': mobile},
    );
    final rawCustomers = payload is Map ? payload['data'] : null;
    if (rawCustomers is! List) return const [];
    return rawCustomers
        .whereType<Map>()
        .map((customer) => Map<String, dynamic>.from(customer))
        .toList();
  }

  Future<bool> register({
    required String mobile,
    required String password,
    required String passwordConfirmation,
    required String posCode,
  }) async {
    var registered = false;
    await _guard(() async {
      await apiClient.post(
        ApiEndpoints.register,
        body: {
          'mobile': mobile,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'pos_code': posCode,
        },
      );
      registered = true;
    });
    return registered;
  }

  Future<void> loadHome() async {
    if (_isFetching) return;
    _beginCartPricing(refreshWalletCredits: true);
    _isFetching = true;
    isHomeLoading = true;
    notifyListeners();

    try {
      await _guard(() async {
        final results = await Future.wait([
          apiClient.get(ApiEndpoints.sections).catchError((_) => []),
          apiClient.get(ApiEndpoints.categories).catchError((_) => []),
          apiClient.get(ApiEndpoints.getCart).catchError((_) => {'data': {}}),
          apiClient.get(ApiEndpoints.getOrders).catchError((_) => []),
          apiClient
              .get(ApiEndpoints.getUserOrdersHistory)
              .catchError((_) => []),
          apiClient.get(ApiEndpoints.getTarget).catchError((_) => {'data': {}}),
          apiClient.get(ApiEndpoints.getFavourites).catchError((_) => []),
          apiClient.get(ApiEndpoints.getLatestOffers).catchError((_) => []),
          apiClient.get(ApiEndpoints.companies).catchError((_) => []),
          apiClient
              .get(ApiEndpoints.pointsSummary)
              .catchError((_) => {'data': {}}),
        ]);

        sections
          ..clear()
          ..addAll(parseItems(results[0]));
        categories
          ..clear()
          ..addAll(parseItems(results[1]));

        final cartData = results[2]['data'];
        if (cartData != null) {
          serverCartCount =
              int.tryParse(cartData['number_of_products']?.toString() ?? '0') ??
              0;
          final List<dynamic> items = cartData['items'] ?? [];
          cart.clear();
          for (var item in items) {
            final product = ApiItem.fromJson(item);
            if (!product.hasValidPrice) continue;
            cart.add(
              CartLine(
                product: product,
                quantity:
                    double.tryParse(item['quantity']?.toString() ?? '1') ?? 1,
              ),
            );
          }
          serverCartCount = cart.length;
        }

        orders
          ..clear()
          ..addAll(parseItems(results[3]));
        ordersHistory
          ..clear()
          ..addAll(parseItems(results[4]));

        final targetData = results[5]['data'];
        if (targetData != null) {
          targetAchieved =
              double.tryParse(targetData['achieved']?.toString() ?? '0') ?? 0;
          targetSales =
              double.tryParse(targetData['target_sales']?.toString() ?? '0') ??
              0;
        }

        favourites
          ..clear()
          ..addAll(
            parseItems(results[6]).where((product) => product.hasValidPrice),
          );
        latestOffers
          ..clear()
          ..addAll(
            parseItems(results[7]).where((product) => product.hasValidPrice),
          );
        companies
          ..clear()
          ..addAll(parseItems(results[8]));

        final pointsData = results[9] is Map ? results[9]['data'] : null;
        if (pointsData != null && pointsData is Map<String, dynamic>) {
          pointsSummary = PointsSummary.fromJson(pointsData);
          userPoints = pointsSummary!.points;
        }

        await Future.wait([loadCartPreview(), loadWalletCredits()]);

        // تحميل الهدايا بشكل مستقل بعد التحميل الأساسي
        loadPointsGifts();
      });
      hasLoadedHome = true;
    } finally {
      _isFetching = false;
      isHomeLoading = false;
      _endCartPricing();
      notifyListeners();
    }
  }

  Future<void> loadOrders() async {
    if (_isFetching) return;
    _isFetching = true;
    await _guard(() async {
      final results = await Future.wait([
        apiClient.get(ApiEndpoints.getOrders).catchError((_) => []),
        apiClient.get(ApiEndpoints.getUserOrdersHistory).catchError((_) => []),
      ]);
      orders
        ..clear()
        ..addAll(parseItems(results[0]));
      ordersHistory
        ..clear()
        ..addAll(parseItems(results[1]));
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
    final activePayload = await apiClient
        .get(ApiEndpoints.getOrders)
        .catchError((_) => []);
    final historyPayload = await apiClient
        .get(ApiEndpoints.getUserOrdersHistory)
        .catchError((_) => []);
    orders
      ..clear()
      ..addAll(parseItems(activePayload));
    ordersHistory
      ..clear()
      ..addAll(parseItems(historyPayload));
  }

  Future<void> loadTarget() async {
    await _guard(() async {
      final payload = await apiClient
          .get(ApiEndpoints.getTarget)
          .catchError((_) => {'data': {}});
      final data = payload['data'];
      if (data != null) {
        targetAchieved =
            double.tryParse(data['achieved']?.toString() ?? '0') ?? 0;
        targetSales =
            double.tryParse(data['target_sales']?.toString() ?? '0') ?? 0;
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
      await apiClient.delete(
        '${ApiEndpoints.removeFromFavourites}/${product.id}',
      );
      // إزالة محلية فورية لتحسين سرعة الاستجابة في الـ UI
      favourites.removeWhere((p) => p.id == product.id);
      notifyListeners();
      // تحديث نهائي من السيرفر للتأكد
      await loadFavourites();
    });
  }

  Future<void> loadFavourites() async {
    final payload = await apiClient
        .get(ApiEndpoints.getFavourites)
        .catchError((_) => []);
    favourites
      ..clear()
      ..addAll(parseItems(payload).where((product) => product.hasValidPrice));
    notifyListeners();
  }

  Future<void> loadCartPreview() async {
    _beginCartPricing();
    final revision = _cartStateRevision;
    try {
      final payload = await apiClient.post(
        ApiEndpoints.incentiveCartPreview,
        body: {
          'wallet_credits': selectedWalletCredits,
          'removed_gift_incentive_ids': removedGiftIncentiveIds.toList(),
        },
      );
      if (revision != _cartStateRevision) return;
      final data = Map<String, dynamic>.from(payload['data'] ?? const {});
      final totals = data['totals'];
      if (totals is! Map) {
        throw const FormatException('Cart totals were not returned.');
      }
      cartTotals = Map<String, dynamic>.from(totals);
      cartGiftItems = (data['gift_items'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      cartIncentiveBanners
        ..clear()
        ..addEntries(
          (data['items'] as List? ?? const [])
              .map((item) {
                final line = Map<String, dynamic>.from(item as Map);
                return MapEntry(
                  line['product_id'].toString(),
                  line['incentive_banner']?.toString() ?? '',
                );
              })
              .where((entry) => entry.value.isNotEmpty),
        );
      serverCartTotal =
          double.tryParse(cartTotals['grand_total']?.toString() ?? '') ?? 0;
      isCartPreviewReady = true;
      if (isWalletCreditsReady) cartPricingError = null;
      notifyListeners();
    } catch (e) {
      cartPricingError = 'Could not calculate the final cart total.';
      debugPrint('Incentive preview error: $e');
    } finally {
      _endCartPricing();
    }
  }

  Future<void> toggleWalletCredit(Map<String, dynamic> credit) async {
    if (isCartPricingLoading) return;
    _updatingWalletCreditKey = _walletCreditKey(credit);
    _beginCartPricing();
    _cartStateRevision++;
    final index = selectedWalletCredits.indexWhere(
      (item) =>
          item['incentive_type_id'].toString() ==
              credit['incentive_type_id'].toString() &&
          item['from_date'].toString() == credit['from_date'].toString() &&
          item['to_date'].toString() == credit['to_date'].toString(),
    );
    if (index == -1) {
      selectedWalletCredits.add(Map<String, dynamic>.from(credit));
    } else {
      selectedWalletCredits.removeAt(index);
    }
    notifyListeners();
    try {
      await loadCartPreview();
    } finally {
      _updatingWalletCreditKey = null;
      _endCartPricing();
    }
  }

  Future<void> removeGiftIncentive(int incentiveId) async {
    _beginCartPricing();
    _cartStateRevision++;
    removedGiftIncentiveIds.add(incentiveId);
    try {
      await loadCartPreview();
    } finally {
      _endCartPricing();
    }
  }

  String? incentiveBannerFor(String productId) {
    final banner = cartIncentiveBanners[productId];
    return banner == null || banner.isEmpty ? null : banner;
  }

  bool isWalletCreditSelected(Map<String, dynamic> credit) =>
      selectedWalletCredits.any(
        (item) =>
            item['incentive_type_id'].toString() ==
                credit['incentive_type_id'].toString() &&
            item['from_date'].toString() == credit['from_date'].toString() &&
            item['to_date'].toString() == credit['to_date'].toString(),
      );
  Future<void> loadWalletCredits() async {
    _beginCartPricing(refreshWalletCredits: true);
    final revision = _cartStateRevision;
    try {
      final payload = await apiClient.get(ApiEndpoints.walletAvailable);
      if (revision != _cartStateRevision) return;
      isWalletCreditsReady = true;
      walletCredits = (payload['data'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final selectedCount = selectedWalletCredits.length;
      selectedWalletCredits.removeWhere(
        (selected) => !walletCredits.any(
          (available) =>
              selected['incentive_type_id'].toString() ==
                  available['incentive_type_id'].toString() &&
              selected['from_date'].toString() ==
                  available['from_date'].toString() &&
              selected['to_date'].toString() == available['to_date'].toString(),
        ),
      );
      final selectionChanged = selectedWalletCredits.length != selectedCount;
      if (selectionChanged) _cartStateRevision++;
      if (isCartPreviewReady) cartPricingError = null;
      notifyListeners();
      if (selectionChanged) await loadCartPreview();
    } catch (e) {
      cartPricingError = 'Could not load cart incentives.';
      debugPrint('Wallet loading error: $e');
    } finally {
      _endCartPricing();
    }
  }

  Future<void> syncCart() async {
    if (_isFetching) return;
    _beginCartPricing(refreshWalletCredits: true);
    final revision = ++_cartStateRevision;
    try {
      final payload = await apiClient.get(ApiEndpoints.getCart);
      if (revision != _cartStateRevision) return;
      final data = payload['data'];
      if (data != null) {
        serverCartCount =
            int.tryParse(data['number_of_products']?.toString() ?? '0') ?? 0;
        final List<dynamic> items = data['items'] ?? [];
        cart.clear();
        for (var item in items) {
          final product = ApiItem.fromJson(item);
          if (!product.hasValidPrice) continue;
          cart.add(
            CartLine(
              product: product,
              quantity:
                  double.tryParse(item['quantity']?.toString() ?? '1') ?? 1,
            ),
          );
        }
        serverCartCount = cart.length;
        await Future.wait([loadCartPreview(), loadWalletCredits()]);
        notifyListeners();
      }
    } catch (e) {
      cartPricingError = 'Could not refresh the cart.';
      debugPrint('Cart sync error: $e');
    } finally {
      _endCartPricing();
    }
  }

  Future<List<ApiItem>> loadProductsByCategory(ApiItem category) async {
    final payload = await apiClient.get(
      '${ApiEndpoints.productsByCategory}/${category.id}',
    );
    return parseItems(
      payload,
    ).where((product) => product.hasValidPrice).toList();
  }

  Future<List<ApiItem>> loadCategoriesByCompany(String companyId) async {
    final payload = await apiClient.get(
      '${ApiEndpoints.companyCategories}/$companyId/categories',
    );
    return parseItems(payload);
  }

  Future<ApiItem> loadProductDetails(String productId) async {
    final payload = await apiClient.get(
      '${ApiEndpoints.productDetails}/$productId',
    );
    final data = payload['data'] as Map<String, dynamic>;
    return ApiItem.fromJson(data);
  }

  Future<void> addToCart(ApiItem product, {double quantity = 1}) async {
    final previousCart = List<CartLine>.from(cart);
    final previousCount = serverCartCount;
    final previousTotal = serverCartTotal;

    _beginCartPricing(refreshWalletCredits: true);
    error = null;
    _optimisticUpdate(product, quantity);
    try {
      await apiClient.post(
        '${ApiEndpoints.addToCart}/${product.id}',
        body: {'quantity': quantity},
      );
      await syncCart();
    } catch (e) {
      cart
        ..clear()
        ..addAll(previousCart);
      serverCartCount = previousCount;
      serverCartTotal = previousTotal;
      error = e.toString();
      cartPricingError = 'Could not update the cart total.';
      notifyListeners();
    } finally {
      _endCartPricing();
    }
  }

  Future<void> updateCartQuantity(ApiItem product, double delta) async {
    _beginCartPricing(refreshWalletCredits: true);
    double currentQty = 0;
    int index = cart.indexWhere((l) => l.product.id == product.id);
    if (index != -1) currentQty = cart[index].quantity;

    _optimisticUpdate(product, delta);

    try {
      if (delta == 1) {
        await apiClient.post(
          '${ApiEndpoints.addToCart}/${product.id}',
          body: {'quantity': 1},
        );
      } else if (delta == -1) {
        await apiClient.delete('${ApiEndpoints.removeFromCart}/${product.id}');
        if (currentQty > 1) {
          await apiClient.post(
            '${ApiEndpoints.addToCart}/${product.id}',
            body: {'quantity': currentQty - 1},
          );
        }
      }
      await syncCart();
    } catch (e) {
      error = e.toString();
      await syncCart();
    } finally {
      _endCartPricing();
    }
  }

  Future<void> setCartQuantity(ApiItem product, double newQty) async {
    _beginCartPricing(refreshWalletCredits: true);
    _optimisticSet(product, newQty);
    try {
      await apiClient.delete('${ApiEndpoints.removeFromCart}/${product.id}');
      if (newQty > 0) {
        await apiClient.post(
          '${ApiEndpoints.addToCart}/${product.id}',
          body: {'quantity': newQty},
        );
      }
      await syncCart();
    } catch (e) {
      error = e.toString();
      await syncCart();
    } finally {
      _endCartPricing();
    }
  }

  void _optimisticUpdate(ApiItem product, double delta) {
    _cartStateRevision++;
    final index = cart.indexWhere((line) => line.product.id == product.id);
    if (index == -1) {
      if (delta > 0) {
        cart.add(CartLine(product: product, quantity: delta));
        serverCartCount++;
      }
    } else {
      final newQty = cart[index].quantity + delta;
      if (newQty <= 0) {
        cart.removeAt(index);
        serverCartCount = (serverCartCount - 1).clamp(0, serverCartCount);
      } else {
        cart[index] = cart[index].copyWith(quantity: newQty);
      }
    }
    notifyListeners();
  }

  void _optimisticSet(ApiItem product, double newQty) {
    _cartStateRevision++;
    final index = cart.indexWhere((l) => l.product.id == product.id);
    if (newQty <= 0) {
      if (index != -1) cart.removeAt(index);
    } else {
      if (index != -1) cart[index] = cart[index].copyWith(quantity: newQty);
    }
    notifyListeners();
  }

  Future<void> removeFromCart(ApiItem product) async {
    _beginCartPricing(refreshWalletCredits: true);
    _cartStateRevision++;
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
    } finally {
      _endCartPricing();
    }
  }

  // الآن ترجع رقم الطلب عند النجاح
  Future<String?> checkout() async {
    if (cart.isEmpty || isLoading) return null;
    String? orderId;
    await _guard(() async {
      final payload = await apiClient.post(
        ApiEndpoints.placeOrder,
        body: {
          'wallet_credits': selectedWalletCredits,
          'removed_gift_incentive_ids': removedGiftIncentiveIds.toList(),
        },
      );
      if (payload['order_id'] != null) {
        orderId = payload['order_id'].toString();
        // Prevent older cart/preview responses from restoring pre-checkout data.
        _cartStateRevision++;
        cart.clear();
        serverCartTotal = 0;
        serverCartCount = 0;
        selectedWalletCredits.clear();
        removedGiftIncentiveIds.clear();
        cartTotals = const {};
        cartGiftItems = const [];
        cartIncentiveBanners.clear();
        notifyListeners();
      }
    });
    return orderId;
  }

  Future<Map<String, dynamic>> loadOrderDetails(String orderId) async {
    final payload = await apiClient.get(
      '${ApiEndpoints.getOrderDetails}/$orderId',
    );
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
      userPoints = 0;
      pointsSummary = null;
      pointsGifts.clear();
      pointsHistory.clear();
      isBootstrapped = false;
      hasLoadedHome = false;
    });
  }

  Future<void> loadPointsSummary() async {
    try {
      final payload = await apiClient.get(ApiEndpoints.pointsSummary);
      final data = payload['data'];
      if (data != null && data is Map<String, dynamic>) {
        pointsSummary = PointsSummary.fromJson(data);
        userPoints = pointsSummary!.points;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading points summary: $e');
    }
  }

  Future<void> loadPointsGifts() async {
    try {
      final payload = await apiClient.get(ApiEndpoints.pointsGifts);
      if (payload is Map) {
        final rawList = payload['data'];
        final List<dynamic> list = rawList is List ? rawList : [];
        pointsGifts.clear();
        for (var item in list) {
          if (item is Map) {
            final gift = PointsGift.fromJson(Map<String, dynamic>.from(item));
            pointsGifts.add(gift);
          }
        }
        if (payload['user_points'] != null) {
          userPoints =
              int.tryParse(payload['user_points'].toString()) ?? userPoints;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading points gifts: $e');
    }
  }

  Future<void> loadPointsHistory() async {
    try {
      final payload = await apiClient.get(ApiEndpoints.pointsHistory);
      if (payload is Map) {
        final rawList = payload['data'];
        final List<dynamic> list = rawList is List ? rawList : [];
        pointsHistory.clear();
        for (var item in list) {
          if (item is Map) {
            pointsHistory.add(
              PointsHistoryItem.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading points history: $e');
    }
  }

  Future<String?> redeemGift(int giftId) async {
    String? message;
    await _guard(() async {
      final payload = await apiClient.post(
        '${ApiEndpoints.pointsRedeem}/$giftId',
      );
      message = payload['message']?.toString();
      if (payload['remaining_points'] != null) {
        userPoints =
            int.tryParse(payload['remaining_points'].toString()) ?? userPoints;
      }
      await loadPointsSummary();
      await loadPointsGifts();
    });
    return message;
  }

  Future<void> loadNotificationCount() async {
    try {
      final payload = await apiClient.get(
        ApiEndpoints.notificationsUnreadCount,
      );
      unreadNotificationsCount =
          int.tryParse(payload['count']?.toString() ?? '0') ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notification count: $e');
    }
  }

  Future<void> loadNotifications() async {
    try {
      final payload = await apiClient.get(ApiEndpoints.notifications);
      final rawItems = payload is Map ? payload['data'] : payload;
      final items = rawItems is List ? rawItems : const [];
      notifications
        ..clear()
        ..addAll(
          items.whereType<Map>().map(
            (item) => AppNotification.fromJson(Map<String, dynamic>.from(item)),
          ),
        );
      unreadNotificationsCount = notifications
          .where((item) => !item.isRead)
          .length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> markNotificationAsRead(AppNotification notification) async {
    if (notification.isRead) return;
    try {
      await apiClient.post(
        '${ApiEndpoints.notifications}/${notification.id}/read',
      );
      await loadNotifications();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    if (unreadNotificationsCount == 0) return;
    try {
      await apiClient.post(ApiEndpoints.notificationsReadAll);
      await loadNotifications();
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
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
