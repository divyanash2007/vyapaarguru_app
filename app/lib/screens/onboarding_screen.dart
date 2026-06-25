import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _cur = 0;

  void _next() {
    if (_cur < 2) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    final isLast = _cur == 2;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _cur = i),
                children: const [
                  _Slide(
                    tag: 'Step 1 of 3', title: 'Smart Inventory\nat Your Fingertips',
                    body: 'Scan barcodes to add products instantly. Track stock levels, get low-stock alerts, and never run out of your best sellers.',
                    icon: Icons.inventory_2_outlined, accentColor: AppColors.accent,
                    cards: [('247', 'Products', null), ('12', 'Low Stock', AppColors.warn), ('+18%', 'This Week', AppColors.success), ('₹84K', 'Stock Value', null)],
                  ),
                  _Slide(
                    tag: 'Step 2 of 3', title: 'Bill Customers,\nSend Instantly',
                    body: 'Create bills in seconds with barcode scanning. Send directly to customers via WhatsApp or SMS — no printer needed.',
                    icon: Icons.description_outlined, accentColor: AppColors.success,
                    cards: [('₹1,240', 'Bill Total', null), ('Sent', 'WhatsApp', AppColors.success), ('3 items', 'In Cart', null), ('GST 5%', 'Applied', null)],
                  ),
                  _Slide(
                    tag: 'Step 3 of 3', title: 'AI Insights to\nGrow Your Business',
                    body: 'Get smart restock suggestions, pricing tips, and sales trends powered by AI.',
                    icon: Icons.show_chart, accentColor: AppColors.blue,
                    cards: [('AI', 'Suggestion', AppColors.blue), ('↑ 24%', 'Revenue', null), ('₹52K', 'This Month', null), ('Restock', 'Maggi', AppColors.success)],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 24),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _ctrl, count: 3,
                    effect: ExpandingDotsEffect(dotHeight: 8, dotWidth: 8, expansionFactor: 3, spacing: 8, dotColor: ext.border, activeDotColor: AppColors.accent),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (!isLast) Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: ext.border), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                          child: Text('Skip', style: TextStyle(color: ext.fgMuted, fontSize: 15)),
                        ),
                      ),
                      if (!isLast) const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentDk, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(isLast ? 'Get Started' : 'Next', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Icon(isLast ? Icons.check : Icons.chevron_right, size: 18),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final String tag, title, body;
  final IconData icon;
  final Color accentColor;
  final List<(String, String, Color?)> cards;

  const _Slide({required this.tag, required this.title, required this.body, required this.icon, required this.accentColor, required this.cards});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 56, 32, 0),
      child: Column(
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? [const Color(0xFF1A1A2E), accentColor.withValues(alpha: 0.15)] : [accentColor.withValues(alpha: 0.08), accentColor.withValues(alpha: 0.15)]),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: Stack(children: [
              Center(child: Container(width: 80, height: 80, decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)), child: Icon(icon, size: 44, color: accentColor))),
              if (cards.isNotEmpty) _card(cards[0], Alignment.topLeft, ext),
              if (cards.length > 1) _card(cards[1], Alignment.topRight, ext),
              if (cards.length > 2) _card(cards[2], Alignment.bottomLeft, ext),
              if (cards.length > 3) _card(cards[3], Alignment.bottomRight, ext),
            ]),
          ),
          const SizedBox(height: 40),
          Text(tag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 2, color: accentColor)),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2, color: ext.fg)),
          const SizedBox(height: 12),
          Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: ext.fgMuted, height: 1.6)),
        ],
      ),
    );
  }

  Widget _card((String, String, Color?) c, Alignment align, AppThemeExtension ext) {
    return Align(alignment: align, child: Container(
      margin: const EdgeInsets.all(20), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(c.$1, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.$3 ?? ext.fg)),
        Text(c.$2, style: TextStyle(fontSize: 10, color: ext.fgMuted, letterSpacing: 0.5)),
      ]),
    ));
  }
}
