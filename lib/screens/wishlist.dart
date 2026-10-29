import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'marketplace.dart';
import 'shell.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final items = s.allProducts.where((p) => s.isWished(p.id)).toList();
    return Scaffold(
      appBar: AppBar(title: Text('Wishlist', style: serif(20))),
      body: items.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.favorite_border,
                text: 'Tap the heart on anything you like and it’ll wait for you here.',
                action: 'Browse the Marketplace',
                onAction: () => goTab(context, 1),
              ),
            )
          : SingleChildScrollView(child: ProductGrid(items)),
    );
  }
}
