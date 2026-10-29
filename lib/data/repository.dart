import '../config.dart';
import 'api_client.dart';
import 'models.dart';
import 'mock_data.dart';

/// Single place the app talks to for data. When [AppConfig.useLiveData] is
/// false (no backend configured) every method returns the built-in demo data,
/// so the app is fully usable out of the box. Once a backend URL is set, the
/// same methods hit your API.
///
/// TODO(owner): if your backend's JSON differs, adjust the key names in
/// models.dart (Shop.fromJson / Product.fromJson / HiveEvent.fromJson) and the
/// paths in config.dart — you should not need to touch the screens.
class Repository {
  Repository({ApiClient? api}) : api = api ?? ApiClient();

  final ApiClient api;

  bool get live => AppConfig.useLiveData;

  Future<List<Shop>> fetchShops() async {
    if (!live) return mockShops;
    final data = await api.get(AppConfig.shopsPath);
    return (data as List).map((e) => Shop.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Product>> fetchProducts() async {
    if (!live) return mockProducts;
    final data = await api.get(AppConfig.productsPath);
    return (data as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<HiveEvent>> fetchEvents() async {
    if (!live) return mockEvents;
    try {
      final data = await api.get(AppConfig.eventsPath);
      return (data as List).map((e) => HiveEvent.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Events are optional — fall back to the demo list if the endpoint is absent.
      return mockEvents;
    }
  }

  // --- Orders & payments -----------------------------------------------------

  /// Creates an order and returns its id. In demo mode a local id is minted.
  /// The server computes prices and delivery fees; only product ids, quantities,
  /// and the selected delivery method are sent.
  Future<String> createOrder(
    List<CartLine> cart, {
    required String deliveryMethod,
  }) async {
    if (!live) {
      return 'UH${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
    final data = await api.post(AppConfig.ordersPath, {
      'items': cart.map((l) => {'productId': l.product.id, 'quantity': l.qty}).toList(),
      'deliveryMethod': deliveryMethod,
    });
    return '${(data as Map)['id'] ?? data['orderId']}';
  }

  /// Asks the backend to send an M-Pesa STK push to [phone]. This does NOT mean
  /// payment succeeded — confirm with [verifyPayment]. In demo mode it simply
  /// waits (no real charge).
  Future<void> startMpesaPayment({required String orderId, required String phone}) async {
    if (!live) {
      await Future.delayed(const Duration(milliseconds: 1200));
      return;
    }
    await api.post(AppConfig.mpesaStkPushPath, {'orderId': orderId, 'phoneNumber': phone});
  }

  /// Returns true once the backend has confirmed the payment. In demo mode we
  /// treat the simulated push as paid so the flow completes.
  Future<bool> verifyPayment(String orderId) async {
    if (!live) return true;
    final data = await api.get(
      AppConfig.paymentVerifyPath,
      query: {'orderId': orderId},
    );
    return data is Map && (data['verified'] == true || data['status'] == 'PAID');
  }

  /// Publishes a seller listing. In demo mode it is kept in memory only.
  Future<Product> createListing(Product p) async {
    if (!live) return p;
    final data = await api.post(AppConfig.productsPath, p.toCreateJson());
    return Product.fromJson(data as Map<String, dynamic>);
  }

  // --- Supabase Auth ---------------------------------------------------------

  Future<String?> login(String email, String password) async {
    if (!live) return null;
    final data = await api.post(AppConfig.loginPath, {'email': email, 'password': password});
    final token = (data as Map)['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw ApiException('Sign-in did not return an active session', 401);
    }
    api.authToken = token;
    return token;
  }

  Future<String?> register(String name, String email, String password) async {
    if (!live) return null;
    final data = await api.post(AppConfig.registerPath, {
      'name': name,
      'email': email,
      'password': password,
      'data': {'name': name},
    });
    final token = (data as Map)['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw ApiException(
        'Account created without a session. Verify your email, then sign in.',
        401,
      );
    }
    api.authToken = token;
    return token;
  }
}
