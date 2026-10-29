import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth.dart';
import 'home.dart';
import 'marketplace.dart';
import 'buzz.dart';
import 'my_shop.dart';
import 'cart.dart';
import 'wishlist.dart';
import 'messages.dart';

/// App shell: the web top-nav (Home / Marketplace / My shop + icons)
/// becomes a bottom NavigationBar, with Buzz promoted to its own tab.
final shellKey = GlobalKey<ShellState>();

/// Jump to a bottom tab from anywhere (also from pushed routes).
void goTab(BuildContext context, int i) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  shellKey.currentState?.go(i);
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => ShellState();
}

class ShellState extends State<Shell> {
  int index = 0;
  void go(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<AppState>().cartCount;
    final pages = const [HomeScreen(), MarketplaceScreen(), BuzzScreen(), MyShopScreen(), CartScreen()];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: go,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Marketplace'),
          const NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'The Buzz'),
          const NavigationDestination(icon: Icon(Icons.store_mall_directory_outlined), selectedIcon: Icon(Icons.store_mall_directory), label: 'My shop'),
          NavigationDestination(
            icon: Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: const Icon(Icons.shopping_cart_outlined)),
            selectedIcon: Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: const Icon(Icons.shopping_cart)),
            label: 'Cart',
          ),
        ],
      ),
    );
  }
}

/// Shared top bar: wordmark + theme / messages / wishlist / cart actions.
class UHAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  const UHAppBar({super.key, this.title});
  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppBar(
      title: title == null ? const Wordmark() : Text(title!),
      actions: [
        _AccountButton(user: s.user),
        IconButton(
          tooltip: 'Theme',
          onPressed: s.toggleTheme,
          icon: Icon(isDark(context) ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
        ),
        IconButton(
          tooltip: 'Messages',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen())),
          icon: const Icon(Icons.chat_bubble_outline),
        ),
        IconButton(
          tooltip: 'Wishlist',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen())),
          icon: const Icon(Icons.favorite_border),
        ),
        CartBadgeIcon(onTap: () => goTab(context, 4)),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// App-bar avatar that opens the account sheet (profile + sign out).
class _AccountButton extends StatelessWidget {
  final AppUser? user;
  const _AccountButton({required this.user});

  @override
  Widget build(BuildContext context) {
    final showInitials = user != null && !user!.guest;
    return IconButton(
      tooltip: 'Account',
      onPressed: () => _showAccountSheet(context),
      icon: showInitials
          ? Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: UH.gold),
              child: Text(user!.initials,
                  style: const TextStyle(color: UH.onGold, fontSize: 12, fontWeight: FontWeight.w800)),
            )
          : const Icon(Icons.person_outline),
    );
  }
}

void _showAccountSheet(BuildContext context) {
  final s = context.read<AppState>();
  final user = s.user;
  final signedIn = user != null && !user.guest;

  void toAuth() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (r) => false,
    );
  }

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: UH.gold,
              child: Text(signedIn ? user.initials : '👋',
                  style: const TextStyle(color: UH.onGold, fontWeight: FontWeight.w800, fontSize: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(signedIn ? user.name : 'Browsing as guest',
                    style: serif(18), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (signedIn)
                  Text(user.email,
                      style: TextStyle(color: mutedOf(ctx), fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          if (signedIn)
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.pop(ctx);
                s.signOut();
                toAuth();
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign out'),
            )
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: UH.gold, foregroundColor: UH.onGold),
              onPressed: () {
                Navigator.pop(ctx);
                toAuth();
              },
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Sign in or create account'),
            ),
        ]),
      ),
    ),
  );
}
