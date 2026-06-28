import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/services/api_service.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/barcode_scanner_widget.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _api = ApiService.instance;

  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController();
  final _sellingPriceCtrl = TextEditingController();
  final _openingStockCtrl = TextEditingController(text: '0');
  final _lowStockCtrl = TextEditingController(text: '5');
  final _notesCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedUnit;
  bool _isSubmitting = false;
  bool _isLookingUp = false;

  List<Map<String, dynamic>> _categories = [];

  String _getFormattedCategoryName(Map<String, dynamic> c) {
    final parentId = c['parent_id'] as int?;
    if (parentId != null) {
      final parent = _categories.firstWhere((cat) => cat['id'] == parentId, orElse: () => {});
      if (parent.isNotEmpty) {
        return '${parent['name']} > ${c['name']}';
      }
    }
    return c['name'] as String;
  }

  // If barcode lookup finds an existing product, store its ID
  int? _existingProductId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await _api.get('/categories/');
      if (!mounted) return;
      setState(() {
        _categories = (data as List<dynamic>).cast<Map<String, dynamic>>();
      });
    } catch (_) {}
  }

  Future<void> _showAddCategoryDialog() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Category'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Spices',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (name != null && name.isNotEmpty) {
      try {
        await _api.post('/categories/', body: {'name': name});
        await _loadCategories();
        setState(() {
          final matched = _categories.firstWhere(
            (c) => (c['name'] as String).toLowerCase() == name.toLowerCase() && c['parent_id'] == null,
            orElse: () => {},
          );
          _selectedCategory = matched.isNotEmpty ? _getFormattedCategoryName(matched) : name;
        });
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _lookupBarcode() async {
    if (_barcodeCtrl.text.isEmpty) return;

    setState(() => _isLookingUp = true);
    try {
      final product = await _api.get('/products/barcode/${_barcodeCtrl.text}');
      if (!mounted) return;
      setState(() {
        _existingProductId = product['id'];
        _nameCtrl.text = product['name'] ?? '';
        if (product['category'] != null) {
          final catId = product['category']['id'] as int?;
          if (catId != null) {
            final matched = _categories.firstWhere((c) => c['id'] == catId, orElse: () => {});
            if (matched.isNotEmpty) {
              _selectedCategory = _getFormattedCategoryName(matched);
            } else {
              _selectedCategory = product['category']['name'] as String?;
            }
          }
        }
        _sellingPriceCtrl.text = product['mrp']?.toString() ?? '';
        _selectedUnit = product['unit'];
        _isLookingUp = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product found! Details auto-filled.'), backgroundColor: AppColors.accent),
      );
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _existingProductId = null;
        _isLookingUp = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Product not in catalog. Fill details manually.'), backgroundColor: Colors.grey[700]),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLookingUp = false);
    }
  }

  Future<void> _saveProduct() async {
    if (_nameCtrl.text.isEmpty || _sellingPriceCtrl.text.isEmpty || _purchasePriceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in product name, purchase price and selling price'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      int productId;

      final mrpValue = double.tryParse(_sellingPriceCtrl.text) ?? 0.0;

      if (_existingProductId != null) {
        productId = _existingProductId!;
        // Update product MRP in global catalog
        await _api.patch('/products/$productId', body: {
          'mrp': mrpValue,
        });
      } else {
        int? categoryId;
        if (_selectedCategory != null) {
          final matchedCat = _categories.firstWhere(
            (c) => _getFormattedCategoryName(c) == _selectedCategory,
            orElse: () => {},
          );
          if (matchedCat.isNotEmpty) {
            categoryId = matchedCat['id'] as int?;
          }
        }

        // Create product in global catalog
        final barcode = _barcodeCtrl.text.isNotEmpty ? _barcodeCtrl.text : DateTime.now().millisecondsSinceEpoch.toString();
        final product = await _api.post('/products/', body: {
          'barcode': barcode,
          'sku': barcode,
          'name': _nameCtrl.text,
          'description': _notesCtrl.text.isNotEmpty ? _notesCtrl.text : _nameCtrl.text,
          'tax': 0,
          'unit': _selectedUnit ?? 'Piece',
          'mrp': mrpValue,
          'category_id': categoryId,
        });
        productId = product['id'];
      }

      // Add or Update shop inventory
      try {
        await _api.post('/inventory/', body: {
          'product_id': productId,
          'qty': int.tryParse(_openingStockCtrl.text) ?? 0,
          'reorder_level': int.tryParse(_lowStockCtrl.text) ?? 5,
          'cost_price': double.tryParse(_purchasePriceCtrl.text) ?? 0,
          'selling_price': mrpValue,
        });
      } on ApiException catch (e) {
        if (e.statusCode == 409) {
          // Update existing inventory item
          await _api.put('/inventory/$productId', body: {
            'qty': int.tryParse(_openingStockCtrl.text) ?? 0,
            'reorder_level': int.tryParse(_lowStockCtrl.text) ?? 5,
            'cost_price': double.tryParse(_purchasePriceCtrl.text) ?? 0,
            'selling_price': mrpValue,
          });
        } else {
          rethrow;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!'), backgroundColor: AppColors.accent),
      );
      Navigator.pop(context, true); // Return true to signal inventory refresh
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
        const SnackBar(content: Text('Failed to save product. Check your connection.'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    final categoryNames = _categories.map((c) => _getFormattedCategoryName(c)).toSet().toList();
    final dropdownCategories = categoryNames.isNotEmpty ? categoryNames : ['Grocery', 'Beverages', 'Snacks', 'Personal Care', 'Dairy', 'Household'];
    if (_selectedCategory != null && !dropdownCategories.contains(_selectedCategory)) {
      dropdownCategories.add(_selectedCategory!);
    }

    final unitItems = ['Piece', 'Kg', 'Gram', 'Litre', 'Ml', 'Pack', 'Box'];
    if (_selectedUnit != null && !unitItems.contains(_selectedUnit)) {
      unitItems.add(_selectedUnit!);
    }

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Add Product')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Scan trigger
            GestureDetector(
              onTap: _isLookingUp ? null : () async {
                final barcode = await BarcodeScannerWidget.scan(context);
                if (barcode != null && barcode.isNotEmpty) {
                  setState(() {
                    _barcodeCtrl.text = barcode;
                  });
                  _lookupBarcode();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: ext.surface2, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  _isLookingUp
                      ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                      : Icon(Icons.qr_code_scanner, size: 28, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Scan Barcode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent)),
                    Text('Auto-fill product details from barcode', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                  ])),
                  Icon(Icons.chevron_right, size: 18, color: ext.fgMuted),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            AppInput(label: 'Barcode', hint: 'Enter barcode manually', controller: _barcodeCtrl, keyboardType: TextInputType.number,
              suffix: IconButton(icon: const Icon(Icons.search, size: 18), onPressed: _lookupBarcode)),
            AppInput(label: 'Product Name', hint: 'e.g. Tata Salt 500g', controller: _nameCtrl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AppDropdown(
                    label: 'Category',
                    items: dropdownCategories,
                    value: _selectedCategory,
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
                    onPressed: _showAddCategoryDialog,
                  ),
                ),
              ],
            ),
            Row(children: [
              Expanded(child: AppInput(label: 'Purchase Price (₹)', hint: '0.00', controller: _purchasePriceCtrl, keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: AppInput(label: 'MRP / Selling Price (₹)', hint: '0.00', controller: _sellingPriceCtrl, keyboardType: TextInputType.number)),
            ]),
            AppInput(label: 'Opening Stock (units)', hint: '0', controller: _openingStockCtrl, keyboardType: TextInputType.number),
            AppInput(label: 'Low Stock Alert (units)', hint: '5', controller: _lowStockCtrl, keyboardType: TextInputType.number),
            AppDropdown(label: 'Unit', items: unitItems, value: _selectedUnit, onChanged: (v) => setState(() => _selectedUnit = v)),
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
            AppInput(label: 'Notes', hint: 'Expiry date, supplier info, etc.', maxLines: 3, controller: _notesCtrl),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : AppButton(label: 'Save Product', full: true, icon: const Icon(Icons.add, size: 16, color: Colors.white), onPressed: _saveProduct),
          ]),
        ),
      ),
    );
  }
}
