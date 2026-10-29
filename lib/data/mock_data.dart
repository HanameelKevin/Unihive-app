import 'package:flutter/material.dart';
import 'models.dart';

/// Demo data mirrored from unihive.shop (Oct 2026).
/// The live site is backed by Supabase — swap these lists for queries
/// (see README → "Connecting real data").

const mockShops = <Shop>[
  Shop(id: '2rare', name: '2rare⭐️', tagline: 'Phone covers · Protect | Style | Express', gradient: [Color(0xFF1A1A1A), Color(0xFF3A2E10)], icon: Icons.phone_iphone),
  Shop(id: 'techtribe', name: 'Techtribe ke', tagline: "Discover your tribe's next upgrade", gradient: [Color(0xFF1E1B4B), Color(0xFF0E7490)], icon: Icons.laptop_mac),
  Shop(id: 'y2k', name: 'Y2k cameras', tagline: 'Digicams & point-and-shoots', gradient: [Color(0xFF3F3F46), Color(0xFF71717A)], icon: Icons.photo_camera),
  Shop(id: 'muruha', name: 'Scents by Muruha', tagline: 'Fragrances & body mists', gradient: [Color(0xFF2A1208), Color(0xFF7C4A1E)], icon: Icons.spa),
  Shop(id: 'apparel', name: 'Apparel Pharmacy', tagline: 'Sneakers & streetwear', gradient: [Color(0xFF27272A), Color(0xFF52525B)], icon: Icons.directions_walk),
  Shop(id: 'curiosity', name: 'Curiosity corner 👾', tagline: 'Gifts, games & oddities', gradient: [Color(0xFF14532D), Color(0xFFCA8A04)], icon: Icons.emoji_objects),
  Shop(id: 'cece', name: 'Cece’s closet✨💕', tagline: 'Thrifted & curated fits', gradient: [Color(0xFF831843), Color(0xFFF9A8D4)], icon: Icons.checkroom),
  Shop(id: 'jnb', name: 'Jnbjewelry', tagline: 'Affordable luxury. Everyday elegance.', gradient: [Color(0xFF0A0A0A), Color(0xFF6B5310)], icon: Icons.diamond),
  Shop(id: 'wausi', name: 'wausicollective', tagline: 'The Collective · handmade jewelry', gradient: [Color(0xFF44403C), Color(0xFFD6CFC4)], icon: Icons.auto_awesome),
  Shop(id: 'madaha', name: 'Madaha Beauty', tagline: 'Statement gold pieces', gradient: [Color(0xFF3B2412), Color(0xFF8B5E34)], icon: Icons.face_retouching_natural),
  Shop(id: 'mimi', name: 'mimi_lewelry', tagline: 'Dainty jewelry', gradient: [Color(0xFF06130D), Color(0xFF14532D)], icon: Icons.favorite),
  Shop(id: 'eden', name: 'EDEN WELLNESS', tagline: 'Wellness blends · created for wholeness', gradient: [Color(0xFF365314), Color(0xFFF59E0B)], icon: Icons.local_drink),
  Shop(id: 'serena', name: 'Serena', tagline: 'Elegant everyday wear', gradient: [Color(0xFF052E16), Color(0xFF166534)], icon: Icons.local_florist),
  Shop(id: 'haven', name: 'Style heaven', tagline: 'Curated fashion pieces for everyday slay', gradient: [Color(0xFF052E16), Color(0xFF3F3A1E)], icon: Icons.shopping_bag),
  Shop(id: 'velora', name: 'Velora shipping store✈️', tagline: 'Imported phone cases & accessories', gradient: [Color(0xFF52525B), Color(0xFFA1A1AA)], icon: Icons.flight),
];

