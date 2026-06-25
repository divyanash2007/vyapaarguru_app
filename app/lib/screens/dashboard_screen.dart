import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(TextSpan(text: 'Namaste, ', style: TextStyle(fontSize: 13, color: ext.fgMuted), children: [TextSpan(text: 'Ramesh Ji', style: TextStyle(fontWeight: FontWeight.w600, color: ext.fg)), const TextSpan(text: ' 👋')])),
                const SizedBox(height: 2),
                Text.rich(TextSpan(text: 'Ramesh ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ext.fg), children: const [TextSpan(text: 'Kirana', style: TextStyle(color: AppColors.accent))])),
              ])),
              Stack(children: [
                Icon(Icons.notifications_outlined, size: 24, color: ext.fg),
                Positioned(top: -2, right: -2, child: Container(width: 16, height: 16, decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                  child: const Center(child: Text('3', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))))),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          // Low stock alert
          const AlertBanner(text: '5 items low on stock — reorder now'),
          // Today's summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Today\'s Sales', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                  Text('₹4,280', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ext.fg)),
                  const SizedBox(height: 4),
                  const Text('↑ 12% vs yesterday', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Orders', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                  Text('23', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ext.fg)),
                  const SizedBox(height: 4),
                  Text('Bills generated', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                ]),
              ]),
              const SizedBox(height: 10),
              SizedBox(height: 40, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (final h in [0.3, 0.5, 0.4, 0.7, 0.55, 0.8, 1.0])
                  Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 2), height: 40 * h, decoration: BoxDecoration(color: h == 1.0 ? AppColors.accentDk : ext.surface2, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))))),
              ])),
            ]),
          ),
          const SizedBox(height: 16),
          // Stat grid
          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.3, children: const [
            StatCard(value: '₹1,24,500', label: 'Monthly Revenue', delta: '↑ 8.3%'),
            StatCard(value: '342', label: 'Items in Stock', delta: '5 low', deltaColor: AppColors.warn),
            StatCard(value: '₹18,200', label: 'Pending Payments', delta: '3 overdue', deltaColor: AppColors.danger),
            StatCard(value: '12', label: 'Dealer Orders', delta: 'This month'),
          ]),
          const SizedBox(height: 16),
          // Quick Actions
          Text('Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ext.fg)),
          const SizedBox(height: 10),
          Row(children: [
            _qaBtn(context, Icons.computer, 'New Bill', '/billing'),
            _qaBtn(context, Icons.shopping_bag_outlined, 'Order Stock', '/dealer'),
            _qaBtn(context, Icons.add, 'Add Item', '/add-product'),
            _qaBtn(context, Icons.access_time, 'AI Tips', '/ai'),
          ]),
          const SizedBox(height: 16),
          // Recent transactions
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Recent Transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ext.fg)),
            GestureDetector(onTap: () => Navigator.pushNamed(context, '/orders'), child: const Text('See all', style: TextStyle(fontSize: 12, color: AppColors.accent))),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
            child: Column(children: [
              _txRow(ext, 'Priya Sharma', '2 min ago · Bill #1042', '+₹340', true),
              _txRow(ext, 'Sharma Traders (Dealer)', '1 hr ago · Order #D-88', '-₹4,200', false),
              _txRow(ext, 'Walk-in Customer', '2 hr ago · Bill #1041', '+₹185', true),
              _txRow(ext, 'Mohan Lal', '3 hr ago · Bill #1040', '+₹620', true, last: true),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _qaBtn(BuildContext ctx, IconData icon, String label, String route) {
    final ext = ctx.appTheme;
    return Expanded(child: GestureDetector(
      onTap: () => Navigator.pushNamed(ctx, route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
        child: Column(children: [Icon(icon, size: 22, color: ext.fg), const SizedBox(height: 6), Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: ext.fgMuted), textAlign: TextAlign.center)]),
      ),
    ));
  }

  Widget _txRow(AppThemeExtension ext, String name, String sub, String amt, bool isSale, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: ext.border))),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isSale ? AppColors.accent : AppColors.blue)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ext.fg)),
          Text(sub, style: TextStyle(fontSize: 11, color: ext.fgMuted)),
        ])),
        Text(amt, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isSale ? AppColors.accent : AppColors.danger)),
      ]),
    );
  }
}
