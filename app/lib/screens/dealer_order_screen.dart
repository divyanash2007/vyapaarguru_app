import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/services/api_service.dart';
import '../widgets/shared_widgets.dart';

class DealerOrderScreen extends StatefulWidget {
  const DealerOrderScreen({super.key});
  @override
  State<DealerOrderScreen> createState() => _DealerOrderScreenState();
}

class _DealerOrderScreenState extends State<DealerOrderScreen> {
  final _api = ApiService.instance;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _selectedDealer = 0;

  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _orderItems = []; // {product_id, name, cost_price, stock, qty}

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.get('/suppliers/'),
        _api.get('/inventory/low-stock'),
      ]);

      final suppliers = (results[0] as List<dynamic>).cast<Map<String, dynamic>>();
      final lowStock = (results[1] as List<dynamic>).cast<Map<String, dynamic>>();

      // Build order items from low-stock inventory
      final items = lowStock.map((inv) {
        final product = inv['product'] as Map<String, dynamic>? ?? {};
        return {
          'product_id': inv['product_id'],
          'name': product['name'] ?? 'Unknown',
          'cost_price': double.tryParse(inv['cost_price']?.toString() ?? '0') ?? 0.0,
          'stock': inv['qty'] ?? 0,
          'qty': inv['reorder_level'] ?? 10,
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _suppliers = suppliers;
        _orderItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  double get _total => _orderItems.fold(0.0, (s, i) => s + (i['cost_price'] as double) * (i['qty'] as int));

  Future<void> _submitOrder() async {
    if (_suppliers.isEmpty || _orderItems.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final supplierId = _suppliers[_selectedDealer]['id'];
      await _api.post('/purchases/', body: {
        'supplier_id': supplierId,
        'items': _orderItems.map((i) => {
          'product_id': i['product_id'],
          'qty': i['qty'],
          'cost_price': i['cost_price'],
        }).toList(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order sent to dealer!'), backgroundColor: AppColors.accent),
      );
      Navigator.pop(context);
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
        const SnackBar(content: Text('Failed to submit order'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton(), title: const Text('Order to Dealer')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Order to Dealer'), actions: [
        Padding(padding: const EdgeInsets.only(right: 16), child: AppBadge(label: '${_orderItems.length} items', variant: BadgeVariant.blue)),
      ]),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionLabel('Select Dealer'),
            if (_suppliers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No suppliers registered yet', style: TextStyle(fontSize: 14, color: ext.fgMuted))),
              )
            else
              ..._suppliers.asMap().entries.map((e) {
                final supplier = e.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDealer = e.key),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: e.key == _selectedDealer ? AppColors.accent.withValues(alpha: 0.05) : ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: e.key == _selectedDealer ? AppColors.accent : ext.border)),
                    child: Row(children: [
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: ext.surface2, shape: BoxShape.circle), child: Center(child: Text('🏪', style: const TextStyle(fontSize: 18)))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(supplier['name'] ?? 'Supplier', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ext.fg)),
                        Text(supplier['phone'] ?? supplier['address'] ?? '', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                      ])),
                      if (e.key == _selectedDealer) const Icon(Icons.check, size: 18, color: AppColors.accent),
                    ]),
                  ),
                );
              }),
            Divider(color: ext.border),
            const SizedBox(height: 8),
            const SectionLabel('Add Items'),
            if (_orderItems.isNotEmpty)
              const AlertBanner(text: 'Items need restocking — added below'),
            if (_orderItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('All items are well-stocked!', style: TextStyle(fontSize: 14, color: ext.fgMuted))),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
                child: Column(children: _orderItems.asMap().entries.map((e) {
                  final item = e.value;
                  final isLast = e.key == _orderItems.length - 1;
                  final stock = item['stock'] as int;
                  final costPrice = (item['cost_price'] as double).toStringAsFixed(0);
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: ext.border))),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item['name'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ext.fg)),
                        Text('₹$costPrice/unit · ${stock == 0 ? 'Out of stock' : 'Current stock: $stock'}', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                      ])),
                      QtyStepperWidget(value: item['qty'] as int, onChanged: (v) => setState(() => item['qty'] = v.clamp(1, 999))),
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
                BillLine(label: 'Items', value: '${_orderItems.length} items'),
                BillLine(label: 'Subtotal', value: '₹${_total.toStringAsFixed(0)}'),
                BillLine(label: 'Total', value: '₹${_total.toStringAsFixed(0)}', isTotal: true),
              ]),
            ),
            const SizedBox(height: 14),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : AppButton(label: 'Send Order to Dealer', full: true, icon: const Icon(Icons.send, size: 16, color: Colors.white), onPressed: _submitOrder),
          ]),
        ),
      ),
    );
  }
}