const mockProducts = <Product>[
  Product(id: 'p1', title: 'Cactus jack phone cases', description: '10/10 quality. Available for most iPhone models.', price: 600, category: 'Phone Accessories', shopId: '2rare', icon: Icons.phone_iphone, tint: Color(0xFF52525B)),
  Product(id: 'p2', title: 'Baths & Bodyworks', description: 'Body spray — Bare Vanilla.', price: 2800, location: 'Nyayo estate', category: 'Beauty', shopId: 'muruha', icon: Icons.spa, tint: Color(0xFFB45309)),
  Product(id: 'p3', title: 'Stardust set', description: 'Customized anklets.', price: 600, location: 'CBD', category: 'Jewelry', shopId: 'mimi', icon: Icons.auto_awesome, tint: Color(0xFFDB2777)),
  Product(id: 'p4', title: 'Sip & Misbehave', description: 'Be your best self. Graphic tee.', price: 1500, category: 'Clothes', shopId: 'cece', icon: Icons.checkroom, tint: Color(0xFF27272A)),
  Product(id: 'p5', title: 'Ringset', description: 'A set of stackable rings.', price: 400, location: 'Nairobi CBD, Beaver house', category: 'Jewelry', shopId: 'jnb', icon: Icons.radio_button_unchecked, tint: Color(0xFFCA8A04)),
  Product(id: 'p6', title: 'Eden wellness', description: 'Wellness drinks and blends, 500 ml.', price: 300, category: 'Beverages', shopId: 'eden', icon: Icons.local_drink, tint: Color(0xFF65A30D)),
  Product(id: 'p7', title: 'Heart necklace and earring', description: 'Heart drop jewelry set.', price: 300, location: 'Qejani residences, Karen', category: 'Jewelry', shopId: 'mimi', icon: Icons.favorite, tint: Color(0xFFDC2626)),
  Product(id: 'p8', title: 'Waist Chains', description: 'Pearl waist chains.', price: 1000, location: 'Qwetu Karen', category: 'Jewelry', shopId: 'wausi', icon: Icons.link, tint: Color(0xFFE7E5E4)),
  Product(id: 'p9', title: 'Air max', description: 'Both colours are available.', price: 3000, category: 'Shoes', shopId: 'apparel', icon: Icons.directions_run, tint: Color(0xFF3F3F46)),
  Product(id: 'p10', title: 'Ladies shoes', description: 'Open shoes, sizes 37–41.', price: 350, category: 'Shoes', shopId: 'haven', icon: Icons.directions_walk, tint: Color(0xFF7C2D12)),
  Product(id: 'p11', title: 'Brown hand bag', description: 'A brown hand bag in great shape.', price: 800, condition: 'good', category: 'Clothes', shopId: 'haven', icon: Icons.shopping_bag, tint: Color(0xFF78350F)),
  Product(id: 'p12', title: 'EARRINGS', description: 'Gold and silver hoops.', price: 100, location: 'Olerai Academy, Rongai', category: 'Jewelry', shopId: 'madaha', icon: Icons.blur_circular, tint: Color(0xFFA16207)),
  Product(id: 'p13', title: 'Olmo pocket camera', description: 'Olmo pocket camera, boxed.', price: 3500, location: 'Umoja 1', category: 'Electronics', shopId: 'y2k', icon: Icons.videocam, tint: Color(0xFF18181B)),
  Product(id: 'p14', title: 'Y2k neck Pieces', description: 'Silver neck pieces.', price: 500, location: 'Qwetu Karen', category: 'Jewelry', shopId: 'velora', icon: Icons.add_link, tint: Color(0xFF71717A)),
  Product(id: 'p15', title: 'Wired speakers', description: 'These wired speakers are loud and clear.', price: 2000, condition: 'like_new', category: 'Electronics', shopId: 'techtribe', icon: Icons.speaker, tint: Color(0xFF1E3A8A)),
  Product(id: 'p16', title: 'Island bliss by Armaf', description: 'Top notes: fruity, floral.', price: 3300, location: 'Hison plaza, Biashara street', category: 'Beauty', shopId: 'muruha', icon: Icons.water_drop, tint: Color(0xFF0E7490)),
];

const marketCategories = <String>[
  'All Products', 'Clothes', 'Electronics', 'Jewelry', 'Beauty', 'Shoes',
  'Phone Accessories', 'Beverages', 'Musical Instruments', 'Sports Equipment',
];

const browseCategories = <BrowseCategory>[
  BrowseCategory('Textbooks', 'Find your course materials', Icons.menu_book),
  BrowseCategory('Electronics', 'Student tech deals', Icons.laptop),
  BrowseCategory('Stationery', 'Notes and supplies', Icons.edit),
  BrowseCategory('Study Materials', 'Past papers and notes', Icons.school),
];

const partners = <Partner>[
  Partner('Smirnoff', 'Official drinks partner', [Color(0xFF7F1D1D), Color(0xFFDC2626)], Icons.local_bar),
  Partner('Red Bull', 'Energy for the night', [Color(0xFF1E3A8A), Color(0xFF2563EB)], Icons.bolt),
  Partner('Little', 'Tickets & rides', [Color(0xFF0A0A0A), Color(0xFF6B5310)], Icons.local_taxi, code: 'UNIHIVE26'),
  Partner('Siwaka Podcast', 'Official media outlet · TikTok', [Color(0xFF334155), Color(0xFF64748B)], Icons.mic),
  Partner('Charge24', 'Official power-bank charging station', [Color(0xFF000000), Color(0xFF14532D)], Icons.battery_charging_full),
  Partner('Harrison’s Pearl Gerar', 'Shawarma & hotdogs', [Color(0xFF7C2D12), Color(0xFFD97706)], Icons.lunch_dining),
];

const heroSlides = <(String, String, String)>[
  ('THE CULTURE', 'Built by us.\nFor us.', 'Not just a platform — a community you’re proud to be part of, online and in person.'),
  ('THE GOODS', 'Shop the Hive.', 'Storefronts run by students and young entrepreneurs. No scams, no stress.'),
  ('THE BUZZ', 'No Going Home.', 'THE HIVE · Fri 30 Oct · 6PM–4AM · Sarakasi Dome. Discounted tickets on Little.'),
];

const tips = <String>[
  'Ride with Little: code UNIHIVE26 for KSh 200 off rides to and from the Hive.',
  'Collect orders at PickUp Mtaani points across Nairobi.',
  'Follow the shops you love — new drops land in your feed first.',
];

const mockEvents = <HiveEvent>[
  HiveEvent(
    title: 'THE HIVE: NO GOING HOME',
    presenter: 'UNIHIVE PRESENTS',
    date: 'Fri, 30 Oct',
    time: '6PM',
    venue: 'Sarakasi Dome, Nairobi',
    offer: '25% off Regular · 20% off VIP — code UNIHIVE, applied for you on Little.',
    ticketUrl: 'https://unihive.shop/services',
    gradient: [Color(0xFF450A0A), Color(0xFFB91C1C)],
  ),
  HiveEvent(
    title: 'Waterfalls Island',
    presenter: 'IT HAPPENED',
    date: 'Sep',
    time: '',
    venue: 'Nairobi',
    offer: '',
    ticketUrl: 'https://unihive.shop/services',
    past: true,
    gradient: [Color(0xFF7F1D1D), Color(0xFF1C1917)],
  ),
  HiveEvent(
    title: 'Live on the Hive stage',
    presenter: 'IT HAPPENED',
    date: 'Aug',
    time: '',
    venue: 'Nairobi',
    offer: '',
    ticketUrl: 'https://unihive.shop/services',
    past: true,
    gradient: [Color(0xFF3B0764), Color(0xFF7E22CE)],
  ),
];

