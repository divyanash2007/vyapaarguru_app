import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class _BillItem { String code, name; int price, qty;
  _BillItem(this.code, this.name, this.price, this.qty);
}

class PosBillingScreen extends StatefulWidget {
  const PosBillingScreen({super.key});
  @override
  State<PosBillingScreen> createState() => _PosBillingScreenState();
}

class _PosBillingScreenState extends State<PosBillingScreen> {
  final _items = <_BillItem>[
    _BillItem('1', 'Tata Salt 500g', 22, 1),
    _BillItem('2', 'Fortune Sunflower Oil 1L', 145, 1),
    _BillItem('3', 'Maggi Noodles 70g', 14, 1),
  ];
  int _discount = 0;

  int get _sub => _items.fold(0, (s, i) => s + i.price * i.qty);
  int get _gst => (_sub * 0.05).round();
  int get _total => _sub + _gst - _discount;

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Column(children: [
      // Customer row
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: ext.surface, 
        child: Row(children: [
          Text('Customer:', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
          const SizedBox(width: 8),
          Expanded(child: TextField(
            style: TextStyle(fontSize: 13, color: ext.fg),
            decoration: InputDecoration(hintText: 'Name or phone (optional)', hintStyle: TextStyle(color: ext.fgMuted), filled: true, fillColor: ext.surface2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: ext.border)), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7)),
          )),
        ]),
      ),
      // Scan strip
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: ext.surface, border: Border(bottom: BorderSide(color: ext.border))),
        child: Row(children: [
          Expanded(child: TextField(
            style: TextStyle(fontSize: 14, color: ext.fg),
            decoration: InputDecoration(hintText: 'Search item or scan barcode…', hintStyle: TextStyle(color: ext.fgMuted), filled: true, fillColor: ext.surface2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: ext.border)), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9)),
          )),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: AppColors.accentDk, borderRadius: BorderRadius.circular(6)),
            child: Row(children: const [Icon(Icons.qr_code_scanner, size: 16, color: Colors.white), SizedBox(width: 6), Text('Scan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))]),
          ),
        ]),
      ),
      // Bill items
      Expanded(
        child: _items.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.computer, size: 48, color: ext.fgMuted.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text('Scan or search items\nto start billing', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: ext.fgMuted)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final item = _items[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(border: i < _items.length - 1 ? Border(bottom: BorderSide(color: ext.border)) : null),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ext.fg)),
                        Text('₹${item.price} × ${item.qty}', style: TextStyle(fontSize: 13, color: ext.fgMuted)),
                      ])),
                      QtyStepperWidget(value: item.qty, scale: 0.85, onChanged: (v) => setState(() => item.qty = v.clamp(1, 999))),
                      const SizedBox(width: 8),
                      SizedBox(width: 52, child: Text('₹${item.price * item.qty}', textAlign: TextAlign.right, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ext.fg))),
                      const SizedBox(width: 4),
                      GestureDetector(onTap: () => setState(() => _items.removeAt(i)), child: Icon(Icons.delete_outline, size: 14, color: AppColors.danger)),
                    ]),
                  );
                },
              ),
      ),
      // Checkout panel
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: ext.surface, border: Border(top: BorderSide(color: ext.border))),
        child: Column(children: [
          _row(ext, 'Subtotal', '₹$_sub'),
          _row(ext, 'GST (5%)', '₹$_gst'),
          _row(ext, 'Discount', '-₹$_discount'),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: ext.border))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ext.fg)),
              Text('₹$_total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent)),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: AppButton(label: 'Send Bill', outline: true, primary: false, onPressed: () => Navigator.pushNamed(context, '/send-bill'), icon: Icon(Icons.send, size: 14, color: ext.fg))),
            const SizedBox(width: 8),
            Expanded(child: AppButton(label: 'Collect ₹$_total', onPressed: () => Navigator.pushNamed(context, '/send-bill'), icon: const Icon(Icons.credit_card, size: 14, color: Colors.white))),
          ]),
        ]),
      ),
    ]);
  }

  Widget _row(AppThemeExtension ext, String l, String r) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: TextStyle(fontSize: 13, color: ext.fgMuted)),
      Text(r, style: TextStyle(fontSize: 13, color: ext.fg)),
    ]));
  }
}
