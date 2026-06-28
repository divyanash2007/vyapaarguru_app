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
  String? _errorMessage;

  // Parsed data
  Map<String, dynamic> _kpis = {};
  List<Map<String, dynamic>> _dailySales = [];
  List<Map<String, dynamic>> _trend = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _topItems = [];
  List<Map<String, dynamic>> _hourlySales = [];
  Map<String, dynamic> _stockHealth = {};

  static const _periodKeys = ['today', 'week', 'month', 'year'];
  static const _periodLabels = ['Today', 'Week', 'Month', 'Year'];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _api.get(
        '/analytics/dashboard',
        queryParams: {'period': _periodKeys[_period]},
      );

      if (!mounted) return;
      setState(() {
        _kpis = data['kpis'] ?? {};
        _dailySales = (data['daily_sales'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        _trend = (data['trend'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        _categories = (data['category_breakdown'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        _topItems = (data['top_items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        _hourlySales = (data['hourly_sales'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        _stockHealth = data['stock_health'] ?? {};
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load analytics';
      });
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? 0;
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  // ─── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off, size: 48, color: ext.fgMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(_errorMessage!, style: TextStyle(color: ext.fgMuted)),
          const SizedBox(height: 12),
          TextButton(onPressed: _loadAnalytics, child: const Text('Retry', style: TextStyle(color: AppColors.accent))),
        ]),
      );
    }

    final revenue = _parseDouble(_kpis['revenue']);
    final profit = _parseDouble(_kpis['profit']);
    final ordersCount = _parseInt(_kpis['orders_count']);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Period tabs ───────────────────────────────
            _buildPeriodTabs(ext),
            const SizedBox(height: 16),

            // ─── KPI Row (Single Line) ───────────────────
            _buildKpiRow(ext, revenue, profit, ordersCount),
            const SizedBox(height: 14),

            // ─── Daily Sales Bar Chart ────────────────────
            _buildDailySalesChart(ext),
            const SizedBox(height: 4),

            // ─── Revenue Trend Line ───────────────────────
            _buildTrendChart(ext),
            const SizedBox(height: 4),

            // ─── Category Breakdown ───────────────────────
            if (_categories.isNotEmpty) _buildCategoryDonut(ext),

            // ─── Top Selling Items ────────────────────────
            if (_topItems.isNotEmpty) _buildTopItems(ext),

            // ─── Hourly Sales Heatmap ─────────────────────
            if (_hourlySales.isNotEmpty) _buildHourlySales(ext),

            // ─── Stock Health ─────────────────────────────
            _buildStockHealth(ext),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Period Tabs ─────────────────────────────────────────────

  Widget _buildPeriodTabs(AppThemeExtension ext) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: ext.border),
      ),
      child: Row(
        children: _periodLabels.asMap().entries.map((e) {
          final active = e.key == _period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _period = e.key);
                _loadAnalytics();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.accentDk : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : ext.fgMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── KPI Row ──────────────────────────────────────────────────

  Widget _buildKpiRow(AppThemeExtension ext, double revenue, double profit, int orders) {
    return Row(
      children: [
        _singleKpiCard(ext, _formatCurrency(revenue), 'REVENUE'),
        const SizedBox(width: 8),
        _singleKpiCard(ext, _formatCurrency(profit), 'PROFIT', valueColor: AppColors.accent),
        const SizedBox(width: 8),
        _singleKpiCard(ext, '$orders', 'ORDERS'),
      ],
    );
  }

  Widget _singleKpiCard(AppThemeExtension ext, String value, String label, {Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: ext.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ext.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: valueColor ?? ext.fg,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.sourceCodePro(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: ext.fgMuted,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Daily Sales Bar Chart ───────────────────────────────────

  Widget _buildDailySalesChart(AppThemeExtension ext) {
    if (_dailySales.isEmpty) return const SizedBox.shrink();

    final maxRevenue = _dailySales.fold<double>(0.0, (max, e) {
      final v = _parseDouble(e['revenue']);
      return v > max ? v : max;
    });

    return _chartCard(
      ext,
      'Daily Sales',
      '${_periodLabels[_period]} · ${_formatCurrency(_parseDouble(_kpis['revenue']))} total',
      SizedBox(
        height: 100,
        child: BarChart(
          BarChartData(
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, meta) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= _dailySales.length) return const SizedBox();
                    
                    // Filter monthly dates to prevent text overlaps
                    if (_period == 2) {
                      final dayNum = int.tryParse(_dailySales[idx]['label'] ?? '') ?? 0;
                      if (dayNum != 1 && dayNum % 5 != 0) {
                        return const SizedBox();
                      }
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _dailySales[idx]['label'] ?? '',
                        style: GoogleFonts.sourceCodePro(fontSize: 9, color: ext.fgMuted),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: _dailySales.asMap().entries.map((e) {
              final rev = _parseDouble(e.value['revenue']);
              final isLast = e.key == _dailySales.length - 1;
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: maxRevenue > 0 ? rev : 0.1,
                    width: _dailySales.length > 14 ? 6 : 20,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    color: isLast ? AppColors.accentDk : ext.surface2,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ─── Revenue Trend Line ──────────────────────────────────────

  Widget _buildTrendChart(AppThemeExtension ext) {
    if (_trend.isEmpty) return const SizedBox.shrink();

    final spots = _trend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), _parseDouble(e.value['revenue']) / 1000);
    }).toList();

    return _chartCard(
      ext,
      'Revenue Trend',
      'Last 6 weeks (₹K)',
      SizedBox(
        height: 90,
        child: LineChart(
          LineChartData(
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, meta) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= _trend.length) return const SizedBox();
                    return Text(
                      _trend[idx]['week_label'] ?? '',
                      style: GoogleFonts.sourceCodePro(fontSize: 9, color: ext.fgMuted),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.accent,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                    radius: 3,
                    color: AppColors.accent,
                    strokeWidth: 1.5,
                    strokeColor: ext.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.accent.withValues(alpha: 0.25),
                      AppColors.accent.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Category Donut ──────────────────────────────────────────

  Widget _buildCategoryDonut(AppThemeExtension ext) {
    final catColors = [
      const Color(0xFF00684A),
      AppColors.blue,
      AppColors.warn,
      AppColors.danger,
      const Color(0xFF8B5CF6),
      Colors.teal,
    ];

    final totalCatRevenue = _categories.fold<double>(0.0, (s, e) => s + _parseDouble(e['revenue']));

    return _chartCard(
      ext,
      'Sales by Category',
      _periodLabels[_period],
      Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 22,
                sections: _categories.asMap().entries.map((e) {
                  final colorIdx = e.key % catColors.length;
                  return PieChartSectionData(
                    value: _parseDouble(e.value['revenue']),
                    color: catColors[colorIdx],
                    radius: 16,
                    showTitle: false,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: _categories.asMap().entries.map((e) {
                final colorIdx = e.key % catColors.length;
                final rev = _parseDouble(e.value['revenue']);
                final pct = totalCatRevenue > 0 ? (rev / totalCatRevenue * 100).round() : 0;
                return _legendRow(ext, catColors[colorIdx], e.value['name'] ?? 'Other', '$pct%');
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Top Selling Items ───────────────────────────────────────

  Widget _buildTopItems(AppThemeExtension ext) {
    final topMax = _topItems.isNotEmpty ? _parseDouble(_topItems.first['revenue']) : 1;

    return _chartCard(
      ext,
      'Top Selling Items',
      'By revenue · ${_periodLabels[_period]}',
      Column(
        children: _topItems.asMap().entries.map((e) {
          final rank = e.key + 1;
          final name = e.value['name'] ?? 'Unknown';
          final rev = _parseDouble(e.value['revenue']);
          final qty = _parseInt(e.value['qty_sold']);
          final pct = topMax > 0 ? rev / topMax : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '#$rank',
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: rank <= 3 ? AppColors.accent : ext.fgMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ext.fg),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatCurrency(rev),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ext.fg),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 4,
                                backgroundColor: ext.surface2,
                                valueColor: const AlwaysStoppedAnimation(AppColors.accentDk),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$qty sold',
                            style: TextStyle(fontSize: 10, color: ext.fgMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Hourly Sales Heatmap ────────────────────────────────────

  Widget _buildHourlySales(AppThemeExtension ext) {
    final maxHourRev = _hourlySales.fold<double>(0.0, (max, e) {
      final v = _parseDouble(e['revenue']);
      return v > max ? v : max;
    });

    // Find peak hour
    String peakLabel = '--';
    if (_hourlySales.isNotEmpty) {
      final peak = _hourlySales.reduce((a, b) => _parseDouble(a['revenue']) >= _parseDouble(b['revenue']) ? a : b);
      final h = _parseInt(peak['hour']);
      peakLabel = '${h > 12 ? h - 12 : h}${h >= 12 ? 'PM' : 'AM'}';
    }

    return _chartCard(
      ext,
      'Hourly Sales Pattern',
      'Peak hour: $peakLabel',
      SizedBox(
        height: 120,
        child: BarChart(
          BarChartData(
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, meta) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= _hourlySales.length) return const SizedBox();
                    final h = _parseInt(_hourlySales[idx]['hour']);
                    // Only show every other label to avoid crowding
                    if (idx % 3 != 0) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${h > 12 ? h - 12 : h}${h >= 12 ? 'p' : 'a'}',
                        style: GoogleFonts.sourceCodePro(fontSize: 8, color: ext.fgMuted),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: _hourlySales.asMap().entries.map((e) {
              final rev = _parseDouble(e.value['revenue']);
              final intensity = maxHourRev > 0 ? rev / maxHourRev : 0.0;
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: maxHourRev > 0 ? rev : 0.1,
                    width: 8,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    color: intensity > 0.7
                        ? AppColors.accentDk
                        : intensity > 0.3
                            ? AppColors.accent.withValues(alpha: 0.5)
                            : ext.surface2,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ─── Stock Health ────────────────────────────────────────────

  Widget _buildStockHealth(AppThemeExtension ext) {
    final total = _parseInt(_stockHealth['total_items']);
    final lowStock = _parseInt(_stockHealth['low_stock']);
    final outOfStock = _parseInt(_stockHealth['out_of_stock']);
    final healthyPct = total > 0 ? (total - lowStock - outOfStock) / total : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ext.border),
      ),
      child: Row(
        children: [
          // Circular progress ring
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: healthyPct,
                    strokeWidth: 5,
                    backgroundColor: ext.surface2,
                    valueColor: AlwaysStoppedAnimation(
                      healthyPct > 0.7 ? AppColors.success : healthyPct > 0.4 ? AppColors.warn : AppColors.danger,
                    ),
                  ),
                ),
                Text(
                  '${(healthyPct * 100).round()}%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ext.fg),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stock Health', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.fg)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _stockMetric(ext, '$total', 'Total', ext.fg),
                    const SizedBox(width: 16),
                    _stockMetric(ext, '$lowStock', 'Low', AppColors.warn),
                    const SizedBox(width: 16),
                    _stockMetric(ext, '$outOfStock', 'Out', AppColors.danger),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockMetric(AppThemeExtension ext, String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: GoogleFonts.sourceCodePro(fontSize: 9, color: ext.fgMuted, letterSpacing: 0.3)),
      ],
    );
  }

  // ─── Shared Utilities ────────────────────────────────────────

  Widget _chartCard(AppThemeExtension ext, String title, String subtitle, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ext.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.fg)),
          Text(subtitle, style: TextStyle(fontSize: 11, color: ext.fgMuted)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _legendRow(AppThemeExtension ext, Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: ext.fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ext.fg)),
        ],
      ),
    );
  }
}
