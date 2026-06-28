import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'pos_billing_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _idx = 0;

  List<Widget> get _screens => [
    DashboardScreen(onSwitchToBilling: () => setState(() => _idx = 2)),
    const InventoryScreen(),
    PosBillingScreen(onBackToDashboard: () => setState(() => _idx = 0)),
    const AnalyticsScreen(),
    const SettingsScreen(),
  ];

  static const _titles = ['', 'Inventory', 'New Bill', 'Analytics', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Scaffold(
      appBar: (_idx == 0 || _idx == 2)
          ? null
          : AppBar(
              title: Text(_titles[_idx]),
              actions: _idx == 1
                  ? [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/add-product'),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentDk,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          ),
                        ),
                      ),
                    ]
                  : _idx == 3
                      ? [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/ai'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.auto_awesome, size: 14, color: AppColors.accent),
                                  const SizedBox(width: 4),
                                  const Text('AI Tips', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                                ]),
                              ),
                            ),
                          ),
                        ]
                      : null,
            ),
      body: SafeArea(
        top: _idx == 0,
        child: IndexedStack(index: _idx, children: _screens),
      ),
      bottomNavigationBar: _idx == 2 ? null : Container(
        decoration: BoxDecoration(
          color: ext.surface,
          border: Border(top: BorderSide(color: ext.border)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home, Icons.home_outlined, 'Home'),
                _navItem(1, Icons.inventory_2, Icons.inventory_2_outlined, 'Inventory'),
                _navItem(2, Icons.computer, Icons.computer_outlined, 'Billing'),
                _navItem(3, Icons.bar_chart, Icons.bar_chart_outlined, 'Analytics'),
                _navItem(4, Icons.settings, Icons.settings_outlined, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData activeIcon, IconData icon, String label) {
    final active = _idx == idx;
    final ext = context.appTheme;
    return GestureDetector(
      onTap: () => setState(() => _idx = idx),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon, size: 22, color: active ? AppColors.accent : ext.fgMuted),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: active ? AppColors.accent : ext.fgMuted)),
          ],
        ),
      ),
    );
  }
}
