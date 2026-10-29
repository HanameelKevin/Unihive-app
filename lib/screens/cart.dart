import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../data/api_client.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text('Your Cart', style: serif(20))),
      body: s.cart.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.shopping_cart_outlined,
                text: 'Your cart is empty.\nThe Hive is full of good stuff.',
                action: 'Start Shopping',
                onAction: () => goTab(context, 1),
              ),
            )
          : ListView(padding: const EdgeInsets.all(16), children: [
              for (final l in s.cart) _CartRow(l),
              const SizedBox(height: 8),
              _Summary(total: s.cartTotal, count: s.cartCount),
            ]),
    );
  }
}

class _CartRow extends StatelessWidget {
  final CartLine l;
  const _CartRow(this.l);
  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final p = l.product;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 64, height: 64, child: ArtTile(url: p.imageUrl, colors: [p.tint, p.tint.withOpacity(0.5)], icon: p.icon, iconSize: 26))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: serif(14, w: FontWeight.w600)),
            Text('${kes(p.price)} each', style: TextStyle(fontSize: 11, color: mutedOf(context))),
            const SizedBox(height: 6),
            Row(children: [
              _QtyBtn(Icons.remove, () => s.changeQty(l, -1)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('${l.qty}', style: const TextStyle(fontWeight: FontWeight.w700))),
              _QtyBtn(Icons.add, () => s.changeQty(l, 1)),
            ]),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(kes(l.total), style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(children: [
            IconButton(visualDensity: VisualDensity.compact, onPressed: () => s.toggleWish(p.id), icon: Icon(s.isWished(p.id) ? Icons.favorite : Icons.favorite_border, size: 18)),
            IconButton(visualDensity: VisualDensity.compact, onPressed: () => s.removeLine(l), icon: const Icon(Icons.delete_outline, size: 18)),
          ]),
        ]),
      ]),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData i;
  final VoidCallback onTap;
  const _QtyBtn(this.i, this.onTap);
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: Theme.of(context).dividerColor)),
          child: Icon(i, size: 16),
        ),
      );
}

