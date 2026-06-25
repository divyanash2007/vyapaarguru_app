import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _period = 1;

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
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
              onTap: () => setState(() => _period = e.key),
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
          _kpi(ext, '₹28.4K', 'Revenue', null),
          const SizedBox(width: 8),
          _kpi(ext, '₹6.2K', 'Profit', AppColors.accent),
          const SizedBox(width: 8),
          _kpi(ext, '142', 'Orders', null),
        ]),
        const SizedBox(height: 12),
        // Bar chart
        _chartCard(ext, 'Daily Sales', 'This week · ₹28,400 total', SizedBox(
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
                return Text(days[v.toInt()], style: GoogleFonts.sourceCodePro(fontSize: 9, color: ext.fgMuted));
              })),
            ),
            barGroups: [45, 60, 38, 75, 90, 100, 55].asMap().entries.map((e) {
              return BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(toY: e.value.toDouble(), width: 20, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)), color: e.key == 5 ? AppColors.accentDk : ext.surface2),
              ]);
            }).toList(),
          )),
        )),
        // Line chart
        _chartCard(ext, 'Revenue Trend', 'Last 4 weeks · ↑ 14% growth', SizedBox(
          height: 80,
          child: LineChart(LineChartData(
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: const [FlSpot(0, 35), FlSpot(1, 45), FlSpot(2, 52), FlSpot(3, 60), FlSpot(4, 70), FlSpot(5, 82)],
                isCurved: true, color: AppColors.accent,
                barWidth: 2, dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: AppColors.accent.withValues(alpha: 0.1)),
              ),
            ],
          )),
        )),
        // Category donut
        _chartCard(ext, 'Sales by Category', 'This week', Row(children: [
          SizedBox(
            width: 80, height: 80,
            child: PieChart(PieChartData(
              sectionsSpace: 0, centerSpaceRadius: 16,
              sections: [
                PieChartSectionData(value: 40, color: const Color(0xFF00684A), radius: 14, showTitle: false),
                PieChartSectionData(value: 22, color: AppColors.blue, radius: 14, showTitle: false),
                PieChartSectionData(value: 18, color: AppColors.warn, radius: 14, showTitle: false),
                PieChartSectionData(value: 12, color: AppColors.danger, radius: 14, showTitle: false),
                PieChartSectionData(value: 8, color: ext.surface2, radius: 14, showTitle: false),
              ],
            )),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(children: [
            _legend(ext, const Color(0xFF00684A), 'Grocery', '40%'),
            _legend(ext, AppColors.blue, 'Beverages', '22%'),
            _legend(ext, AppColors.warn, 'Snacks', '18%'),
            _legend(ext, AppColors.danger, 'Personal Care', '12%'),
            _legend(ext, ext.surface2, 'Other', '8%'),
          ])),
        ])),
        // Top selling
        _chartCard(ext, 'Top Selling Items', 'By revenue this week', Column(children: [
          _topItem(ext, '#1', 'Fortune Sunflower Oil 1L', '₹4,350', 1.0),
          _topItem(ext, '#2', 'India Gate Basmati 1kg', '₹3,120', 0.72),
          _topItem(ext, '#3', 'Maggi Noodles 70g', '₹2,380', 0.55),
          _topItem(ext, '#4', 'Dove Soap 100g', '₹1,728', 0.40),
        ])),
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
