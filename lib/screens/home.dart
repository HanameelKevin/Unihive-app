import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'shell.dart';
import 'marketplace.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UHAppBar(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _HeroCarousel(),
          const TipBar(),
          const SectionTitle('Featured Shops', subtitle: 'Discover top Shops owned by entrepreneurs'),
          const _FeaturedShopsGrid(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllShopsScreen())),
              child: const Text('Explore All Shops'),
            ),
          ),
          const SectionTitle('Brands growing with the Hive', eyebrowText: 'OFFICIAL PARTNERS'),
          const _PartnersRow(),
          const SectionTitle('Browse Categories', subtitle: 'Explore what the Hive is selling — from tech to everyday essentials'),
          const _CategoryGrid(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel();
  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final ctrl = PageController();
  int page = 0;
  Timer? timer;

  static const _bgs = [
    [Color(0xFF0B0B1E), Color(0xFF2A1238), Color(0xFF0A0A0A)],
    [Color(0xFF06130D), Color(0xFF14532D), Color(0xFF040B08)],
    [Color(0xFF1A0003), Color(0xFF7A0A12), Color(0xFF0A0000)],
  ];

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!ctrl.hasClients) return;
      ctrl.animateToPage((page + 1) % heroSlides.length, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Height adapts to the screen so the hero text never overflows on small
    // phones or with larger system font sizes.
    final h = (MediaQuery.of(context).size.height * 0.6).clamp(440.0, 560.0);
    return SizedBox(
      height: h,
      child: Stack(children: [
        PageView.builder(
          controller: ctrl,
          itemCount: heroSlides.length,
          onPageChanged: (i) => setState(() => page = i),
          itemBuilder: (_, i) {
            final (eb, title, body) = heroSlides[i];
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(center: const Alignment(0.5, -0.4), radius: 1.3, colors: _bgs[i]),
              ),
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(eb, style: eyebrow()),
                const SizedBox(height: 10),
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: serif(40, color: Colors.white)),
                const SizedBox(height: 12),
                Text(body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14)),
                      onPressed: () => goTab(context, 1),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: const Text('Start Shopping'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: UH.gold, side: const BorderSide(color: UH.gold), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14)),
                      onPressed: () => goTab(context, 3),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Open Your Shop'),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                GoodsBuzzToggle(buzz: false, onChanged: (b) => goTab(context, b ? 2 : 1)),
              ]),
            );
          },
        ),
        Positioned(
          top: 14,
          right: 16,
          child: Row(
            children: List.generate(
              heroSlides.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(left: 5),
                width: i == page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(color: i == page ? UH.gold : Colors.white30, borderRadius: BorderRadius.circular(3)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Two-column staggered layout like the site's masonry grid.
class _FeaturedShopsGrid extends StatelessWidget {
  const _FeaturedShopsGrid();
  @override
  Widget build(BuildContext context) {
    final featured = context.watch<AppState>().shops.take(8).toList();
    final left = <Widget>[], right = <Widget>[];
    for (var i = 0; i < featured.length; i++) {
      final card = Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: ShopCard(featured[i], height: i % 3 == 0 ? 210 : 160),
      );
      (i.isEven ? left : right).add(card);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(children: left)),
        const SizedBox(width: 12),
        Expanded(child: Column(children: right)),
      ]),
    );
  }
}

class _PartnersRow extends StatelessWidget {
  const _PartnersRow();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: partners.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final p = partners[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 150,
              child: Stack(fit: StackFit.expand, children: [
                ArtTile(colors: p.gradient, icon: p.icon, iconSize: 48),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87], stops: [0.4, 1]),
                  ),
                ),
                if (p.code != null)
                  Align(
                    alignment: const Alignment(0, -0.1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(border: Border.all(color: UH.gold), borderRadius: BorderRadius.circular(4)),
                      child: Text(p.code!, style: const TextStyle(color: UH.gold, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700)),
                    ),
                  ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: serif(15, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(p.role, maxLines: 2, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ]),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();
  @override
  Widget build(BuildContext context) {
    const tints = [Color(0xFF3F2A14), Color(0xFF27272A), Color(0xFF7C2D12), Color(0xFF14532D)];
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: browseCategories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.15),
      itemBuilder: (_, i) {
        final c = browseCategories[i];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarketplaceScreen(initialCategory: c.name, standalone: true))),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(fit: StackFit.expand, children: [
              ArtTile(colors: [tints[i], tints[i].withOpacity(0.5)], icon: c.icon, iconSize: 40),
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87]))),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(radius: 15, backgroundColor: Colors.white, child: Icon(c.icon, size: 16, color: UH.onGold)),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                right: 10,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.name, style: serif(16, color: Colors.white)),
                  Text(c.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class AllShopsScreen extends StatelessWidget {
  const AllShopsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final shops = context.watch<AppState>().shops;
    return Scaffold(
      appBar: AppBar(title: Text('All Shops', style: serif(20))),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: shops.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 12, childAspectRatio: 0.6),
        itemBuilder: (_, i) => ShopCard(shops[i], height: 170),
      ),
    );
  }
}