class _Summary extends StatelessWidget {
  final int total, count;
  const _Summary({required this.total, required this.count});
  @override
  Widget build(BuildContext context) {
    Widget row(String a, String b, {bool bold = false, bool italic = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Text(a, style: TextStyle(fontWeight: bold ? FontWeight.w800 : null, fontSize: bold ? 16 : 14)),
            const Spacer(),
            Text(b, style: TextStyle(fontWeight: bold ? FontWeight.w800 : null, fontSize: bold ? 16 : 13, fontStyle: italic ? FontStyle.italic : null, color: italic ? mutedOf(context) : null)),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Order Summary', style: serif(18)),
        const SizedBox(height: 10),
        row('Subtotal ($count items)', kes(total)),
        row('Delivery', 'Calculated at checkout', italic: true),
        const Divider(height: 20),
        row('Total', kes(total), bold: true),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: UH.success, foregroundColor: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
          icon: const Icon(Icons.credit_card, size: 18),
          label: const Text('Proceed to Checkout'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => goTab(context, 1), icon: const Icon(Icons.arrow_back, size: 16), label: const Text('Continue Shopping')),
      ]),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int delivery = 0; // 0 = PickUp Mtaani, 1 = Meet seller, 2 = Doorstep
  final phone = TextEditingController();
  bool placing = false;
  String? _pendingOrderId;

  static const _opts = [
    ('PickUp Mtaani point', 'Collect at an agent near campus', 150),
    ('Meet the seller', 'Arrange a safe spot in chat', 0),
    ('Doorstep delivery', 'Rider drops it to you (Nairobi)', 300),
  ];

  @override
  void dispose() {
    phone.dispose();
    super.dispose();
  }

  /// Create the order, trigger the M-Pesa STK push, then confirm payment.
  /// In demo mode (no backend configured) this completes immediately; with a
  /// backend it sends a real STK push and only proceeds once payment verifies.
  Future<void> _pay() async {
    final digits = phone.text.replaceAll(RegExp(r'\D'), '');
    if (_pendingOrderId == null && digits.length < 9) {
      toast(context, 'Enter your M-Pesa number');
      return;
    }
    final s = context.read<AppState>();
    setState(() => placing = true);
    try {
      var orderId = _pendingOrderId;
      if (orderId == null) {
        const deliveryMethods = ['pickup', 'meet_seller', 'doorstep'];
        orderId = await s.createOrder(deliveryMethods[delivery]);
        _pendingOrderId = orderId;
        try {
          await s.startMpesa(orderId, digits);
        } catch (error) {
          if (error is! ApiException || error.code != 'PAYMENT_OUTCOME_UNKNOWN') {
            _pendingOrderId = null;
          }
          rethrow;
        }
      }
      final paid = await s.verifyPayment(orderId);
      if (!context.mounted) return;
      if (paid) {
        _pendingOrderId = null;
        s.recordOrder(orderId);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OrderSuccessScreen(orderId: orderId)),
        );
      } else {
        setState(() => placing = false);
        toast(context, 'Payment is pending. Approve the M-Pesa prompt, then check again.');
      }
    } catch (e) {
      if (!context.mounted) return;
      setState(() => placing = false);
      toast(context, 'Payment failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final fee = _opts[delivery].$3;
    return Scaffold(
      appBar: AppBar(title: Text('Checkout', style: serif(20))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Delivery', style: serif(18)),
        const SizedBox(height: 8),
        for (var i = 0; i < _opts.length; i++)
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: delivery == i ? UH.gold : Theme.of(context).dividerColor),
            ),
            child: RadioListTile<int>(
              value: i,
              groupValue: delivery,
              activeColor: UH.gold,
              onChanged: _pendingOrderId == null
                  ? (v) => setState(() => delivery = v!)
                  : null,
              title: Text(_opts[i].$1, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_opts[i].$2, style: TextStyle(color: mutedOf(context), fontSize: 12)),
              secondary: Text(_opts[i].$3 == 0 ? 'Free' : kes(_opts[i].$3), style: TextStyle(color: accentOf(context), fontWeight: FontWeight.w700)),
            ),
          ),
        const SizedBox(height: 18),
        Text('Pay with M-Pesa', style: serif(18)),
        const SizedBox(height: 8),
        TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          readOnly: _pendingOrderId != null,
          decoration: const InputDecoration(prefixText: '+254 ', hintText: '7XX XXX XXX', prefixIcon: Icon(Icons.phone_android)),
        ),
        const SizedBox(height: 6),
        Text(
          AppConfig.useLiveData
              ? 'You’ll get an STK push on your phone — enter your M-Pesa PIN to pay.'
              : 'You’ll get an STK push to confirm. (Demo — no real payment is made.)',
          style: TextStyle(fontSize: 11, color: mutedOf(context)),
        ),
        const SizedBox(height: 20),
        _Line('Items', kes(s.cartTotal)),
        _Line('Delivery', fee == 0 ? 'Free' : kes(fee)),
        const Divider(),
        _Line('Total', kes(s.cartTotal + fee), bold: true),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: UH.success, foregroundColor: Colors.white),
          onPressed: placing || s.cart.isEmpty ? null : _pay,
          child: placing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_pendingOrderId == null
                  ? 'Pay ${kes(s.cartTotal + fee)}'
                  : 'Check payment status'),
        ),
      ]),
    );
  }
}

class _Line extends StatelessWidget {
  final String a, b;
  final bool bold;
  const _Line(this.a, this.b, {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text(a, style: TextStyle(fontWeight: bold ? FontWeight.w800 : null)),
          const Spacer(),
          Text(b, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ]),
      );
}

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  const OrderSuccessScreen({super.key, required this.orderId});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Icon(Icons.check_circle, size: 80, color: UH.gold),
              const SizedBox(height: 16),
              Text('Order placed!', textAlign: TextAlign.center, style: serif(30)),
              const SizedBox(height: 8),
              Text('Order #$orderId\nThe seller has been notified. Track it under My shop → Orders.',
                  textAlign: TextAlign.center, style: TextStyle(color: mutedOf(context))),
              const SizedBox(height: 28),
              ElevatedButton(onPressed: () => goTab(context, 0), child: const Text('Back to the Hive')),
            ]),
          ),
        ),
      );
}
