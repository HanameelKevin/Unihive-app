import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../screens/product_detail.dart';
import '../screens/shop_detail.dart';

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color mutedOf(BuildContext c) => Theme.of(c).colorScheme.onSurfaceVariant;
Color accentOf(BuildContext c) => isDark(c) ? UH.gold : UH.onGold;

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1400)));
}

/// "UniHive" wordmark — gold Open Sans bold, as in the site header.
class Wordmark extends StatelessWidget {
  final double size;
  const Wordmark({super.key, this.size = 22});
  @override
  Widget build(BuildContext context) => Text('UniHive',
      style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: accentOf(context), letterSpacing: -0.3));
}

/// Image area: real network image when available, otherwise a branded gradient tile.
class ArtTile extends StatelessWidget {
  final String? url;
  final List<Color> colors;
  final IconData icon;
  final double iconSize;
  const ArtTile({super.key, this.url, required this.colors, required this.icon, this.iconSize = 42});

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Center(child: Icon(icon, size: iconSize, color: Colors.white.withOpacity(0.85))),
    );
    if (url == null) return fallback;
    return Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
  }
}

class SectionTitle extends StatelessWidget {
  final String? eyebrowText;
  final String title;
  final String? subtitle;
  final bool center;
  const SectionTitle(this.title, {super.key, this.eyebrowText, this.subtitle, this.center = true});

  @override
  Widget build(BuildContext context) {
    final align = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
      child: Column(crossAxisAlignment: align, children: [
        if (eyebrowText != null) ...[Text(eyebrowText!, style: eyebrow(color: accentOf(context))), const SizedBox(height: 6)],
        Text(title, textAlign: center ? TextAlign.center : TextAlign.start, style: serif(24)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, textAlign: center ? TextAlign.center : TextAlign.start, style: TextStyle(color: mutedOf(context))),
        ],
      ]),
    );
  }
}

/// TIP strip used under heroes on the site.
class TipBar extends StatefulWidget {
  final List<String> items;
  const TipBar({super.key, this.items = tips});
  @override
  State<TipBar> createState() => _TipBarState();
}

class _TipBarState extends State<TipBar> {
  int i = 0;
  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) setState(() => i = (i + 1) % widget.items.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark(context) ? Colors.black : const Color(0xFFF1EBD8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: UH.gold, borderRadius: BorderRadius.circular(3)),
          child: const Text('TIP', style: TextStyle(color: UH.onGold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(widget.items[i], key: ValueKey(i), style: const TextStyle(fontSize: 13)),
          ),
        ),
      ]),
    );
  }
}

/// The "🛍️ The Goods & ✨ The Buzz" pill switch.
class GoodsBuzzToggle extends StatelessWidget {
  final bool buzz;
  final ValueChanged<bool> onChanged;
  const GoodsBuzzToggle({super.key, required this.buzz, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool active, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: active ? UH.gold : Colors.transparent, borderRadius: BorderRadius.circular(30)),
            child: Text(label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? UH.onGold : Colors.white.withOpacity(0.85))),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg('🛍️ The Goods', !buzz, () => onChanged(false)),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('&', style: TextStyle(color: UH.gold, fontWeight: FontWeight.w700))),
        seg('✨ The Buzz', buzz, () => onChanged(true)),
      ]),
    );
  }
}

class CartBadgeIcon extends StatelessWidget {
  final VoidCallback onTap;
  const CartBadgeIcon({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final n = context.watch<AppState>().cartCount;
    return IconButton(
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: n > 0,
        backgroundColor: UH.gold,
        textColor: UH.onGold,
        label: Text('$n'),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}

/// Marketplace product card (matches site: image, heart, serif title, gold price,
/// short description, condition tag, location, View Seller, Add to Cart + share).
class ProductCard extends StatelessWidget {
  final Product p;
  const ProductCard(this.p, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final dark = isDark(context);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(p))),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 1.25,
            child: Stack(fit: StackFit.expand, children: [
              Hero(tag: 'p-${p.id}', child: ArtTile(url: p.imageUrl, colors: [p.tint, p.tint.withOpacity(0.55)], icon: p.icon)),
              Positioned(
                top: 6,
                right: 6,
                child: _RoundIcon(
                  icon: s.isWished(p.id) ? Icons.favorite : Icons.favorite_border,
                  color: s.isWished(p.id) ? UH.danger : Colors.white,
                  onTap: () => s.toggleWish(p.id),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: serif(14, w: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(kes(p.price), style: TextStyle(color: accentOf(context), fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(p.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: mutedOf(context))),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.sell_outlined, size: 11, color: mutedOf(context)),
                const SizedBox(width: 3),
                Text(p.condition, style: TextStyle(fontSize: 11, color: mutedOf(context))),
              ]),
              if (p.location != null)
                Row(children: [
                  Icon(Icons.place_outlined, size: 11, color: mutedOf(context)),
                  const SizedBox(width: 3),
                  Expanded(child: Text(p.location!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: mutedOf(context)))),
                ]),
            ]),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: dark ? UH.cardHi : const Color(0xFFF1EBD8),
                      foregroundColor: accentOf(context),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {
                      s.addToCart(p);
                      toast(context, 'Added “${p.title}” to cart');
                    },
                    icon: const Icon(Icons.add_shopping_cart, size: 15),
                    label: const Text('Add to Cart', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black.withOpacity(0.5),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 16, color: color)),
        ),
      );
}

/// Featured shop card: banner with share + Follow, name and rating overlay,
/// plus a strip of product thumbnails underneath.
class ShopCard extends StatelessWidget {
  final Shop shop;
  final double height;
  const ShopCard(this.shop, {super.key, this.height = 190});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final following = s.isFollowing(shop.id);
    final thumbs = s.allProducts.where((p) => p.shopId == shop.id).take(3).toList();
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopDetailScreen(shop))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: height,
            child: Stack(fit: StackFit.expand, children: [
              ArtTile(url: shop.bannerUrl, colors: shop.gradient, icon: shop.icon, iconSize: 56),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87], stops: [0.45, 1]),
                ),
              ),
              Positioned(top: 8, left: 8, child: _RoundIcon(icon: Icons.share_outlined, color: Colors.white, onTap: () => toast(context, 'Link to ${shop.name} copied'))),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => s.toggleFollow(shop.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: following ? UH.gold : Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(following ? 'Following' : 'Follow',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: following ? UH.onGold : Colors.white)),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(shop.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: serif(17, color: Colors.white)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.star_rounded, size: 14, color: UH.gold),
                    const SizedBox(width: 3),
                    Text('${shop.rating} · ${shop.reviews} reviews', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
        if (thumbs.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              for (final t in thumbs)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(width: 44, height: 44, child: ArtTile(url: t.imageUrl, colors: [t.tint, t.tint.withOpacity(0.6)], icon: t.icon, iconSize: 18)),
                  ),
                ),
            ],
          ),
        ],
      ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.icon, required this.text, this.action, this.onAction});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 44, color: mutedOf(context)),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: TextStyle(color: mutedOf(context))),
          if (action != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onAction, icon: const Icon(Icons.add, size: 16), label: Text(action!)),
          ],
        ]),
      );
}
