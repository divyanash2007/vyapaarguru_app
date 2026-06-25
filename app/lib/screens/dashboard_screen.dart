import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/auth_provider.dart';
import '../core/services/api_service.dart';
import '../widgets/shared_widgets.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onSwitchToBilling;
  const DashboardScreen({super.key, this.onSwitchToBilling});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService.instance;
  bool _isLoading = true;

  int _todaySalesTotal = 0;
  int _todayOrdersCount = 0;
  int _inventoryTotal = 0;
  int _lowStockCount = 0;
  int _monthlySalesTotal = 0;
  int _pendingPayments = 0;
  int _dealerOrdersCount = 0;
  List<Map<String, dynamic>> _recentSales = [];
  List<Map<String, dynamic>> _recentPurchases = [];
  List<double> _weeklyBarData = [0, 0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _api.get('/sales/', queryParams: {'per_page': '100'}),
        _api.get('/inventory/', queryParams: {'per_page': '1'}),
        _api.get('/inventory/low-stock'),
        _api.get('/purchases/', queryParams: {'per_page': '10'}),
      ]);

      final salesData = results[0] as Map<String, dynamic>;
      final inventoryData = results[1] as Map<String, dynamic>;
      final lowStockItems = results[2] as List<dynamic>;
      final purchasesData = results[3] as Map<String, dynamic>;

      final salesList = salesData['items'] as List<dynamic>;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Today's sales
      int todayTotal = 0;
      int todayCount = 0;
      int monthlyTotal = 0;
      int pendingTotal = 0;
      final weekData = List<double>.filled(7, 0);

      for (final sale in salesList) {
        final createdAt = DateTime.parse(sale['created_at']);
        final grandTotal = _parseNum(sale['grand_total']);
        final balanceDue = _parseNum(sale['balance_due']);

        // Today
        if (createdAt.isAfter(today)) {
          todayTotal += grandTotal;
          todayCount++;
        }
        // This month
        if (createdAt.month == now.month && createdAt.year == now.year) {
          monthlyTotal += grandTotal;
        }
        // Pending
        if (balanceDue > 0) {
          pendingTotal += balanceDue;
        }
        // Weekly bar chart (last 7 days)
        final daysAgo = now.difference(createdAt).inDays;
        if (daysAgo < 7) {
          // 6 = today, 5 = yesterday, ... 0 = 6 days ago
          weekData[6 - daysAgo] += grandTotal;
        }
      }

      // Normalize bar data for chart (0..1)
      final maxVal = weekData.reduce((a, b) => a > b ? a : b);
      final normalizedBars = weekData.map((v) => maxVal > 0 ? v / maxVal : 0.0).toList();

      if (!mounted) return;
      setState(() {
        _todaySalesTotal = todayTotal;
        _todayOrdersCount = todayCount;
        _inventoryTotal = inventoryData['total'] ?? 0;
        _lowStockCount = lowStockItems.length;
        _monthlySalesTotal = monthlyTotal;
        _pendingPayments = pendingTotal;
        _dealerOrdersCount = purchasesData['total'] ?? 0;
        _recentSales = (salesList.take(4).toList()).cast<Map<String, dynamic>>();
        _recentPurchases = ((purchasesData['items'] as List<dynamic>).take(2).toList()).cast<Map<String, dynamic>>();
        _weeklyBarData = normalizedBars;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  int _parseNum(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.round();
    return (double.tryParse(val.toString()) ?? 0).round();
  }

  String _formatCurrency(int amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹$amount';
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    final auth = context.watch<AuthProvider>();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _loadDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text.rich(TextSpan(text: 'Namaste, ', style: TextStyle(fontSize: 13, color: ext.fgMuted), children: [TextSpan(text: auth.ownerName.isNotEmpty ? auth.ownerName : 'Ji', style: TextStyle(fontWeight: FontWeight.w600, color: ext.fg)), const TextSpan(text: ' 👋')])),
                  const SizedBox(height: 2),
                  Text.rich(TextSpan(text: '${auth.shopName.split(' ').first} ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ext.fg), children: [TextSpan(text: auth.shopName.split(' ').length > 1 ? auth.shopName.split(' ').sublist(1).join(' ') : '', style: const TextStyle(color: AppColors.accent))])),
                ])),
                Stack(children: [
                  Icon(Icons.notifications_outlined, size: 24, color: ext.fg),
                  if (_lowStockCount > 0)
                    Positioned(top: -2, right: -2, child: Container(width: 16, height: 16, decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                      child: Center(child: Text('$_lowStockCount', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))))),
                ]),
              ],
            ),
            const SizedBox(height: 16),
            // Low stock alert
            if (_lowStockCount > 0)
              AlertBanner(text: '$_lowStockCount items low on stock — reorder now'),
            // Today's summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Today\'s Sales', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                    Text(_formatCurrency(_todaySalesTotal), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ext.fg)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Orders', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                    Text('$_todayOrdersCount', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ext.fg)),
                    const SizedBox(height: 4),
                    Text('Bills generated', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                  ]),
                ]),
                const SizedBox(height: 10),
                SizedBox(height: 40, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (int i = 0; i < _weeklyBarData.length; i++)
                    Expanded(child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 40 * (_weeklyBarData[i] > 0 ? _weeklyBarData[i] : 0.05),
                      decoration: BoxDecoration(
                        color: i == _weeklyBarData.length - 1 ? AppColors.accentDk : ext.surface2,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    )),
                ])),
              ]),
            ),
            const SizedBox(height: 16),
            // Stat grid
            GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.3, children: [
              StatCard(value: _formatCurrency(_monthlySalesTotal), label: 'Monthly Revenue', delta: 'This month'),
              StatCard(value: '$_inventoryTotal', label: 'Items in Stock', delta: _lowStockCount > 0 ? '$_lowStockCount low' : 'All good', deltaColor: _lowStockCount > 0 ? AppColors.warn : AppColors.accent),
              StatCard(value: _formatCurrency(_pendingPayments), label: 'Pending Payments', delta: _pendingPayments > 0 ? 'Outstanding' : 'All clear', deltaColor: _pendingPayments > 0 ? AppColors.danger : AppColors.accent),
              StatCard(value: '$_dealerOrdersCount', label: 'Dealer Orders', delta: 'Total'),
            ]),
            const SizedBox(height: 16),
            // Quick Actions
            Text('Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ext.fg)),
            const SizedBox(height: 10),
            Row(children: [
              _qaBtn(context, Icons.computer, 'New Bill', null, onTap: widget.onSwitchToBilling),
              _qaBtn(context, Icons.shopping_bag_outlined, 'Order Stock', '/dealer'),
              _qaBtn(context, Icons.add, 'Add Item', '/add-product'),
              _qaBtn(context, Icons.access_time, 'AI Tips', '/ai'),
            ]),
            const SizedBox(height: 16),
            // Recent transactions
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Recent Transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ext.fg)),
              GestureDetector(onTap: () => Navigator.pushNamed(context, '/orders'), child: const Text('See all', style: TextStyle(fontSize: 12, color: AppColors.accent))),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
              child: _recentSales.isEmpty && _recentPurchases.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('No transactions yet', style: TextStyle(fontSize: 13, color: ext.fgMuted))),
                    )
                  : Column(children: [
                      ..._recentSales.map((sale) {
                        final customerName = sale['customer']?['name'] ?? 'Walk-in Customer';
                        final grandTotal = _parseNum(sale['grand_total']);
                        final createdAt = DateTime.tryParse(sale['created_at'] ?? '') ?? DateTime.now();
                        final timeAgo = _timeAgo(createdAt);
                        return _txRow(ext, customerName, '$timeAgo · Bill #${sale['id']}', '+₹$grandTotal', true, last: sale == _recentSales.last && _recentPurchases.isEmpty);
                      }),
                      ..._recentPurchases.map((purchase) {
                        final supplierName = purchase['supplier']?['name'] ?? 'Supplier';
                        final totalAmount = _parseNum(purchase['total_amount']);
                        final createdAt = DateTime.tryParse(purchase['created_at'] ?? '') ?? DateTime.now();
                        final timeAgo = _timeAgo(createdAt);
                        return _txRow(ext, '$supplierName (Dealer)', '$timeAgo · Order #D-${purchase['id']}', '-₹$totalAmount', false, last: purchase == _recentPurchases.last);
                      }),
                    ]),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _qaBtn(BuildContext ctx, IconData icon, String label, String? route, {VoidCallback? onTap}) {
    final ext = ctx.appTheme;
    return Expanded(child: GestureDetector(
      onTap: onTap ?? (route != null ? () => Navigator.pushNamed(ctx, route) : null),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
        child: Column(children: [Icon(icon, size: 22, color: ext.fg), const SizedBox(height: 6), Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: ext.fgMuted), textAlign: TextAlign.center)]),
      ),
    ));
  }

  Widget _txRow(AppThemeExtension ext, String name, String sub, String amt, bool isSale, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: ext.border))),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isSale ? AppColors.accent : AppColors.blue)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ext.fg)),
          Text(sub, style: TextStyle(fontSize: 11, color: ext.fgMuted)),
        ])),
        Text(amt, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isSale ? AppColors.accent : AppColors.danger)),
      ]),
    );
  }
}
