import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'shell.dart';

/// Premium dark-gold sign in / create account screen.
/// Works in demo mode (any valid-looking credentials get you in) and against a
/// real backend via AppState.signIn / signUp.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  // Ambient background drift + staggered entrance.
  late final AnimationController _bg =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat(reverse: true);
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isLogin = true;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _bg.dispose();
    _intro.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Animation<double> _step(double begin, double end) => CurvedAnimation(
        parent: _intro,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );

  void _switchMode(bool login) {
    if (login == _isLogin) return;
    setState(() {
      _isLogin = login;
      _error = null;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final s = context.read<AppState>();
    try {
      if (_isLogin) {
        await s.signIn(_email.text.trim(), _password.text);
      } else {
        await s.signUp(_name.text.trim(), _email.text.trim(), _password.text);
      }
      if (!mounted) return;
      _enterApp();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  void _guest() {
    context.read<AppState>().continueAsGuest();
    _enterApp();
  }

  void _enterApp() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: Shell(key: shellKey)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UH.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        _animatedBackdrop(),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _header(),
                  const SizedBox(height: 28),
                  _card(),
                  const SizedBox(height: 18),
                  _guestAndTerms(),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // --- Ambient background ----------------------------------------------------
  Widget _animatedBackdrop() {
    return AnimatedBuilder(
      animation: _bg,
      builder: (_, __) {
        final t = _bg.value;
        return Stack(children: [
          const Positioned.fill(child: ColoredBox(color: UH.bg)),
          _glow(
            align: Alignment(-0.9 + 0.3 * t, -0.95 + 0.1 * t),
            color: UH.gold.withOpacity(0.22),
            size: 360,
          ),
          _glow(
            align: Alignment(0.95 - 0.2 * t, -0.2 + 0.25 * t),
            color: const Color(0xFF7A0A12).withOpacity(0.28),
            size: 320,
          ),
          _glow(
            align: Alignment(0.2 * math.sin(t * math.pi), 0.95),
            color: const Color(0xFF3B0A45).withOpacity(0.30),
            size: 380,
          ),
        ]);
      },
    );
  }

  Widget _glow({required Alignment align, required Color color, required double size}) => Align(
        alignment: align,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, Colors.transparent]),
          ),
        ),
      );

  // --- Header ----------------------------------------------------------------
  Widget _header() {
    final a = _step(0.0, 0.55);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, -0.15), end: Offset.zero).animate(a),
        child: Column(children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [UH.gold, Color(0xFFF6DFA0)],
              ),
              boxShadow: [BoxShadow(color: UH.gold.withOpacity(0.35), blurRadius: 28, offset: const Offset(0, 10))],
            ),
            child: const Icon(Icons.hexagon, size: 38, color: UH.onGold),
          ),
          const SizedBox(height: 16),
          const Text('UniHive',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: UH.gold, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('THE GOODS & THE BUZZ', style: eyebrow(color: UH.muted)),
        ]),
      ),
    );
  }

  // --- Card ------------------------------------------------------------------
  Widget _card() {
    final a = _step(0.2, 0.9);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(a),
        child: Container(
          // Gradient hairline border for the premium feel.
          padding: const EdgeInsets.all(1.4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [UH.gold.withOpacity(0.55), Colors.white.withOpacity(0.04), UH.gold.withOpacity(0.18)],
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 30, offset: const Offset(0, 18))],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: const Color(0xFF081109),
            ),
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _segmented(),
                const SizedBox(height: 22),
                Text(
                  _isLogin ? 'Welcome back' : 'Join the Hive',
                  style: serif(23, color: UH.text),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLogin
                      ? 'Sign in to shop, sell and catch the Buzz.'
                      : 'Create your account — it takes a minute.',
                  style: const TextStyle(color: UH.muted, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Name (sign up only) — animates in/out.
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  child: _isLogin
                      ? const SizedBox(width: double.infinity)
                      : Column(children: [
                          _field(
                            controller: _name,
                            label: 'Full name',
                            icon: Icons.person_outline,
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                (!_isLogin && (v ?? '').trim().isEmpty) ? 'Enter your name' : null,
                          ),
                          const SizedBox(height: 14),
                        ]),
                ),

                _field(
                  controller: _email,
                  label: 'Email address',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final t = (v ?? '').trim();
                    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
                    return ok ? null : 'Enter a valid email';
                  },
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _password,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20, color: UH.muted),
                  ),
                  validator: (v) =>
                      (v ?? '').length < 8 ? 'At least 8 characters' : null,
                ),

                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password reset is coming soon.')),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: UH.gold,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Forgot password?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),

                // Error banner.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _error == null
                      ? const SizedBox(width: double.infinity)
                      : Container(
                          key: const ValueKey('err'),
                          margin: const EdgeInsets.only(top: 6, bottom: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: UH.danger.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: UH.danger.withOpacity(0.4)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline, color: UH.danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12))),
                          ]),
                        ),
                ),

                const SizedBox(height: 18),
                _primaryButton(),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _segmented() {
    Widget seg(String label, bool login) {
      final active = _isLogin == login;
      return Expanded(
        child: GestureDetector(
          onTap: () => _switchMode(login),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: active ? UH.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: active
                  ? [BoxShadow(color: UH.gold.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: active ? UH.onGold : UH.muted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(children: [seg('Sign In', true), seg('Create Account', false)]),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(color: UH.text, fontSize: 14, fontWeight: FontWeight.w500),
      cursorColor: UH.gold,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: UH.muted, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: UH.gold),
        prefixIcon: Icon(icon, size: 20, color: UH.muted),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.black.withOpacity(0.25),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UH.gold, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: UH.danger.withOpacity(0.7)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: UH.danger, width: 1.4),
        ),
      ),
    );
  }

  Widget _primaryButton() {
    return GestureDetector(
      onTap: _busy ? null : _submit,
      child: AnimatedScale(
        scale: _busy ? 0.99 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: [UH.gold, Color(0xFFF6DFA0)]),
            boxShadow: [BoxShadow(color: UH.gold.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: _busy
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: UH.onGold),
                )
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    _isLogin ? 'Sign In to the Hive' : 'Create Account',
                    style: const TextStyle(color: UH.onGold, fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: UH.onGold, size: 18),
                ]),
        ),
      ),
    );
  }

  Widget _guestAndTerms() {
    final a = _step(0.45, 1.0);
    return FadeTransition(
      opacity: a,
      child: Column(children: [
        Row(children: [
          Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: UH.muted, fontSize: 12))),
          Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _guest,
            style: OutlinedButton.styleFrom(
              foregroundColor: UH.text,
              side: BorderSide(color: Colors.white.withOpacity(0.14)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.explore_outlined, size: 18),
            label: const Text('Continue as guest', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'By continuing you agree to UniHive’s Terms & Privacy Policy.',
          textAlign: TextAlign.center,
          style: TextStyle(color: UH.muted.withOpacity(0.8), fontSize: 11, height: 1.4),
        ),
        if (!AppConfig.useLiveData) ...[
          const SizedBox(height: 8),
          Text(
            'Demo mode — any email and an 8+ character password works.',
            textAlign: TextAlign.center,
            style: TextStyle(color: UH.gold.withOpacity(0.8), fontSize: 11),
          ),
        ],
      ]),
    );
  }
}
