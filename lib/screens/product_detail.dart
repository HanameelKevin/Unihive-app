import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'messages.dart';
import 'shell.dart';
import 'shop_detail.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product p;
  const ProductDetailScreen(this.p, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final shop = s.shopById(p.shopId);
    final more = s.allProducts.where((x) => x.shopId == p.shopId && x.id != p.id).toList();

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          actions: [
            IconButton(
              onPressed: () => s.toggleWish(p.id),
              icon: Icon(s.isWished(p.id) ? Icons.favorite : Icons.favorite_border, color: s.isWished(p.id) ? UH.danger : null),
            ),
            IconButton(onPressed: () => toast(context, 'Product link copied'), icon: const Icon(Icons.share_outlined)),
            CartBadgeIcon(onTap: () => goTab(context, 4)),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(tag: 'p-${p.id}', child: ArtTile(url: p.imageUrl, colors: [p.tint, p.tint.withOpacity(0.5)], icon: p.icon, iconSize: 90)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, style: serif(26)),
              const SizedBox(height: 6),
              Text(kes(p.price), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accentOf(context))),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _Pill(Icons.sell_outlined, p.condition.replaceAll('_', ' ')),
                _Pill(Icons.category_outlined, p.category),
                if (p.location != null) _Pill(Icons.place_outlined, p.location!),
              ]),
              const SizedBox(height: 18),
              Text(p.description, style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 22),
              // Seller row
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopDetailScreen(shop))),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 46, height: 46, child: ArtTile(colors: shop.gradient, icon: shop.icon, iconSize: 22))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(shop.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Row(children: [
                          const Icon(Icons.star_rounded, size: 14, color: UH.gold),
                          Text(' ${shop.rating} · ${shop.reviews} reviews', style: TextStyle(fontSize: 12, color: mutedOf(context))),
                        ]),
                      ]),
                    ),
                    Text('View Seller', style: TextStyle(color: accentOf(context), fontWeight: FontWeight.w600, fontSize: 12)),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: UH.gold.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: UH.border)),
                child: const Row(children: [
                  Icon(Icons.verified_user_outlined, color: UH.gold, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text('No scams, no stress. Pay on collection at PickUp Mtaani points across Nairobi.', style: TextStyle(fontSize: 12))),
                ]),
              ),
              if (more.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('More from ${shop.name}', style: serif(18)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: more.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(more[i]))),
                      child: SizedBox(
                        width: 110,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(height: 90, width: 110, child: ArtTile(colors: [more[i].tint, more[i].tint.withOpacity(0.5)], icon: more[i].icon, iconSize: 28))),
                          const SizedBox(height: 4),
                          Text(more[i].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          Text(kes(more[i].price), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accentOf(context))),
                        ]),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 90),
            ]),
          ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(shop: shop, about: p))),
              child: const Icon(Icons.chat_bubble_outline, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  s.addToCart(p);
                  toast(context, 'Added to cart');
                },
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Add to Cart'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: mutedOf(context)),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 12)),
        ]),
      );
}
