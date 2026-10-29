import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final shops = context.watch<AppState>().shops;
    // Demo inbox: a few shops with sample last-messages. Replace with a real
    // conversations endpoint when your backend has messaging.
    // TODO(owner): load real conversations here.
    final convos = shops.take(3).toList();
    const last = ['Yes, both colours are available 👍', 'I can meet you at CBD tomorrow', 'Mango blends are back this week!'];
    return Scaffold(
      appBar: AppBar(title: Text('Messages', style: serif(20))),
      body: convos.isEmpty
          ? Center(child: EmptyState(icon: Icons.chat_bubble_outline, text: 'No conversations yet.'))
          : ListView.separated(
        itemCount: convos.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(context).dividerColor),
        itemBuilder: (_, i) => ListTile(
          leading: ClipRRect(borderRadius: BorderRadius.circular(22), child: SizedBox(width: 44, height: 44, child: ArtTile(colors: convos[i].gradient, icon: convos[i].icon, iconSize: 20))),
          title: Text(convos[i].name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(last[i], maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text('${i + 1}h', style: TextStyle(color: mutedOf(context), fontSize: 12)),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(shop: convos[i]))),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final Shop shop;
  final Product? about;
  const ChatScreen({super.key, required this.shop, this.about});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ctrl = TextEditingController();
  late final List<(bool, String)> msgs = [
    (false, 'Hey 👋 welcome to ${widget.shop.name}! How can I help?'),
    if (widget.about != null) (true, 'Hi! Is “${widget.about!.title}” still available?'),
  ];

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void send() {
    final t = ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() => msgs.add((true, t)));
    ctrl.clear();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => msgs.add((false, 'Got it! I’ll get back to you shortly.')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.shop.name, style: serif(18))),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: msgs.length,
            itemBuilder: (_, i) {
              final (me, text) = msgs[i];
              return Align(
                alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: me ? UH.gold : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(text, style: TextStyle(color: me ? UH.onGold : null)),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: Row(children: [
              Expanded(child: TextField(controller: ctrl, onSubmitted: (_) => send(), decoration: const InputDecoration(hintText: 'Message…'))),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: UH.gold, foregroundColor: UH.onGold),
                onPressed: send,
                icon: const Icon(Icons.send),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
