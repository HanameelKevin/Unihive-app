import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

/// "The Buzz" — events side of UniHive. Darker, louder: wide display type,
/// red/purple glow, gold CTAs.
class BuzzScreen extends StatelessWidget {
  const BuzzScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final events = context.watch<AppState>().events;
    final upcoming = events.where((e) => !e.past).toList();
    final past = events.where((e) => e.past).toList();
    return Scaffold(
      backgroundColor: UH.bg,
      appBar: const UHAppBar(),
      body: ListView(padding: EdgeInsets.zero, children: [
        Container(
          color: UH.surface,
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(children: [
            Text('The Buzz', style: display(34, color: const Color(0xFFF5F0E1))),
            const SizedBox(height: 8),
            const Text('Events, experiences and the people who make them — straight from the Hive.',
                textAlign: TextAlign.center, style: TextStyle(color: UH.muted)),
            const SizedBox(height: 16),
            GoodsBuzzToggle(buzz: true, onChanged: (b) {
              if (!b) goTab(context, 1);
            }),
          ]),
        ),
        // Reel / teaser
        Container(
          height: 300,
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment(0.3, 0.2), radius: 1.1, colors: [Color(0xFF6B1A7A), Color(0xFF1A0A2E), UH.bg]),
          ),
          child: Stack(children: [
            Center(
              child: Container(
                width: 170,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF312E81), Color(0xFF701A75)]),
                  boxShadow: [BoxShadow(color: const Color(0xFFD946EF).withOpacity(0.4), blurRadius: 40)],
                ),
                child: Center(
                  child: Text('Unihive',
                      style: TextStyle(
                        fontSize: 34,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFFF0ABFC),
                        shadows: [Shadow(color: const Color(0xFFD946EF).withOpacity(0.9), blurRadius: 18)],
                      )),
                ),
              ),
            ),
            const Positioned(left: 16, bottom: 14, child: Text('Who are you when the lights go red?', style: TextStyle(color: Colors.white, fontSize: 13))),
            Positioned(right: 12, bottom: 8, child: IconButton(onPressed: () {}, icon: const Icon(Icons.volume_off_outlined, color: Colors.white70, size: 20))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
          child: Row(children: [
            Text('Events & tickets', style: display(18, color: Colors.white)),
            const Spacer(),
            const Text('All events →', style: TextStyle(color: UH.gold, fontWeight: FontWeight.w600, fontSize: 12)),
          ]),
        ),
        for (final e in upcoming) _EventCard(e),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 4),
          child: Text('It happened', style: display(18, color: Colors.white)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('You either were there, or you’re about to find out what you missed.', style: TextStyle(color: UH.muted, fontSize: 13)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: past.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 170,
                child: Stack(fit: StackFit.expand, children: [
                  ArtTile(colors: past[i].gradient, icon: Icons.nightlife, iconSize: 50),
                  Positioned(top: 10, left: 10, child: _Chip('IT HAPPENED')),
                  Positioned(left: 12, right: 12, bottom: 12, child: Text(past[i].title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String t;
  final bool gold;
  const _Chip(this.t, {this.gold = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: gold ? UH.gold : Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: gold ? null : Border.all(color: Colors.white24),
        ),
        child: Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: gold ? UH.onGold : Colors.white)),
      );
}

class _EventCard extends StatelessWidget {
  final HiveEvent e;
  const _EventCard(this.e);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: UH.gold.withOpacity(0.35)), color: Colors.black),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 260,
          width: double.infinity,
          child: Stack(fit: StackFit.expand, children: [
            Container(decoration: BoxDecoration(gradient: RadialGradient(colors: [e.gradient.last, e.gradient.first, Colors.black], radius: 0.9))),
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('THE', style: serif(14, color: const Color(0xFFFDE68A))),
                Text('HIVE', style: serif(54, color: const Color(0xFFFDE68A))),
                const Text('HALLOWEEN PARTY', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 3)),
              ]),
            ),
            const Positioned(top: 12, left: 12, child: _Chip('UP NEXT', gold: true)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.presenter, style: eyebrow(color: UH.buzzOrange)),
            const SizedBox(height: 8),
            Text(e.title, style: display(26, color: Colors.white)),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _Meta(Icons.calendar_today_outlined, e.date),
              _Meta(Icons.schedule, e.time),
              _Meta(Icons.place_outlined, e.venue),
            ]),
            const SizedBox(height: 14),
            Text('🎟️ ${e.offer}', style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                  onPressed: () => launchUrl(
                    Uri.parse(e.ticketUrl.isNotEmpty ? e.ticketUrl : AppConfig.ticketsUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: const Text('Tickets on Little ↗'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), shape: const StadiumBorder()),
                  onPressed: () => toast(context, 'Lineup drops soon 👀'),
                  child: const Text('Explore the night →'),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData i;
  final String t;
  const _Meta(this.i, this.t);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 14, color: UH.gold),
          const SizedBox(width: 6),
          Text(t, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ]),
      );
}
