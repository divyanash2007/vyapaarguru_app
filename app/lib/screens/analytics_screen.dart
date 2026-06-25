import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _api = ApiService.instance;
  int _period = 1; // 0=Today, 1=Week, 2=Month, 3=Year
  bool _isLoading = true;

  int _revenue = 0;
  int _profit = 0;
  int _ordersCount = 0;
  List<double> _dailySales = [0, 0, 0, 0, 0, 0, 0];
  List<FlSpot> _trendSpots = [];
  Map<String, double> _categoryBreakdown = {};
  List<MapEntry<String, double>> _topItems = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all sales
      final salesData = await _api.get('/sales/', queryParams: {'per_page': '200'});
      final salesList = (salesData['items'] as List<dynamic>).cast<Map<String, dynamic>>();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Filter by selected period
      List<Map<String, dynamic>> filtered;
      switch (_period) {
        case 0: // Today
          filtered = salesList.where((s) => DateTime.parse(s['created_at']).isAfter(today)).toList();
          break;
        case 1: // Week
          final weekAgo = today.subtract(const Duration(days: 7));
          filtered = salesList.where((s) => DateTime.parse(s['created_at']).isAfter(weekAgo)).toList();
          break;
        case 2: // Month
          filtered = salesList.where((s) {
            final d = DateTime.parse(s['created_at']);
            return d.month == now.month && d.year == now.year;
          }).toList();
          break;
        default: // Year
          filtered = salesList.where((s) {
            final d = DateTime.parse(s['created_at']);
            return d.year == now.year;
          }).toList();
      }

      // KPIs
      int revenue = 0;
      int ordersCount = filtered.length;
      for (final sale in filtered) {
        revenue += _parseNum(sale['grand_total']);
      }
      // Approximate profit as 22% of revenue (rough margin)
      final profit = (revenue * 0.22).round();

      // Daily sales for bar chart (last 7 days)
      final dailySales = List<double>.filled(7, 0);
      for (final sale in salesList) {
        final d = DateTime.parse(sale['created_at']);
        final daysAgo = now.difference(d).inDays;
        if (daysAgo < 7) {
          dailySales[6 - daysAgo] += _parseNum(sale['grand_total']).toDouble();
        }
      }

      // Trend line — weekly totals for last 6 weeks
      final trendSpots = <FlSpot>[];
      for (int w = 5; w >= 0; w--) {
        final weekStart = today.subtract(Duration(days: 7 * w + today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        double weekTotal = 0;
        for (final sale in salesList) {
          final d = DateTime.parse(sale['created_at']);
          if (d.isAfter(weekStart) && d.isBefore(weekEnd)) {
            weekTotal += _parseNum(sale['grand_total']);
          }
        }
        trendSpots.add(FlSpot((5 - w).toDouble(), weekTotal / 1000));
      }

      // Category breakdown
      final catRevenue = <String, double>{};
      final itemRevenue = <String, double>{};
      for (final sale in filtered) {
        for (final item in (sale['items'] as List<dynamic>? ?? [])) {
          final product = item['product'] as Map<String, dynamic>? ?? {};
          final catName = product['category']?['name'] ?? 'Other';
          final productName = product['name'] ?? 'Unknown';
          final itemTotal = _parseNum(item['unit_price']).toDouble() * (item['qty'] as int? ?? 1);

          catRevenue[catName] = (catRevenue[catName] ?? 0) + itemTotal;
          itemRevenue[productName] = (itemRevenue[productName] ?? 0) + itemTotal;
        }
      }

      // Top items by revenue
      final sortedItems = itemRevenue.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

      if (!mounted) return;
      setState(() {
        _revenue = revenue;
        _profit = profit;
        _ordersCount = ordersCount;
        _dailySales = dailySales;
        _trendSpots = trendSpots;
        _categoryBreakdown = catRevenue;
        _topItems = sortedItems.take(4).toList();
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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    // Normalize daily sales for bar chart
    final maxDaily = _dailySales.reduce((a, b) => a > b ? a : b);

    // Category pie data
    final totalCatRevenue = _categoryBreakdown.values.fold(0.0, (a, b) => a + b);
    final catColors = [const Color(0xFF00684A), AppColors.blue, AppColors.warn, AppColors.danger, Colors.grey];

    // Top item max for progress bar
    final topMax = _topItems.isNotEmpty ? _topItems.first.value : 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Period tabs
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(100), border: Border.all(color: ext.border)),
          child: Row(children: ['Today', 'Week', 'Month', 'Year'].asMap().entries.map((e) {
            final active = e.key == _period;
            return Expanded(child: GestureDetector(
              onTap: () {
                setState(() => _period = e.key);
                _loadAnalytics();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(color: active ? AppColors.accentDk : Colors.transparent, borderRadius: BorderRadius.circular(100)),
                child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: active ? Colors.white : ext.fgMuted)),
              ),
            ));
          }).toList()),
        ),
        const SizedBox(height: 16),
        // KPI row
        Row(children: [
          _kpi(ext, _formatCurrency(_revenue), 'Revenue', null),
          const SizedBox(width: 8),
          _kpi(ext, _formatCurrency(_profit), 'Profit', AppColors.accent),
          const SizedBox(width: 8),
          _kpi(ext, '$_ordersCount', 'Orders', null),
        ]),
        const SizedBox(height: 12),
        // Bar chart
        _chartCard(ext, 'Daily Sales', 'This week · ${_formatCurrency(_revenue)} total', SizedBox(
          height: 90,
          child: BarChart(BarChartData(
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (v.toInt() < 0 || v.toInt() >= days.length) return const SizedBox();
                return Text(days[v.toInt()], style: GoogleFonts.sourceCodePro(fontSize: 9, color: ext.fgMuted));
              })),
            ),
            barGroups: _dailySales.asMap().entries.map((e) {
              return BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(
                  toY: maxDaily > 0 ? e.value : 0.1,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  color: e.key == 6 ? AppColors.accentDk : ext.surface2,
                ),
              ]);
            }).toList(),
          )),
        )),
        // Line chart
        _chartCard(ext, 'Revenue Trend', 'Last 6 weeks', SizedBox(
          height: 80,
          child: LineChart(LineChartData(
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: _trendSpots.isNotEmpty ? _trendSpots : [const FlSpot(0, 0)],
                isCurved: true, color: AppColors.accent,
                barWidth: 2, dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: AppColors.accent.withValues(alpha: 0.1)),
              ),
            ],
          )),
        )),
        // Category donut
        if (_categoryBreakdown.isNotEmpty)
          _chartCard(ext, 'Sales by Category', _period == 0 ? 'Today' : _period == 1 ? 'This week' : _period == 2 ? 'This month' : 'This year', Row(children: [
            SizedBox(
              width: 80, height: 80,
              child: PieChart(PieChartData(
                sectionsSpace: 0, centerSpaceRadius: 16,
                sections: _categoryBreakdown.entries.toList().asMap().entries.map((e) {
                  final colorIdx = e.key % catColors.length;
                  return PieChartSectionData(value: e.value.value, color: catColors[colorIdx], radius: 14, showTitle: false);
                }).toList(),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(children: _categoryBreakdown.entries.toList().asMap().entries.map((e) {
              final colorIdx = e.key % catColors.length;
              final pct = totalCatRevenue > 0 ? (e.value.value / totalCatRevenue * 100).round() : 0;
              return _legend(ext, catColors[colorIdx], e.value.key, '$pct%');
            }).toList())),
          ])),
        // Top selling
        if (_topItems.isNotEmpty)
          _chartCard(ext, 'Top Selling Items', 'By revenue', Column(children: _topItems.asMap().entries.map((e) {
            final rank = '#${e.key + 1}';
            final pct = topMax > 0 ? e.value.value / topMax : 0.0;
            return _topItem(ext, rank, e.value.key, _formatCurrency(e.value.value.round()), pct);
          }).toList())),
      ]),
    );
  }

  Widget _kpi(AppThemeExtension ext, String val, String lbl, Color? color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
      child: Column(children: [
        Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color ?? ext.fg)),
        const SizedBox(height: 2),
        Text(lbl.toUpperCase(), style: GoogleFonts.sourceCodePro(fontSize: 10, color: ext.fgMuted, letterSpacing: 0.3)),
      ]),
    ));
  }

  Widget _chartCard(AppThemeExtension ext, String title, String sub, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.fg)),
        Text(sub, style: TextStyle(fontSize: 11, color: ext.fgMuted)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _legend(AppThemeExtension ext, Color c, String lbl, String val) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 6),
      Expanded(child: Text(lbl, style: TextStyle(fontSize: 12, color: ext.fg))),
      Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ext.fg)),
    ]));
  }

  Widget _topItem(AppThemeExtension ext, String rank, String name, String val, double pct) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
      SizedBox(width: 20, child: Text(rank, style: GoogleFonts.sourceCodePro(fontSize: 12, fontWeight: FontWeight.w700, color: ext.fgMuted))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ext.fg)),
        const SizedBox(height: 4),
        ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: pct, minHeight: 4, backgroundColor: Colors.transparent, valueColor: const AlwaysStoppedAnimation(AppColors.accentDk))),
      ])),
      const SizedBox(width: 12),
      Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.fg)),
    ]));
  }
}
