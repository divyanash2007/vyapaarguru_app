import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/services/api_service.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/barcode_scanner_widget.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _api = ApiService.instance;
  final _searchCtrl = TextEditingController();
  bool _isLoading = true;
  int _chipIdx = 0;
  String _searchQuery = '';

  List<Map<String, dynamic>> _inventoryItems = [];
  List<Map<String, dynamic>> _lowStockItems = [];
  List<Map<String, dynamic>> _categories = [];
  int _totalItems = 0;
  int _outOfStockCount = 0;

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
        _api.get('/inventory/', queryParams: {'per_page': '100'}),
        _api.get('/inventory/low-stock'),
        _api.get('/categories/'),
      ]);

      final inventoryData = results[0] as Map<String, dynamic>;
      final lowStock = results[1] as List<dynamic>;
      final categories = results[2] as List<dynamic>;

      final items = (inventoryData['items'] as List<dynamic>).cast<Map<String, dynamic>>();
      final outOfStock = items.where((item) => (item['qty'] as int) == 0).length;

      if (!mounted) return;
      setState(() {
        _inventoryItems = items;
        _lowStockItems = lowStock.cast<Map<String, dynamic>>();
        _categories = categories.cast<Map<String, dynamic>>();
        _totalItems = inventoryData['total'] ?? items.length;
        _outOfStockCount = outOfStock;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

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

  List<Map<String, dynamic>> get _filteredItems {
    var items = _inventoryItems;

    // Category filter
    if (_chipIdx > 0 && _chipIdx - 1 < _categories.length) {
      final catId = _categories[_chipIdx - 1]['id'];
      items = items.where((item) => item['product']?['category_id'] == catId).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items.where((item) {
        final name = (item['product']?['name'] ?? '').toString().toLowerCase();
        final barcode = (item['product']?['barcode'] ?? '').toString().toLowerCase();
        return name.contains(q) || barcode.contains(q);
      }).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    final chipLabels = ['All', ..._categories.map((c) => _getFormattedCategoryName(c)).toSet()];
    final items = _filteredItems;
    final lowStockAlert = _lowStockItems.isNotEmpty
        ? '${_lowStockItems.first['product']?['name'] ?? 'Item'} — only ${_lowStockItems.first['qty']} units left'
        : null;

    return Stack(children: [
      RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppSearchBar(
              hint: 'Search items or scan barcode…',
              controller: _searchCtrl,
              trailing: GestureDetector(
                onTap: () async {
                  final barcode = await BarcodeScannerWidget.scan(context);
                  if (barcode != null && barcode.isNotEmpty) {
                    setState(() {
                      _searchCtrl.text = barcode;
                      _searchQuery = barcode;
                    });
                  }
                },
                child: Icon(Icons.qr_code_scanner, size: 18, color: AppColors.accent),
              ),
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
            ChipRow(labels: chipLabels, selected: _chipIdx, onSelected: (i) => setState(() => _chipIdx = i)),
            const SizedBox(height: 8),
            // Stock summary
            Row(children: [
              _pill(ext, '$_totalItems', 'Total Items', null),
              const SizedBox(width: 8),
              _pill(ext, '${_lowStockItems.length}', 'Low Stock', AppColors.warn),
              const SizedBox(width: 8),
              _pill(ext, '$_outOfStockCount', 'Out of Stock', AppColors.danger),
            ]),
            const SizedBox(height: 14),
            if (lowStockAlert != null) AlertBanner(text: lowStockAlert),
            const SectionLabel('All Products'),
            items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('No products found', style: TextStyle(fontSize: 14, color: ext.fgMuted))),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
                    child: Column(children: items.map((item) => _itemTile(ext, item)).toList()),
                  ),
            const SizedBox(height: 80),
          ]),
        ),
      ),
      // FAB
      Positioned(bottom: 16, right: 16, child: FloatingActionButton(
        backgroundColor: AppColors.accentDk, foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add-product');
          if (result == true) _loadData();
        },
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

  Widget _itemTile(AppThemeExtension ext, Map<String, dynamic> item) {
    final product = item['product'] as Map<String, dynamic>? ?? {};
    final name = product['name'] ?? 'Unknown';
    final barcode = product['barcode'] ?? '';
    final sellingPrice = _parseNum(item['selling_price']);
    final qty = item['qty'] as int? ?? 0;
    final reorderLevel = item['reorder_level'] as int? ?? 10;

    // Compute stock ratio
    final maxQty = reorderLevel * 3; // consider 3x reorder as "full stock"
    final ratio = maxQty > 0 ? (qty / maxQty).clamp(0.0, 1.0) : 0.0;

    Color barColor;
    BadgeVariant badgeVariant;
    String badgeLabel;

    if (qty == 0) {
      barColor = AppColors.danger;
      badgeVariant = BadgeVariant.red;
      badgeLabel = 'Out';
    } else if (qty <= reorderLevel) {
      barColor = AppColors.warn;
      badgeVariant = BadgeVariant.warn;
      badgeLabel = '$qty left';
    } else {
      barColor = AppColors.accentDk;
      badgeVariant = BadgeVariant.green;
      badgeLabel = '$qty left';
    }

    // Pick emoji from first char of category or product name
    final emoji = _getEmoji(product['category']?['name'] ?? name);
    final imageUrl = product['img_url'] as String? ?? product['image_url'] as String?;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ext.border.withValues(alpha: 0.5)))),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: ext.surface2, borderRadius: BorderRadius.circular(6)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: hasImage
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
                  )
                : Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ext.fg)),
          Text('Barcode: $barcode', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: ratio, minHeight: 4, backgroundColor: ext.surface2, valueColor: AlwaysStoppedAnimation(barColor))),
        ])),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹$sellingPrice', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ext.fg)),
          const SizedBox(height: 2),
          AppBadge(label: badgeLabel, variant: badgeVariant),
        ]),
      ]),
    );
  }

  int _parseNum(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.round();
    return (double.tryParse(val.toString()) ?? 0).round();
  }

  String _getEmoji(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('grocery') || lower.contains('salt') || lower.contains('food')) return '🧂';
    if (lower.contains('oil') || lower.contains('cook')) return '🛢️';
    if (lower.contains('rice') || lower.contains('grain')) return '🍚';
    if (lower.contains('soap') || lower.contains('personal') || lower.contains('care')) return '🧴';
    if (lower.contains('beverage') || lower.contains('drink') || lower.contains('cola')) return '🥤';
    if (lower.contains('snack') || lower.contains('noodle') || lower.contains('maggi')) return '🍜';
    if (lower.contains('dairy') || lower.contains('milk')) return '🥛';
    if (lower.contains('medical') || lower.contains('medicine')) return '💊';
    if (lower.contains('electronic')) return '🔌';
    if (lower.contains('cloth')) return '👕';
    return '📦';
  }
}
