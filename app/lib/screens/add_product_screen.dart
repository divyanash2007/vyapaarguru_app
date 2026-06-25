import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Add Product')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Scan trigger
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: ext.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent, style: BorderStyle.none), // dashed not natively supported
                ),
                child: Row(children: [
                  Icon(Icons.qr_code_scanner, size: 28, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Scan Barcode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent)),
                    Text('Auto-fill product details from barcode', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                  ])),
                  Icon(Icons.chevron_right, size: 18, color: ext.fgMuted),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            const AppInput(label: 'Product Name', hint: 'e.g. Tata Salt 500g'),
            AppDropdown(label: 'Category', items: const ['Grocery', 'Beverages', 'Snacks', 'Personal Care', 'Dairy', 'Household']),
            Row(children: const [
              Expanded(child: AppInput(label: 'Purchase Price (₹)', hint: '0.00', keyboardType: TextInputType.number)),
              SizedBox(width: 10),
              Expanded(child: AppInput(label: 'Selling Price (₹)', hint: '0.00', keyboardType: TextInputType.number)),
            ]),
            const AppInput(label: 'Opening Stock (units)', hint: '0', keyboardType: TextInputType.number),
            const AppInput(label: 'Low Stock Alert (units)', hint: '5', keyboardType: TextInputType.number),
            AppDropdown(label: 'Unit', items: const ['Piece', 'Kg', 'Gram', 'Litre', 'Ml', 'Pack', 'Box']),
            // Photo upload
            Container(
              height: 80, width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border, style: BorderStyle.none)),
              child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.image_outlined, size: 20, color: ext.fgMuted),
                const SizedBox(width: 8),
                Text('Add Product Photo (optional)', style: TextStyle(fontSize: 13, color: ext.fgMuted)),
              ])),
            ),
            const SizedBox(height: 14),
            const AppInput(label: 'Notes', hint: 'Expiry date, supplier info, etc.', maxLines: 3),
            AppButton(label: 'Save Product', full: true, icon: const Icon(Icons.add, size: 16, color: Colors.white), onPressed: () => Navigator.pop(context)),
          ]),
        ),
      ),
    );
  }
}
