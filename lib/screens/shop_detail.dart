import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'marketplace.dart';
import 'messages.dart';

class ShopDetailScreen extends StatelessWidget {
  final Shop shop;
  const ShopDetailScreen(this.shop, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final items = s.allProducts.where((p) => p.shopId == shop.id).toList();
    final following = s.isFollowing(shop.id);

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 230,
          pinned: true,
          actions: [IconButton(onPressed: () => toast(context, 'Shop link copied'), icon: const Icon(Icons.share_outlined))],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(shop.name, style: serif(16, color: Colors.white)),
            background: Stack(fit: StackFit.expand, children: [
              ArtTile(url: shop.bannerUrl, colors: shop.gradient, icon: shop.icon, iconSize: 80),
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87]))),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(shop.tagline, style: TextStyle(color: mutedOf(context))),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.star_rounded, color: UH.gold, size: 18),
                Text(' ${shop.rating}', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(' · ${shop.reviews} reviews · ${items.length} listings', style: TextStyle(color: mutedOf(context), fontSize: 13)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: following
                      ? OutlinedButton.icon(onPressed: () => s.toggleFollow(shop.id), icon: const Icon(Icons.check, size: 16), label: const Text('Following'))
                      : ElevatedButton.icon(onPressed: () => s.toggleFollow(shop.id), icon: const Icon(Icons.add, size: 16), label: const Text('Follow')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(shop: shop))),
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Message'),
                  ),
                ),
              ]),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: items.isEmpty
              ? const EmptyState(icon: Icons.inventory_2_outlined, text: 'This shop hasn’t posted any listings yet')
              : ProductGrid(items),
        ),
      ]),
    );
  }
}
