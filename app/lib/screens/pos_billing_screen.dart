import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/services/api_service.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/barcode_scanner_widget.dart';

class _BillItem {
  int productId;
  String name;
  double sellingPrice;
  double tax;
  int qty;

  _BillItem({required this.productId, required this.name, required this.sellingPrice, this.tax = 0, required this.qty});
}

class PosBillingScreen extends StatefulWidget {
  const PosBillingScreen({super.key});
  @override
  State<PosBillingScreen> createState() => _PosBillingScreenState();
}

class _PosBillingScreenState extends State<PosBillingScreen> {
  final _api = ApiService.instance;
  final _items = <_BillItem>[];
  final _searchCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final int _discount = 0;
  bool _isSearching = false;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _searchResults = [];
  int? _selectedCustomerId;

  double get _sub => _items.fold(0.0, (s, i) => s + i.sellingPrice * i.qty);
  double get _gst => _items.fold(0.0, (s, i) => s + (i.sellingPrice * i.qty * i.tax / 100));
  double get _total => _sub + _gst - _discount;

  Future<void> _searchProducts(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final data = await _api.get('/products/', queryParams: {'search': query, 'per_page': '10'});
      if (!mounted) return;
      setState(() {
        _searchResults = (data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  Future<void> _addProductToBill(Map<String, dynamic> product) async {
    final productId = product['id'] as int;

    // Check if already in bill
    final existing = _items.where((i) => i.productId == productId).toList();
    if (existing.isNotEmpty) {
      setState(() => existing.first.qty++);
      _searchCtrl.clear();
      _searchResults = [];
      return;
    }

    // Fetch inventory for selling price
    try {
      final inv = await _api.get('/inventory/$productId');
      final sellingPrice = double.tryParse(inv['selling_price'].toString()) ?? double.tryParse(product['mrp'].toString()) ?? 0.0;
      final tax = double.tryParse(product['tax']?.toString() ?? '0') ?? 0.0;

      if (!mounted) return;
      setState(() {
        _items.add(_BillItem(
          productId: productId,
          name: product['name'] ?? 'Unknown',
          sellingPrice: sellingPrice,
          tax: tax,
          qty: 1,
        ));
        _searchCtrl.clear();
        _searchResults = [];
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _checkout(String paymentMethod) async {
    if (_items.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final saleData = await _api.post('/sales/', body: {
        if (_selectedCustomerId != null) 'customer_id': _selectedCustomerId,
        'discount': _discount,
        'tax': _gst,
        'payment_method': paymentMethod,
        'items': _items.map((i) => {
          'product_id': i.productId,
          'qty': i.qty,
          'discount': 0,
          'tax': i.tax,
        }).toList(),
        'payments': [
          {'amount': _total, 'method': paymentMethod},
        ],
      });

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Navigate to send bill with sale data
      Navigator.pushNamed(context, '/send-bill', arguments: saleData);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create sale. Check your connection.'), backgroundColor: AppColors.danger),
      );
    }
  }

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
            controller: _customerCtrl,
            style: TextStyle(fontSize: 13, color: ext.fg),
            decoration: InputDecoration(hintText: 'Name or phone (optional)', hintStyle: TextStyle(color: ext.fgMuted), filled: true, fillColor: ext.surface2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: ext.border)), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7)),
            onChanged: (v) async {
              if (v.length >= 3) {
                try {
                  final customers = await _api.get('/customers/', queryParams: {'search': v});
                  if (customers is List && customers.isNotEmpty) {
                    _selectedCustomerId = customers.first['id'];
                  } else {
                    _selectedCustomerId = null;
                  }
                } catch (_) {}
              }
            },
          )),
        ]),
      ),
      // Scan strip
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: ext.surface, border: Border(bottom: BorderSide(color: ext.border))),
        child: Column(children: [
          Row(children: [
            Expanded(child: TextField(
              controller: _searchCtrl,
              style: TextStyle(fontSize: 14, color: ext.fg),
              decoration: InputDecoration(hintText: 'Search item or scan barcode…', hintStyle: TextStyle(color: ext.fgMuted), filled: true, fillColor: ext.surface2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: ext.border)), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9)),
              onChanged: _searchProducts,
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                final barcode = await BarcodeScannerWidget.scan(context);
                if (barcode != null && barcode.isNotEmpty) {
                  try {
                    final product = await _api.get('/products/barcode/$barcode');
                    _addProductToBill(product);
                  } on ApiException {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Product not found'), backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(color: AppColors.accentDk, borderRadius: BorderRadius.circular(6)),
                child: const Row(children: [Icon(Icons.qr_code_scanner, size: 16, color: Colors.white), SizedBox(width: 6), Text('Scan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white))]),
              ),
            ),
          ]),
          // Search results dropdown
          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: ext.border)),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (_, i) {
                  final p = _searchResults[i];
                  return ListTile(
                    dense: true,
                    title: Text(p['name'] ?? '', style: TextStyle(fontSize: 13, color: ext.fg)),
                    subtitle: Text('MRP: ₹${p['mrp']}', style: TextStyle(fontSize: 11, color: ext.fgMuted)),
                    onTap: () => _addProductToBill(p),
                  );
                },
              ),
            ),
          if (_isSearching)
            const Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))),
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
                        Text('₹${item.sellingPrice.toStringAsFixed(0)} × ${item.qty}', style: TextStyle(fontSize: 13, color: ext.fgMuted)),
                      ])),
                      QtyStepperWidget(value: item.qty, scale: 0.85, onChanged: (v) => setState(() => item.qty = v.clamp(1, 999))),
                      const SizedBox(width: 8),
                      SizedBox(width: 52, child: Text('₹${(item.sellingPrice * item.qty).toStringAsFixed(0)}', textAlign: TextAlign.right, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ext.fg))),
                      const SizedBox(width: 4),
                      GestureDetector(onTap: () => setState(() => _items.removeAt(i)), child: const Icon(Icons.delete_outline, size: 14, color: AppColors.danger)),
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
          _row(ext, 'Subtotal', '₹${_sub.toStringAsFixed(0)}'),
          _row(ext, 'GST', '₹${_gst.toStringAsFixed(0)}'),
          _row(ext, 'Discount', '-₹$_discount'),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: ext.border))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ext.fg)),
              Text('₹${_total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent)),
            ]),
          ),
          const SizedBox(height: 12),
          _isSubmitting
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : Row(children: [
                  Expanded(child: AppButton(label: 'Send Bill', outline: true, primary: false, onPressed: () => _checkout('cash'), icon: Icon(Icons.send, size: 14, color: ext.fg))),
                  const SizedBox(width: 8),
                  Expanded(child: AppButton(label: 'Collect ₹${_total.toStringAsFixed(0)}', onPressed: () => _checkout('cash'), icon: const Icon(Icons.credit_card, size: 14, color: Colors.white))),
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
