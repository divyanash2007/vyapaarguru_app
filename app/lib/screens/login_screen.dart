import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _step = 0;
  final _phoneCtrl = TextEditingController();
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  final _otpFocuses = List.generate(6, (_) => FocusNode());
  final _shopNameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  String? _shopType;

  void _goBack() => setState(() => _step--);

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: i == _step ? AppColors.accent : ext.border),
                )),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _phoneStep();
      case 1: return _otpStep();
      case 2: return _shopStep();
      case 3: return _successStep();
      default: return const SizedBox();
    }
  }

  Widget _phoneStep() {
    final ext = context.appTheme;
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(width: 60, height: 60, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))]),
            child: const Icon(Icons.shopping_bag_outlined, size: 32, color: Colors.white)),
          const SizedBox(height: 16),
          Text('Welcome to VyapaarGuru', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: ext.fg)),
          const SizedBox(height: 8),
          Text('Enter your mobile number to get started', style: TextStyle(fontSize: 14, color: ext.fgMuted)),
          const SizedBox(height: 32),
          // Features list
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WHAT YOU\'LL GET', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.fg, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                ...[
                  'Inventory management with barcode scanning',
                  'Direct dealer ordering and customer billing',
                  'AI-powered business insights and suggestions',
                  'WhatsApp integration for customer bills',
                ].map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Icon(Icons.check_circle_outline, size: 16, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Expanded(child: Text(t, style: TextStyle(fontSize: 13, color: ext.fgMuted))),
                  ]),
                )),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppInput(label: 'Mobile Number', hint: '9876543210', controller: _phoneCtrl, keyboardType: TextInputType.phone, maxLength: 10,
            prefix: Padding(padding: const EdgeInsets.only(left: 12, top: 12), child: Text('+91', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: ext.fg)))),
          const SizedBox(height: 8),
          Text.rich(TextSpan(text: 'By continuing, you agree to our ', style: TextStyle(fontSize: 11, color: ext.fgMuted), children: [
            TextSpan(text: 'Terms of Service', style: const TextStyle(color: AppColors.accent)),
            const TextSpan(text: ' and '),
            TextSpan(text: 'Privacy Policy', style: const TextStyle(color: AppColors.accent)),
          ]), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          AppButton(label: 'Send OTP', full: true, onPressed: () {
            if (_phoneCtrl.text.length == 10) setState(() => _step = 1);
          }),
        ],
      ),
    );
  }

  Widget _otpStep() {
    final ext = context.appTheme;
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: _goBack, icon: Icon(Icons.arrow_back, color: ext.fg))),
          const SizedBox(height: 16),
          Text('Verify OTP', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: ext.fg)),
          const SizedBox(height: 8),
          Text.rich(TextSpan(text: 'Enter the 6-digit code sent to\n', style: TextStyle(fontSize: 14, color: ext.fgMuted), children: [
            TextSpan(text: '+91 ${_phoneCtrl.text}', style: TextStyle(fontWeight: FontWeight.w600, color: ext.fg)),
          ]), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) => Container(
              width: 38, height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _otpCtrls[i], focusNode: _otpFocuses[i],
                textAlign: TextAlign.center, keyboardType: TextInputType.number, maxLength: 1,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ext.fg),
                decoration: InputDecoration(counterText: '', filled: true, fillColor: ext.surface2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: ext.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.accent)), contentPadding: EdgeInsets.zero),
                onChanged: (v) { if (v.isNotEmpty && i < 5) _otpFocuses[i + 1].requestFocus(); },
              ),
            )),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Didn\'t receive code?', style: TextStyle(fontSize: 13, color: ext.fgMuted)),
            GestureDetector(onTap: () {}, child: const Text('Resend OTP', style: TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w500))),
          ]),
          const SizedBox(height: 32),
          AppButton(label: 'Verify & Continue', full: true, onPressed: () => setState(() => _step = 2)),
        ],
      ),
    );
  }

  Widget _shopStep() {
    final ext = context.appTheme;
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: _goBack, icon: Icon(Icons.arrow_back, color: ext.fg))),
          const SizedBox(height: 16),
          Text('Setup Your Shop', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: ext.fg)),
          const SizedBox(height: 8),
          Text('Tell us about your business to personalize your experience', style: TextStyle(fontSize: 14, color: ext.fgMuted), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.accent), const SizedBox(width: 8), Text('Shop Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ext.fg))]),
                const SizedBox(height: 12),
                AppInput(label: 'Shop Name', hint: 'e.g. Sharma General Store', controller: _shopNameCtrl),
                Row(children: [
                  Expanded(child: AppInput(label: 'Owner Name', hint: 'Your name', controller: _ownerCtrl)),
                  const SizedBox(width: 10),
                  Expanded(child: AppDropdown(label: 'Shop Type', items: const ['General Store', 'Medical', 'Electronics', 'Clothing', 'Grocery', 'Other'], value: _shopType, onChanged: (v) => setState(() => _shopType = v))),
                ]),
                AppInput(label: 'Shop Address', hint: 'Enter your shop address', maxLines: 3),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton(label: 'Complete Setup', full: true, onPressed: () {
            if (_shopNameCtrl.text.isNotEmpty && _ownerCtrl.text.isNotEmpty) setState(() => _step = 3);
          }),
        ],
      ),
    );
  }

  Widget _successStep() {
    final ext = context.appTheme;
    return Center(
      key: const ValueKey(3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0), duration: const Duration(milliseconds: 600), curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(width: 80, height: 80, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success), child: const Icon(Icons.check, size: 40, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            Text('Welcome to VyapaarGuru!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ext.fg)),
            const SizedBox(height: 8),
            Text('Your shop is ready to go', style: TextStyle(fontSize: 14, color: ext.fgMuted)),
            const SizedBox(height: 32),
            AppButton(label: 'Start Managing Your Shop', full: true, onPressed: () => Navigator.pushReplacementNamed(context, '/home')),
          ],
        ),
      ),
    );
  }
}
