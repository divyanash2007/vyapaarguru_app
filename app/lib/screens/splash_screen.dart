import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    Future.delayed(const Duration(seconds: 3), () {
      _fadeCtrl.forward().then((_) {
        if (mounted) Navigator.pushReplacementNamed(context, '/onboarding');
      });
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0).animate(_fadeCtrl),
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 32, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, size: 44, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: ext.fg),
                  children: const [
                    TextSpan(text: 'Vyapaar'),
                    TextSpan(text: 'Guru', style: TextStyle(color: AppColors.accent)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Manage your shop.\nGrow your business.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: ext.fgMuted, height: 1.5)),
              const SizedBox(height: 32),
              _LoadingDots(),
              const SizedBox(height: 16),
              Text('Loading your dashboard...', style: TextStyle(fontSize: 14, color: ext.fgMuted, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat();
    });
    _ctrls[0].value = 0.77;
    _ctrls[1].value = 0.88;
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrls[i],
          builder: (_, __) {
            final v = _ctrls[i].value;
            final scale = v < 0.4 ? (v / 0.4) : (v < 0.8 ? 1.0 - ((v - 0.4) / 0.4) : 0.0);
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: scale.clamp(0.2, 1.0)),
              ),
            );
          },
        );
      }),
    );
  }
}
