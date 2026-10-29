/// =============================================================================
/// UniHive — owner configuration
/// =============================================================================
/// Without the Supabase build-time values, the app uses demo data and simulated
/// checkout. The Supabase client key is public; server/payment secrets never
/// belong in this Flutter application.
library;

class AppConfig {
  AppConfig._();

  /// Set using --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co.
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// A Supabase publishable/anon key is intended for client apps.
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get apiBaseUrl =>
      _supabaseUrl.replaceFirst(RegExp(r'/+$'), '');

  static const String shopsPath =
      '/rest/v1/shops?select=*&order=created_at.desc';
  static const String productsPath =
      '/rest/v1/products?select=*&is_active=eq.true&order=created_at.desc';
  static const String eventsPath = '/rest/v1/events?select=*';
  static const String ordersPath = '/functions/v1/create-order';
  static const String mpesaStkPushPath = '/functions/v1/mpesa-stk-push';
  static const String paymentVerifyPath = '/functions/v1/verify-payment';
  static const String loginPath = '/auth/v1/token?grant_type=password';
  static const String registerPath = '/auth/v1/signup';
  static const String uploadPath = '/storage/v1/object/product-images';

  /// The shop id used for in-memory demo listings.
  static const String myShopId = 'my-shop';

  static const String ticketsUrl = 'https://unihive.shop/services';
  static const String littlePromoCode = 'UNIHIVE26';
  static const String supportEmail = 'support@unihive.shop';

  /// Live mode requires a valid Supabase HTTPS URL and a client key.
  static bool get useLiveData {
    final uri = Uri.tryParse(apiBaseUrl);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.endsWith('.supabase.co') &&
        supabaseAnonKey.isNotEmpty;
  }

  /// No pre-issued user token is bundled; users authenticate at runtime.
  static String? get authTokenOrNull => null;
}
