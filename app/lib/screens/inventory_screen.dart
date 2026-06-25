import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _chipIdx = 0;
  final _products = const [
    ('🧂', 'Tata Salt 500g', '8901030874628', 22, 3, 0.12, BadgeVariant.red, '3 left'),
    ('🛢️', 'Fortune Sunflower Oil 1L', '8906002480012', 145, 24, 0.60, BadgeVariant.green, '24 left'),
    ('🍚', 'India Gate Basmati 1kg', '8901719110023', 120, 8, 0.35, BadgeVariant.warn, '8 left'),
    ('🧴', 'Dove Soap 100g', '8901058851019', 48, 32, 0.80, BadgeVariant.green, '32 left'),
    ('🥤', 'Coca-Cola 600ml', '8901030874635', 40, 0, 0.0, BadgeVariant.red, 'Out'),
    ('🍜', 'Maggi Noodles 70g', '8901491503009', 14, 56, 0.90, BadgeVariant.green, '56 left'),
  ];

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Stack(children: [
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppSearchBar(hint: 'Search items or scan barcode…', trailing: Icon(Icons.qr_code_scanner, size: 18, color: AppColors.accent)),
          ChipRow(labels: const ['All', 'Grocery', 'Beverages', 'Snacks', 'Personal Care'], selected: _chipIdx, onSelected: (i) => setState(() => _chipIdx = i)),
          const SizedBox(height: 8),
          // Stock summary
          Row(children: [
            _pill(ext, '342', 'Total Items', null),
            const SizedBox(width: 8),
            _pill(ext, '5', 'Low Stock', AppColors.warn),
            const SizedBox(width: 8),
            _pill(ext, '2', 'Out of Stock', AppColors.danger),
          ]),
          const SizedBox(height: 14),
          const AlertBanner(text: 'Tata Salt (500g) — only 3 units left'),
          const SectionLabel('All Products'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
            child: Column(children: _products.map((p) => _item(ext, p)).toList()),
          ),
          const SizedBox(height: 80),
        ]),
      ),
      // FAB
      Positioned(bottom: 16, right: 16, child: FloatingActionButton(
        backgroundColor: AppColors.accentDk, foregroundColor: Colors.white,
        onPressed: () => Navigator.pushNamed(context, '/add-product'),
        child: const Icon(Icons.add, size: 24),
      )),
    ]);
  }

  Widget _pill(AppThemeExtension ext, String val, String lbl, Color? color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
      child: Column(children: [
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color ?? ext.fg)),
        const SizedBox(height: 2),
        Text(lbl.toUpperCase(), style: TextStyle(fontSize: 10, color: ext.fgMuted, letterSpacing: 0.5)),
      ]),
    ));
  }

  Widget _item(AppThemeExtension ext, (String, String, String, int, int, double, BadgeVariant, String) p) {
    Color barColor;
    if (p.$6 < 0.2) barColor = AppColors.danger;
    else if (p.$6 < 0.5) barColor = AppColors.warn;
    else barColor = AppColors.accentDk;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ext.border.withValues(alpha: 0.5)))),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: ext.surface2, borderRadius: BorderRadius.circular(6)),
          child: Center(child: Text(p.$1, style: const TextStyle(fontSize: 18)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.$2, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ext.fg)),
          Text('Barcode: ${p.$3}', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: p.$6, minHeight: 4, backgroundColor: ext.surface2, valueColor: AlwaysStoppedAnimation(barColor))),
        ])),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹${p.$4}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ext.fg)),
          const SizedBox(height: 2),
          AppBadge(label: p.$8, variant: p.$7),
        ]),
      ]),
    );
  }
}
