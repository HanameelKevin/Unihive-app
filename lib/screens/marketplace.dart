import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

class MarketplaceScreen extends StatefulWidget {
  final String? initialCategory;
  final bool standalone; // opened from a category tile (pushed route)
  const MarketplaceScreen({super.key, this.initialCategory, this.standalone = false});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late String category = marketCategories.contains(widget.initialCategory) ? widget.initialCategory! : 'All Products';
  String query = '';
  int shuffleSeed = 0;
  int visible = 8;

  @override
  Widget build(BuildContext context) {
    final all = context.watch<AppState>().allProducts;
    var list = all.where((p) {
      final inCat = category == 'All Products' || p.category == category;
      final q = query.trim().toLowerCase();
      final inQ = q.isEmpty || p.title.toLowerCase().contains(q) || p.description.toLowerCase().contains(q);
      return inCat && inQ;
    }).toList();
    if (shuffleSeed > 0) list.shuffle(Random(shuffleSeed));
    final shown = list.take(visible).toList();

    return Scaffold(
      appBar: widget.standalone ? AppBar(title: Text(widget.initialCategory ?? 'Marketplace', style: serif(20))) : const UHAppBar(),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => query = v),
                  decoration: const InputDecoration(hintText: 'Search products...', prefixIcon: Icon(Icons.search, size: 20)),
                ),
              ),
            ]),
          ),
        ),
        if (!widget.standalone) const SliverToBoxAdapter(child: _PromoBanner()),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              scrollDirection: Axis.horizontal,
              itemCount: marketCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = marketCategories[i];
                final sel = c == category;
                return ChoiceChip(
                  label: Text(c),
                  selected: sel,
                  showCheckmark: false,
                  selectedColor: UH.gold,
                  labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? UH.onGold : null),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (_) => setState(() {
                    category = c;
                    visible = 8;
                  }),
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            child: Row(children: [
              Text('${list.length} items', style: TextStyle(color: mutedOf(context), fontSize: 12)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => shuffleSeed++),
                icon: const Icon(Icons.shuffle, size: 16),
                label: const Text('Shuffle'),
                style: TextButton.styleFrom(foregroundColor: mutedOf(context)),
              ),
            ]),
          ),
        ),
        if (shown.isEmpty)
          const SliverToBoxAdapter(child: EmptyState(icon: Icons.search_off, text: 'Nothing here yet. Try another category or search.'))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((_, i) => ProductCard(shown[i]), childCount: shown.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.52),
            ),
          ),
        if (shown.length < list.length)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(child: OutlinedButton(onPressed: () => setState(() => visible += 8), child: const Text('Load More'))),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ]),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();
  @override
  Widget build(BuildContext context) {
    final events = context.watch<AppState>().events;
    if (events.isEmpty) return const SizedBox.shrink();
    final e = events.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
            decoration: const BoxDecoration(
              gradient: RadialGradient(center: Alignment(0.6, -0.2), radius: 1.2, colors: [Color(0xFF7A0A12), Color(0xFF1A0003)]),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('THIS FRIDAY · 25% OFF REGULAR · 20% OFF VIP', style: eyebrow().copyWith(fontSize: 9, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text('No Going Home.', style: serif(30, color: Colors.white)),
              const SizedBox(height: 8),
              Text('THE HIVE · ${e.date} · 6PM–4AM · ${e.venue.split(',').first}. Costumes, Smirnoff, DJs till sunrise.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: const StadiumBorder()),
                onPressed: () => goTab(context, 2),
                icon: const Text('Enter the Hive', style: TextStyle(fontWeight: FontWeight.w700)),
                label: const Icon(Icons.arrow_forward, size: 16),
              ),
            ]),
          ),
          const TipBar(),
        ]),
      ),
    );
  }
}

/// Used by shop pages too.
class ProductGrid extends StatelessWidget {
  final List<Product> items;
  const ProductGrid(this.items, {super.key});
  @override
  Widget build(BuildContext context) => GridView.builder(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.52),
        itemBuilder: (_, i) => ProductCard(items[i]),
      );
}
