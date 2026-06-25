import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/services/api_service.dart';
import '../widgets/shared_widgets.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});
  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _api = ApiService.instance;
  int _tab = 0;
  bool _isLoading = true;
  bool _showDetail = false;
  Map<String, dynamic>? _detailData;
  String _detailType = 'bill';

  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _purchases = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _api.get('/sales/', queryParams: {'per_page': '50'}),
        _api.get('/purchases/', queryParams: {'per_page': '50'}),
      ]);

      if (!mounted) return;
      setState(() {
        _sales = ((results[0] as Map<String, dynamic>)['items'] as List<dynamic>).cast<Map<String, dynamic>>();
        _purchases = ((results[1] as Map<String, dynamic>)['items'] as List<dynamic>).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(d.year, d.month, d.day);

    String prefix;
    if (dateOnly == today) {
      prefix = 'Today';
    } else if (dateOnly == yesterday) {
      prefix = 'Yesterday';
    } else {
      prefix = '${d.day}/${d.month}/${d.year}';
    }
    return '$prefix, ${d.hour}:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Scaffold(
      appBar: _showDetail
          ? AppBar(leading: BackButton(onPressed: () => setState(() => _showDetail = false)), title: Text(_detailType == 'bill' ? 'Bill #${_detailData?['id'] ?? ''}' : 'Order #D-${_detailData?['id'] ?? ''}'))
          : AppBar(leading: const BackButton(), title: const Text('Order History')),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : _showDetail
                ? _detail(ext)
                : Column(children: [
                    // Tabs
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(100), border: Border.all(color: ext.border)),
                        child: Row(children: ['Customer Sales', 'Dealer Orders'].asMap().entries.map((e) {
                          final active = e.key == _tab;
                          return Expanded(child: GestureDetector(
                            onTap: () => setState(() => _tab = e.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(color: active ? AppColors.accentDk : Colors.transparent, borderRadius: BorderRadius.circular(100)),
                              child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: active ? Colors.white : ext.fgMuted)),
                            ),
                          ));
                        }).toList()),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: AppSearchBar(hint: 'Search by name, bill no…')),
                    Expanded(child: RefreshIndicator(
                      color: AppColors.accent,
                      onRefresh: _loadData,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: _tab == 0 ? _buildSalesCards(ext) : _buildPurchaseCards(ext),
                      ),
                    )),
                  ]),
      ),
    );
  }

  List<Widget> _buildSalesCards(AppThemeExtension ext) {
    if (_sales.isEmpty) {
      return [Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('No sales yet', style: TextStyle(fontSize: 14, color: ext.fgMuted))))];
    }
    return _sales.map((sale) {
      final customerName = sale['customer']?['name'] ?? 'Walk-in Customer';
      final items = (sale['items'] as List<dynamic>?) ?? [];
      final itemsSummary = items.take(3).map((i) => i['product']?['name'] ?? 'Item').join(', ');
      final grandTotal = '₹${sale['grand_total']}';
      final date = _formatDate(sale['created_at']);
      final balanceDue = double.tryParse(sale['balance_due']?.toString() ?? '0') ?? 0;
      final status = balanceDue > 0 ? 'Pending' : 'Paid';
      final badge = balanceDue > 0 ? BadgeVariant.warn : BadgeVariant.green;

      return _orderCard(ext, 'BILL #${sale['id']}', customerName, itemsSummary, grandTotal, date, status, badge, 'bill', sale);
    }).toList();
  }

  List<Widget> _buildPurchaseCards(AppThemeExtension ext) {
    if (_purchases.isEmpty) {
      return [Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('No dealer orders yet', style: TextStyle(fontSize: 14, color: ext.fgMuted))))];
    }
    return _purchases.map((purchase) {
      final supplierName = purchase['supplier']?['name'] ?? 'Supplier';
      final items = (purchase['items'] as List<dynamic>?) ?? [];
      final itemsSummary = items.take(3).map((i) => '${i['product']?['name'] ?? 'Item'} ×${i['qty']}').join(', ');
      final totalAmount = '₹${purchase['total_amount']}';
      final date = _formatDate(purchase['created_at']);

      return _orderCard(ext, 'ORDER #D-${purchase['id']}', supplierName, itemsSummary, totalAmount, date, 'Delivered', BadgeVariant.blue, 'dealer', purchase);
    }).toList();
  }

  Widget _orderCard(AppThemeExtension ext, String id, String name, String items, String total, String date, String status, BadgeVariant badge, String type, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () => setState(() { _showDetail = true; _detailType = type; _detailData = data; }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(id, style: const TextStyle(fontSize: 12, color: AppColors.accent, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ext.fg)),
            ]),
            AppBadge(label: status, variant: badge),
          ]),
          const SizedBox(height: 4),
          Text(items, style: TextStyle(fontSize: 12, color: ext.fgMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: ext.border))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(total, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ext.fg)),
              Text(date, style: TextStyle(fontSize: 11, color: ext.fgMuted)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _detail(AppThemeExtension ext) {
    if (_detailData == null) return const SizedBox();
    final isBill = _detailType == 'bill';
    final data = _detailData!;

    final name = isBill ? (data['customer']?['name'] ?? 'Walk-in Customer') : (data['supplier']?['name'] ?? 'Supplier');
    final subtitle = isBill ? (data['customer']?['phone'] ?? '') : 'Supplier';
    final date = _formatDate(data['created_at']);
    final items = (data['items'] as List<dynamic>?) ?? [];
    final total = isBill ? data['grand_total']?.toString() ?? '0' : data['total_amount']?.toString() ?? '0';
    final balanceDue = double.tryParse(data['balance_due']?.toString() ?? '0') ?? 0;
    final status = isBill ? (balanceDue > 0 ? 'Pending' : 'Paid') : 'Delivered';
    final badgeVariant = isBill ? (balanceDue > 0 ? BadgeVariant.warn : BadgeVariant.green) : BadgeVariant.blue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ext.fg)),
                if (subtitle.isNotEmpty) Text(isBill ? '+91 $subtitle' : subtitle, style: TextStyle(fontSize: 12, color: ext.fgMuted)),
              ]),
              AppBadge(label: status, variant: badgeVariant),
            ]),
            const SizedBox(height: 6),
            Text('${isBill ? 'BILL' : 'ORDER'} #${isBill ? '' : 'D-'}${data['id']} · $date', style: TextStyle(fontSize: 11, color: ext.fgMuted, letterSpacing: 1)),
          ]),
        ),
        const SizedBox(height: 12),
        SectionLabel(isBill ? 'Items' : 'Items Ordered'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
          child: Column(children: [
            ...items.map((item) {
              final productName = item['product']?['name'] ?? 'Item';
              final qty = item['qty'] ?? 1;
              final price = isBill
                  ? double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0
                  : double.tryParse(item['cost_price']?.toString() ?? '0') ?? 0;
              return BillLine(label: '$productName × $qty', value: '₹${(price * qty).toStringAsFixed(0)}');
            }),
            if (isBill) BillLine(label: 'Tax', value: '₹${data['tax'] ?? 0}', valueColor: ext.fgMuted),
            BillLine(label: 'Total', value: '₹$total', isTotal: true, valueColor: AppColors.accent),
          ]),
        ),
        const SizedBox(height: 12),
        if (isBill) AppButton(label: 'Resend Bill', full: true, outline: true, primary: false, onPressed: () {}),
      ]),
    );
  }
}
