import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class DealerOrderScreen extends StatefulWidget {
  const DealerOrderScreen({super.key});
  @override
  State<DealerOrderScreen> createState() => _DealerOrderScreenState();
}

class _DealerOrderScreenState extends State<DealerOrderScreen> {
  int _dealer = 0;
  final _items = [
    {'name': 'Tata Salt 500g', 'price': 18, 'stock': 3, 'qty': 12},
    {'name': 'India Gate Basmati 1kg', 'price': 105, 'stock': 8, 'qty': 10},
    {'name': 'Coca-Cola 600ml', 'price': 32, 'stock': 0, 'qty': 24},
  ];

  int get _total => _items.fold(0, (s, i) => s + (i['price'] as int) * (i['qty'] as int));

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Order to Dealer'), actions: [
        Padding(padding: const EdgeInsets.only(right: 16), child: AppBadge(label: '${_items.length} items', variant: BadgeVariant.blue)),
      ]),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionLabel('Select Dealer'),
            ...[('🏪', 'Sharma Traders', 'Grocery & FMCG · Last order 3 days ago'), ('🏬', 'Gupta Wholesale', 'Beverages & Snacks · Last order 1 week ago')].asMap().entries.map((e) {
              return GestureDetector(
                onTap: () => setState(() => _dealer = e.key),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: e.key == _dealer ? AppColors.accent.withValues(alpha: 0.05) : ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: e.key == _dealer ? AppColors.accent : ext.border)),
                  child: Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: ext.surface2, shape: BoxShape.circle), child: Center(child: Text(e.value.$1, style: const TextStyle(fontSize: 18)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.value.$2, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ext.fg)),
                      Text(e.value.$3, style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                    ])),
                    if (e.key == _dealer) const Icon(Icons.check, size: 18, color: AppColors.accent),
                  ]),
                ),
              );
            }),
            Divider(color: ext.border),
            const SizedBox(height: 8),
            const SectionLabel('Add Items'),
            const AlertBanner(text: '3 items need restocking — added below'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
              child: Column(children: _items.asMap().entries.map((e) {
                final item = e.value;
                final isLast = e.key == _items.length - 1;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: ext.border))),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item['name'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ext.fg)),
                      Text('₹${item['price']}/unit · ${(item['stock'] as int) == 0 ? 'Out of stock' : 'Current stock: ${item['stock']}'}', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                    ])),
                    QtyStepperWidget(value: item['qty'] as int, onChanged: (v) => setState(() => item['qty'] = v)),
                  ]),
                );
              }).toList()),
            ),
            const SizedBox(height: 14),
            // Order summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
              child: Column(children: [
                BillLine(label: 'Items', value: '${_items.length} items'),
                BillLine(label: 'Subtotal', value: '₹$_total'),
                BillLine(label: 'Expected delivery', value: 'Tomorrow, 10 AM'),
                BillLine(label: 'Total', value: '₹$_total', isTotal: true),
              ]),
            ),
            const SizedBox(height: 14),
            AppButton(label: 'Send Order to Dealer', full: true, icon: const Icon(Icons.send, size: 16, color: Colors.white), onPressed: () => Navigator.pop(context)),
          ]),
        ),
      ),
    );
  }
}
