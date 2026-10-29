import 'package:flutter/material.dart';
import '../theme.dart';
import 'auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: const AuthScreen()),
      ));
    });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UH.bg,
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: c, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.easeOutBack)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.hexagon_outlined, size: 64, color: UH.gold),
              const SizedBox(height: 14),
              const Text('UniHive', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: UH.gold)),
              const SizedBox(height: 6),
              Text('THE GOODS & THE BUZZ', style: eyebrow(color: UH.muted)),
            ]),
          ),
        ),
      ),
    );
  }
}
