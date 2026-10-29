import 'package:flutter/material.dart';
import '../config.dart';
import '../data/api_client.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../data/repository.dart';

class AppState extends ChangeNotifier {
  AppState({Repository? repo}) : _repo = repo ?? Repository(api: ApiClient());

  final Repository _repo;

  ThemeMode themeMode = ThemeMode.dark;

  // --- Catalog (seeded from demo data; replaced by the backend in bootstrap) --
  List<Shop> shops = [...mockShops];
  List<Product> products = [...mockProducts];
  List<HiveEvent> events = [...mockEvents];

  bool catalogLoading = false;
  String? catalogError; // non-null when a live refresh failed (demo data kept)

  // --- Auth --------------------------------------------------------------------
  AppUser? user;
  bool get isAuthenticated => user != null && !(user!.guest);
  bool get isGuest => user?.guest ?? false;

  /// True once the user has passed the auth gate (signed in or chose guest).
  bool get hasEntered => user != null;

  String _nameFromEmail(String email) {
    final local = email.split('@').first.replaceAll(RegExp(r'[._]+'), ' ').trim();
    if (local.isEmpty) return 'Student';
    return local
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// Signs in. In demo mode any valid-looking credentials are accepted so the
  /// flow is usable without a backend. With a backend, throws on bad creds.
  Future<void> signIn(String email, String password) async {
    if (AppConfig.useLiveData) {
      await _repo.login(email, password); // throws ApiException on failure
    }
    user = AppUser(name: _nameFromEmail(email), email: email);
    notifyListeners();
  }

  /// Registers a new account (demo-friendly; throws on failure when live).
  Future<void> signUp(String name, String email, String password) async {
    if (AppConfig.useLiveData) {
      await _repo.register(name, email, password);
    }
    user = AppUser(name: name.trim().isEmpty ? _nameFromEmail(email) : name.trim(), email: email);
    notifyListeners();
  }

  /// Browse without an account.
  void continueAsGuest() {
    user = const AppUser(name: 'Guest', email: '', guest: true);
    notifyListeners();
  }

  void signOut() {
    user = null;
    _repo.api.authToken = null;
    cart.clear();
    wishlist.clear();
    following.clear();
    notifyListeners();
  }

  // --- User session (in-memory demo; see Repository for real wiring) ----------
  final List<CartLine> cart = [];
  final Set<String> wishlist = {};
  final Set<String> following = {};
  final List<Product> myListings = [];
  final List<String> orders = [];

  /// Loads live data when a backend is configured. Safe to call on startup;
  /// in demo mode it is a no-op and the seeded sample data stays.
  Future<void> bootstrap() async {
    if (!AppConfig.useLiveData) return;
    catalogLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.fetchShops(),
        _repo.fetchProducts(),
        _repo.fetchEvents(),
      ]);
      shops = results[0] as List<Shop>;
      products = results[1] as List<Product>;
      events = results[2] as List<HiveEvent>;
      catalogError = null;
    } catch (e) {
      // Keep the seeded demo data visible rather than showing a blank app.
      catalogError = e.toString();
    } finally {
      catalogLoading = false;
      notifyListeners();
    }
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // --- Catalog lookups --------------------------------------------------------
  /// All products a shopper can see = the seller's own new listings + catalog.
  List<Product> get allProducts => [...myListings, ...products];

  Shop shopById(String id) => shops.firstWhere(
        (s) => s.id == id,
        orElse: () => shops.isNotEmpty ? shops.first : mockShops.first,
      );

  // --- Cart -------------------------------------------------------------------
  int get cartCount => cart.fold(0, (a, l) => a + l.qty);
  int get cartTotal => cart.fold(0, (a, l) => a + l.total);

  void addToCart(Product p) {
    final i = cart.indexWhere((l) => l.product.id == p.id);
    if (i >= 0) {
      cart[i].qty++;
    } else {
      cart.add(CartLine(p));
    }
    notifyListeners();
  }

  void changeQty(CartLine l, int delta) {
    l.qty += delta;
    if (l.qty <= 0) cart.remove(l);
    notifyListeners();
  }

  void removeLine(CartLine l) {
    cart.remove(l);
    notifyListeners();
  }

  // --- Checkout ---------------------------------------------------------------
  /// Creates an order on the backend (or a local id in demo mode).
  Future<String> createOrder(String deliveryMethod) =>
      _repo.createOrder(cart, deliveryMethod: deliveryMethod);

  /// Sends the M-Pesa STK push for an order.
  Future<void> startMpesa(String orderId, String phone) =>
      _repo.startMpesaPayment(orderId: orderId, phone: phone);

  /// Confirms whether the order has been paid.
  Future<bool> verifyPayment(String orderId) => _repo.verifyPayment(orderId);

  /// Records a completed order locally and empties the cart.
  void recordOrder(String id) {
    orders.add(id);
    cart.clear();
    notifyListeners();
  }

  // --- Wishlist / follow ------------------------------------------------------
  bool isWished(String id) => wishlist.contains(id);
  void toggleWish(String id) {
    wishlist.contains(id) ? wishlist.remove(id) : wishlist.add(id);
    notifyListeners();
  }

  bool isFollowing(String id) => following.contains(id);
  void toggleFollow(String id) {
    following.contains(id) ? following.remove(id) : following.add(id);
    notifyListeners();
  }

  // --- Seller listings --------------------------------------------------------
  Future<void> addListing(Product p) async {
    final saved = await _repo.createListing(p);
    myListings.insert(0, saved);
    notifyListeners();
  }
}
