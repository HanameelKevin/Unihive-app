import 'package:flutter/material.dart';

// --- Safe parse helpers (backends vary: numbers may arrive as String/num) ---
double _d(dynamic v, [double fallback = 0]) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? fallback;
int _i(dynamic v, [int fallback = 0]) =>
    v is num ? v.toInt() : int.tryParse('$v'.split('.').first) ?? fallback;
String? _s(dynamic v) => (v == null || '$v'.isEmpty) ? null : '$v';

/// Deterministic brand gradient so live data without colours still looks good.
List<Color> gradientFor(String seed) {
  const palettes = <List<Color>>[
    [Color(0xFF1A1A1A), Color(0xFF3A2E10)],
    [Color(0xFF1E1B4B), Color(0xFF0E7490)],
    [Color(0xFF14532D), Color(0xFFCA8A04)],
    [Color(0xFF831843), Color(0xFFF9A8D4)],
    [Color(0xFF2A1208), Color(0xFF7C4A1E)],
    [Color(0xFF052E16), Color(0xFF166534)],
    [Color(0xFF3F3F46), Color(0xFF71717A)],
    [Color(0xFF0A0A0A), Color(0xFF6B5310)],
  ];
  return palettes[seed.hashCode.abs() % palettes.length];
}

class Shop {
  final String id;
  final String name;
  final String tagline;
  final double rating;
  final int reviews;
  final List<Color> gradient; // placeholder banner until real images are wired
  final IconData icon;
  final String? bannerUrl;

  const Shop({
    required this.id,
    required this.name,
    required this.tagline,
    this.rating = 4.5,
    this.reviews = 10,
    required this.gradient,
    required this.icon,
    this.bannerUrl,
  });

  /// Maps a backend shop record. Expected JSON (adjust keys in one place if
  /// your API differs):
  /// { "id", "name", "tagline" | "bio", "rating", "reviews" | "reviewCount",
  ///   "bannerUrl" | "banner" | "image" }
  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
        id: '${j['id']}',
        name: _s(j['name']) ?? 'Shop',
        tagline: _s(j['tagline']) ?? _s(j['bio']) ?? '',
        rating: _d(j['rating'], 4.5),
        reviews: _i(j['reviews'] ?? j['reviewCount'], 0),
        gradient: gradientFor('${j['id']}'),
        icon: Icons.storefront,
        bannerUrl: _s(j['bannerUrl']) ??
            _s(j['banner_url']) ??
            _s(j['banner']) ??
            _s(j['image']) ??
            _s(j['avatar']),
      );
}

class Product {
  final String id;
  final String title;
  final String description;
  final int price; // KES
  final String condition; // new / like_new / good
  final String? location;
  final String category;
  final String shopId;
  final IconData icon;
  final Color tint;
  final String? imageUrl;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.condition = 'new',
    this.location,
    required this.category,
    required this.shopId,
    required this.icon,
    required this.tint,
    this.imageUrl,
  });

  /// Expected JSON:
  /// { "id", "title" | "name", "description", "price", "condition",
  ///   "location", "category", "shopId", "imageUrl" | "images"[0] }
  factory Product.fromJson(Map<String, dynamic> j) {
    final images = j['images'];
    final firstImage = (images is List && images.isNotEmpty) ? '${images.first}' : null;
    return Product(
      id: '${j['id']}',
      title: _s(j['title']) ?? _s(j['name']) ?? 'Item',
      description: _s(j['description']) ?? '',
      price: _i(j['price'] ?? j['price_kes'], 0),
      condition: _s(j['condition']) ?? 'new',
      location: _s(j['location']),
      category: _s(j['category']) ?? 'Other',
      shopId: '${j['shopId'] ?? j['shop_id'] ?? j['shop']?['id'] ?? ''}',
      icon: Icons.sell,
      tint: gradientFor('${j['id']}').first,
      imageUrl: _s(j['imageUrl']) ?? _s(j['image_url']) ?? firstImage,
    );
  }

  /// Sent to the backend when a seller publishes a listing.
  Map<String, dynamic> toCreateJson() => {
        'title': title,
        'name': title,
        'description': description,
        'price': price,
        'condition': condition,
        if (location != null) 'location': location,
        'category': category,
        'shopId': shopId,
        if (imageUrl != null) 'images': [imageUrl],
      };
}

class Partner {
  final String name;
  final String role;
  final List<Color> gradient;
  final IconData icon;
  final String? code;
  const Partner(this.name, this.role, this.gradient, this.icon, {this.code});
}

class BrowseCategory {
  final String name;
  final String subtitle;
  final IconData icon;
  const BrowseCategory(this.name, this.subtitle, this.icon);
}

class HiveEvent {
  final String title;
  final String presenter;
  final String date;
  final String time;
  final String venue;
  final String offer;
  final String ticketUrl;
  final bool past;
  final List<Color> gradient;
  const HiveEvent({
    required this.title,
    required this.presenter,
    required this.date,
    required this.time,
    required this.venue,
    required this.offer,
    required this.ticketUrl,
    this.past = false,
    required this.gradient,
  });

  factory HiveEvent.fromJson(Map<String, dynamic> j) => HiveEvent(
        title: _s(j['title']) ?? 'Event',
        presenter: _s(j['presenter']) ?? 'UNIHIVE',
        date: _s(j['date']) ?? '',
        time: _s(j['time']) ?? '',
        venue: _s(j['venue']) ?? '',
        offer: _s(j['offer']) ?? '',
        ticketUrl: _s(j['ticketUrl']) ?? _s(j['url']) ?? '',
        past: j['past'] == true,
        gradient: gradientFor(_s(j['title']) ?? 'event'),
      );
}

class AppUser {
  final String name;
  final String email;
  final bool guest;
  const AppUser({required this.name, required this.email, this.guest = false});

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        name: _s(j['name']) ?? 'Student',
        email: _s(j['email']) ?? '',
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class CartLine {
  final Product product;
  int qty;
  CartLine(this.product, [this.qty = 1]);
  int get total => product.price * qty;
}

String kes(num v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return 'KES $b';
}
