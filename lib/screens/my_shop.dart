import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../data/models.dart';
import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

/// Seller dashboard — mirrors /myshop: stats, Products / My Services / Orders tabs,
/// empty state with "Create Your First Listing".
class MyShopScreen extends StatelessWidget {
  const MyShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    void addProduct() => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen()));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const UHAppBar(),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: UH.gold,
          foregroundColor: UH.onGold,
          onPressed: addProduct,
          icon: const Icon(Icons.add),
          label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('My Shop', style: serif(28)),
                  const SizedBox(height: 10),
                  Row(children: [
                    _MiniStat('${s.myListings.length}', 'Listings'),
                    _MiniStat('${s.orders.length}', 'Pending Orders'),
                    const _MiniStat('Seller', 'Account Type', valueColor: Color(0xFFF97316)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () => toast(context, 'Shop customization coming soon'), icon: const Icon(Icons.settings_outlined, size: 16), label: const Text('Customize Shop'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton.icon(onPressed: () => _showTerms(context), icon: const Icon(Icons.menu_book_outlined, size: 16), label: const Text('Terms'))),
                  ]),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.1,
                    children: [
                      _StatCard('Active Listings', '${s.myListings.length}', Icons.inventory_2_outlined),
                      _StatCard('Total Sales', '0', Icons.shopping_bag_outlined),
                      _StatCard('Revenue', 'KES 0', Icons.attach_money),
                      _StatCard('Pending Orders', '${s.orders.length}', Icons.schedule),
                    ],
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(color: isDark(context) ? UH.bg : Colors.white, borderRadius: BorderRadius.circular(8)),
                  indicatorPadding: const EdgeInsets.all(4),
                  labelColor: accentOf(context),
                  unselectedLabelColor: mutedOf(context),
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: 'Products', iconMargin: EdgeInsets.zero),
                    Tab(icon: Icon(Icons.star_border, size: 18), text: 'My Services', iconMargin: EdgeInsets.zero),
                    Tab(icon: Icon(Icons.receipt_long_outlined, size: 18), text: 'Orders', iconMargin: EdgeInsets.zero),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(children: [
            s.myListings.isEmpty
                ? EmptyState(icon: Icons.inventory_2_outlined, text: 'You haven\'t posted any listings yet', action: 'Create Your First Listing', onAction: addProduct)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    children: [
                      for (final p in s.myListings)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 52, height: 52, child: ArtTile(colors: [p.tint, p.tint.withOpacity(0.5)], icon: p.icon, iconSize: 22))),
                          title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${p.category} · ${p.condition}'),
                          trailing: Text(kes(p.price), style: TextStyle(color: accentOf(context), fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
            const EmptyState(icon: Icons.star_border, text: 'Offer a service — braiding, tutoring, photography, design…', action: 'Add a Service'),
            s.orders.isEmpty
                ? EmptyState(icon: Icons.receipt_long_outlined, text: 'No orders yet.', action: 'Browse the Marketplace', onAction: () => goTab(context, 1))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final o in s.orders.reversed)
                        ListTile(
                          leading: const Icon(Icons.local_shipping_outlined, color: UH.gold),
                          title: Text('Order #$o'),
                          subtitle: const Text('Awaiting seller confirmation'),
                        ),
                    ],
                  ),
          ]),
        ),
      ),
    );
  }

  void _showTerms(BuildContext context) => showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Text(
            'Seller terms (summary)\n\n• List only items you own and can deliver.\n• Describe condition honestly — new, like new or good.\n• Respond to buyers within 24 hours.\n• No counterfeit, illegal or prohibited goods.\n• UniHive may remove listings that break these rules.',
            style: TextStyle(height: 1.5),
          ),
        ),
      );
}

class _MiniStat extends StatelessWidget {
  final String v, l;
  final Color? valueColor;
  const _MiniStat(this.v, this.l, {this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 22),
        child: Column(children: [
          Text(v, style: TextStyle(fontWeight: FontWeight.w800, color: valueColor)),
          Text(l, style: TextStyle(fontSize: 11, color: mutedOf(context))),
        ]),
      );
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatCard(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            Icon(icon, size: 16, color: mutedOf(context)),
          ]),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        ]),
      );
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final price = TextEditingController();
  final desc = TextEditingController();
  final location = TextEditingController();
  String category = marketCategories[1];
  String condition = 'new';

  @override
  void dispose() {
    for (final c in [title, price, desc, location]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Product', style: serif(20))),
      body: Form(
        key: form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // TODO(owner): wire real photo upload. Add the `image_picker` package,
          // pick an image here, upload it (see Repository/AppConfig.uploadPath),
          // and set the returned URL on the Product below (imageUrl).
          InkWell(
            onTap: () => toast(context, 'Photo picker — add the image_picker package to enable'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 150,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: UH.gold.withOpacity(0.5))),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_a_photo_outlined, color: accentOf(context), size: 34),
                const SizedBox(height: 6),
                Text('Add photos', style: TextStyle(color: accentOf(context), fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Title'), validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(
            controller: price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Price', prefixText: 'KES '),
            validator: (v) => int.tryParse(v ?? '') == null ? 'Enter a number' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [for (final c in marketCategories.skip(1)) DropdownMenuItem(value: c, child: Text(c))],
            onChanged: (v) => setState(() => category = v!),
          ),
          const SizedBox(height: 12),
          Text('Condition', style: TextStyle(color: mutedOf(context), fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            for (final c in ['new', 'like_new', 'good'])
              ChoiceChip(
                label: Text(c.replaceAll('_', ' ')),
                selected: condition == c,
                showCheckmark: false,
                selectedColor: UH.gold,
                labelStyle: TextStyle(color: condition == c ? UH.onGold : null, fontWeight: FontWeight.w600),
                onSelected: (_) => setState(() => condition = c),
              ),
          ]),
          const SizedBox(height: 12),
          TextFormField(controller: location, decoration: const InputDecoration(labelText: 'Pickup location (optional)', hintText: 'e.g. Qwetu Karen')),
          const SizedBox(height: 12),
          TextFormField(controller: desc, maxLines: 4, decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              await context.read<AppState>().addListing(Product(
                    id: 'mine-${DateTime.now().millisecondsSinceEpoch}',
                    title: title.text.trim(),
                    description: desc.text.trim().isEmpty ? 'No description' : desc.text.trim(),
                    price: int.parse(price.text),
                    condition: condition,
                    location: location.text.trim().isEmpty ? null : location.text.trim(),
                    category: category,
                    // Attributed to the signed-in seller's shop.
                    shopId: AppConfig.myShopId,
                    icon: Icons.sell,
                    tint: const Color(0xFF14532D),
                  ));
              navigator.pop();
              messenger.showSnackBar(const SnackBar(content: Text('Listing published to the Marketplace')));
            },
            child: const Text('Publish Listing'),
          ),
        ]),
      ),
    );
  }
}
