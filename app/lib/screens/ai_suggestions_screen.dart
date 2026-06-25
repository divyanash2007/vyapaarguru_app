import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class AiSuggestionsScreen extends StatefulWidget {
  const AiSuggestionsScreen({super.key});
  @override
  State<AiSuggestionsScreen> createState() => _AiSuggestionsScreenState();
}

class _AiSuggestionsScreenState extends State<AiSuggestionsScreen> {
  int _chip = 0;

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('AI Suggestions'), actions: [
        Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 16), decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent)),
      ]),
      body: SafeArea(
        top: false,
        child: Column(children: [
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // AI header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(colors: [ext.surface, AppColors.accent.withValues(alpha: 0.15)]),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withValues(alpha: 0.12)),
                  child: const Icon(Icons.auto_awesome, size: 26, color: AppColors.accent)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('DukaanAI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ext.fg)),
                    Text('Analysed your last 30 days · 6 insights ready', style: TextStyle(fontSize: 12, color: ext.fgMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            ChipRow(labels: const ['All', 'Restock', 'Pricing', 'Trends', 'Savings'], selected: _chip, onSelected: (i) => setState(() => _chip = i)),
            const SizedBox(height: 8),
            // Suggestion cards
            _suggestion(ext, '🔴 Urgent · Restock', 'Reorder Tata Salt & Coca-Cola now', 'These 2 items are out of stock or critically low. Based on your sales pattern, you sell ~8 units/day. You\'ll lose ₹320/day in revenue if not restocked.', 'Order Now', '/dealer'),
            _suggestion(ext, '💰 Pricing · Opportunity', 'Raise Fortune Oil price by ₹5', 'Nearby shops sell Fortune Oil at ₹150. Your price is ₹145. Raising to ₹150 could add ₹750/month in profit with no impact on demand.', 'Apply Price', null),
            _suggestion(ext, '📈 Trend · Seasonal', 'Stock up on cold drinks before summer', 'May–June sees 3× higher beverage sales. Last year you ran out of Coca-Cola and Limca in week 2. Order 2× your usual quantity this week.', 'Plan Order', '/dealer'),
            _suggestion(ext, '💡 Savings · Bulk Buy', 'Buy Maggi in bulk — save ₹1.50/pack', 'Sharma Traders offers ₹12.50/pack for orders of 100+. You sell 56 packs/week. Buying 200 packs saves ₹300 and covers 3.5 weeks.', 'Add to Order', null),
            const SectionLabel('Quick Insights'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
              child: Column(children: [
                _insight(ext, Icons.trending_up, AppColors.accent, 'Saturday is your best day — 40% more sales'),
                _insight(ext, Icons.access_time, AppColors.blue, 'Peak hours: 8–10 AM and 5–7 PM'),
                _insight(ext, Icons.people_outline, AppColors.warn, '12 repeat customers this week', last: true),
              ]),
            ),
          ]),
        )),
        // Chat input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: ext.surface, border: Border(top: BorderSide(color: ext.border))),
          child: Row(children: [
            Expanded(child: TextField(
              style: TextStyle(fontSize: 14, color: ext.fg),
              decoration: InputDecoration(hintText: 'Ask DukaanAI anything…', hintStyle: TextStyle(color: ext.fgMuted), filled: true, fillColor: ext.surface2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide(color: ext.border)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
            )),
            const SizedBox(width: 8),
            Container(width: 40, height: 40, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accentDk),
              child: const Icon(Icons.send, size: 18, color: Colors.white)),
          ]),
        ),
      ])),
    );
  }

  Widget _suggestion(AppThemeExtension ext, String tag, String title, String body, String action, String? route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: [ext.surface, AppColors.accent.withValues(alpha: 0.12)]),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tag.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 2, color: AppColors.accent)),
        const SizedBox(height: 6),
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ext.fg)),
        const SizedBox(height: 6),
        Text(body, style: TextStyle(fontSize: 13, color: ext.fgMuted, height: 1.5)),
        const SizedBox(height: 12),
        Row(children: [
          AppButton(label: action, small: true, onPressed: () { if (route != null) Navigator.pushNamed(context, route); }),
          const SizedBox(width: 8),
          AppButton(label: 'Dismiss', small: true, outline: true, primary: false),
        ]),
      ]),
    );
  }

  Widget _insight(AppThemeExtension ext, IconData icon, Color color, String text, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: ext.border))),
      child: Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 16, color: color)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: ext.fg))),
      ]),
    );
  }
}
