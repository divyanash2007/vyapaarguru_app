import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/services/api_service.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/add_supplier_bottom_sheet.dart';
import '../widgets/barcode_scanner_widget.dart';

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

  // Search variables
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
          'qty': inv['reorder_level'] != null && inv['reorder_level'] > 0 ? inv['reorder_level'] : 10,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load dealer data'), backgroundColor: AppColors.danger),
      );
    }
  }

  double get _subtotal => _orderItems.fold(0.0, (s, i) => s + (i['cost_price'] as double) * (i['qty'] as int));

  Future<void> _addSupplierInline() async {
    final result = await AddSupplierBottomSheet.show(context);
    if (result != null) {
      // Reload suppliers and auto-select the newly added one
      try {
        final data = await _api.get('/suppliers/');
        final suppliers = (data as List<dynamic>).cast<Map<String, dynamic>>();
        
        int newIndex = 0;
        for (int i = 0; i < suppliers.length; i++) {
          if (suppliers[i]['id'] == result['id']) {
            newIndex = i;
            break;
          }
        }

        setState(() {
          _suppliers = suppliers;
          _selectedDealer = newIndex;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Supplier "${result['name']}" added & selected!'), backgroundColor: AppColors.success),
        );
      } catch (_) {}
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final data = await _api.get('/inventory/', queryParams: {'search': query, 'per_page': '10'});
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

  void _addItemToOrder(Map<String, dynamic> invItem) {
    final p = invItem['product'] as Map<String, dynamic>? ?? {};
    final productId = invItem['product_id'] as int;

    // Check if product is already in the order list
    final existing = _orderItems.where((i) => i['product_id'] == productId).toList();
    if (existing.isNotEmpty) {
      setState(() {
        existing.first['qty']++;
        _searchCtrl.clear();
        _searchResults = [];
      });
      return;
    }

    final costPrice = double.tryParse(invItem['cost_price']?.toString() ?? '0') ?? 0.0;
    final stock = invItem['qty'] as int? ?? 0;

    setState(() {
      _orderItems.add({
        'product_id': productId,
        'name': p['name'] ?? 'Unknown Product',
        'cost_price': costPrice,
        'stock': stock,
        'qty': invItem['reorder_level'] != null && invItem['reorder_level'] > 0 ? invItem['reorder_level'] : 10,
      });
      _searchCtrl.clear();
      _searchResults = [];
    });
  }

  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerWidget.scan(context);
    if (barcode == null || barcode.isEmpty) return;

    try {
      // Find product by barcode
      final product = await _api.get('/products/barcode/$barcode');
      final productId = product['id'] as int;

      // Fetch its inventory entry
      final invItem = await _api.get('/inventory/$productId');
      _addItemToOrder(invItem);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product with barcode "$barcode" not found in inventory'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _submitOrder() async {
    if (_suppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or add a supplier first'), backgroundColor: AppColors.danger),
      );
      return;
    }
    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to order'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final supplier = _suppliers[_selectedDealer];
      final supplierId = supplier['id'];
      final supplierPhone = supplier['phone']?.toString() ?? '';
      
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
        const SnackBar(content: Text('Order sent to dealer successfully!'), backgroundColor: AppColors.success),
      );

      if (supplierPhone.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln('*Purchase Order*');
        buffer.writeln('Supplier: ${supplier['name']}');
        buffer.writeln('Expected Delivery: Tomorrow, 10 AM');
        buffer.writeln('--------------------------------');
        for (final item in _orderItems) {
          buffer.writeln('${item['name']} x${item['qty']}');
        }
        buffer.writeln('--------------------------------');
        buffer.writeln('*Total Estimated: ₹${_subtotal.toStringAsFixed(0)}*');
        buffer.writeln('Please confirm and prepare this order. Thank you!');

        final phoneDigits = supplierPhone.replaceAll(RegExp(r'\D'), '');
        final finalPhone = phoneDigits.length == 10 ? '91$phoneDigits' : phoneDigits;

        final url = Uri.parse('https://wa.me/$finalPhone?text=${Uri.encodeComponent(buffer.toString())}');
        final fallbackUrl = Uri.parse('whatsapp://send?phone=$finalPhone&text=${Uri.encodeComponent(buffer.toString())}');

        try {
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else if (await canLaunchUrl(fallbackUrl)) {
            await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
          } else {
            // Direct launch bypass for package visibility constraints
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not launch WhatsApp: $e'), backgroundColor: AppColors.danger),
            );
          }
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
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

  IconData _getProductIcon(String name) {
    final l = name.toLowerCase();
    if (l.contains('salt')) return Icons.kitchen;
    if (l.contains('rice') || l.contains('basmati')) return Icons.grass;
    if (l.contains('cola') || l.contains('drink') || l.contains('beverage')) return Icons.local_drink;
    if (l.contains('oil')) return Icons.opacity;
    return Icons.shopping_bag_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: ext.bg,
        appBar: AppBar(leading: const BackButton(), title: const Text('Order to Dealer')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return Scaffold(
      backgroundColor: ext.bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Order to Dealer'),
        actions: [
          if (_orderItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: AppBadge(
                  label: '${_orderItems.length} items',
                  variant: BadgeVariant.blue,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SELECT DEALER SECTION ---
                    const SectionLabel('Select Dealer'),
                    if (_suppliers.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ext.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ext.border),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'No registered dealers found',
                              style: TextStyle(fontSize: 13, color: ext.fgMuted),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _addSupplierInline,
                              icon: const Icon(Icons.add, size: 16, color: AppColors.accent),
                              label: const Text('Add Dealer', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      ..._suppliers.asMap().entries.map((e) {
                        final idx = e.key;
                        final supplier = e.value;
                        final isSelected = idx == _selectedDealer;
                        final name = supplier['name'] ?? 'Supplier';
                        final address = supplier['address'] ?? 'No address registered';

                        return GestureDetector(
                          onTap: () => setState(() => _selectedDealer = idx),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.accent.withValues(alpha: 0.05) : ext.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppColors.accent : ext.border,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Dealer Icon
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: ext.surface2,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text('🏬', style: TextStyle(fontSize: 16)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: ext.fg,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: ext.fgMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check, color: AppColors.accent, size: 18),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _addSupplierInline,
                          icon: const Icon(Icons.add, size: 16, color: AppColors.accent),
                          label: const Text(
                            'Add New Dealer',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Divider(color: ext.border.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),

                    // --- ADD ITEMS SECTION ---
                    const SectionLabel('Add Items'),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: ext.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: ext.border),
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: _searchProducts,
                              style: TextStyle(fontSize: 13, color: ext.fg),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                hintText: 'Search or type item name...',
                                hintStyle: TextStyle(color: ext.fgMuted.withValues(alpha: 0.6), fontSize: 13),
                                border: InputBorder.none,
                                isDense: true,
                                suffixIcon: _isSearching
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _scanBarcode,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: ext.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: ext.border),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner,
                              color: AppColors.accent,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Dropdown Overlay for Search results
                    if (_searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          color: ext.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ext.border),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, idx) {
                            final invItem = _searchResults[idx];
                            final p = invItem['product'] as Map<String, dynamic>? ?? {};
                            final name = p['name'] ?? '';
                            final costPrice = invItem['cost_price'] ?? p['mrp'] ?? 0.0;
                            final stock = invItem['qty'] ?? 0;

                            return ListTile(
                              dense: true,
                              title: Text(name, style: TextStyle(fontSize: 13, color: ext.fg, fontWeight: FontWeight.w500)),
                              subtitle: Text('Stock: $stock · Cost: ₹$costPrice', style: TextStyle(fontSize: 11, color: ext.fgMuted)),
                              trailing: const Icon(Icons.add, size: 16, color: AppColors.accent),
                              onTap: () => _addItemToOrder(invItem),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 14),

                    // Low-stock alert banner
                    if (_orderItems.isNotEmpty)
                      const AlertBanner(
                        text: 'Items need restocking — added below',
                      ),

                    // Order items list
                    if (_orderItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Search or scan items to add them here',
                            style: TextStyle(fontSize: 13, color: ext.fgMuted),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: ext.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ext.border),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _orderItems.length,
                          separatorBuilder: (_, index) => Divider(color: ext.border.withValues(alpha: 0.5), height: 1),
                          itemBuilder: (context, idx) {
                            final item = _orderItems[idx];
                            final name = item['name'] as String;
                            final costPrice = (item['cost_price'] as double).toStringAsFixed(0);
                            final stock = item['stock'] as int;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  // Product thumbnail icon
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: ext.surface2,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getProductIcon(name),
                                      color: AppColors.accent,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Item Name and Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: ext.fg,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₹$costPrice/unit · ${stock == 0 ? 'Out of stock' : 'Current stock: $stock'}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: ext.fgMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Stepper
                                  QtyStepperWidget(
                                    value: item['qty'] as int,
                                    onChanged: (v) {
                                      setState(() {
                                        if (v <= 0) {
                                          _orderItems.removeAt(idx);
                                        } else {
                                          item['qty'] = v;
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // --- BOTTOM SUMMARY & SUBMIT BUTTON (Pinned) ---
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: ext.surface,
                border: Border(
                  top: BorderSide(color: ext.border.withValues(alpha: 0.3)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items',
                        style: TextStyle(fontSize: 13, color: ext.fgMuted),
                      ),
                      Text(
                        '${_orderItems.length} items',
                        style: TextStyle(fontSize: 13, color: ext.fg),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(fontSize: 13, color: ext.fgMuted),
                      ),
                      Text(
                        '₹${_subtotal.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 13, color: ext.fg),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Expected delivery',
                        style: TextStyle(fontSize: 13, color: ext.fgMuted),
                      ),
                      Text(
                        'Tomorrow, 10 AM',
                        style: TextStyle(fontSize: 13, color: ext.fg),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ext.fg),
                      ),
                      Text(
                        '₹${_subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _isSubmitting
                      ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                      : AppButton(
                          label: 'Send Order to Dealer',
                          full: true,
                          icon: const Icon(Icons.send, size: 16, color: Colors.white),
                          onPressed: _submitOrder,
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
