import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/theme_provider.dart';
import '../core/providers/auth_provider.dart';
import '../widgets/shared_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    final tp = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    final ownerName = auth.ownerName.isNotEmpty ? auth.ownerName : 'User';
    final initial = ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'U';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Profile card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(colors: [ext.surface, AppColors.accent.withValues(alpha: 0.12)]),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Container(width: 56, height: 56, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accentDk),
              child: Center(child: Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ownerName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ext.fg)),
              Text(auth.phoneNo.isNotEmpty ? '+91 ${auth.phoneNo}' : '', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
              const SizedBox(height: 6),
              const AppBadge(label: 'Pro Plan'),
            ])),
            Icon(Icons.edit_outlined, size: 18, color: ext.fgMuted),
          ]),
        ),
        const SizedBox(height: 16),
        // Appearance
        const SectionLabel('Appearance'),
        _group(ext, [
          _row(ext, Icons.dark_mode, AppColors.blue, 'Dark Mode', null, trailing: ToggleSwitch(value: tp.isDark, onChanged: (_) => tp.toggle())),
        ]),
        const SizedBox(height: 16),
        // Shop details
        const SectionLabel('Shop Details'),
        _group(ext, [
          _row(ext, Icons.home_outlined, AppColors.blue, 'Shop Name', auth.shopName.isNotEmpty ? auth.shopName : 'Not set'),
          _row(ext, Icons.location_on_outlined, AppColors.warn, 'Address', auth.address.isNotEmpty ? auth.address : 'Not set'),
          _row(ext, Icons.description_outlined, AppColors.accent, 'GST Number', auth.gstNo ?? 'Not set'),
        ]),
        const SizedBox(height: 16),
        // Billing
        const SectionLabel('Billing'),
        _group(ext, [
          _row(ext, Icons.credit_card, AppColors.accent, 'Default Tax Rate', null, trailing: Text('5% GST', style: TextStyle(fontSize: 13, color: ext.fgMuted))),
          _row(ext, Icons.phone, AppColors.blue, 'Auto-send Bill', 'Send via WhatsApp after payment', trailing: const ToggleSwitch(value: true)),
          _row(ext, Icons.print, AppColors.warn, 'Printer Setup', 'Thermal printer not connected'),
        ]),
        const SizedBox(height: 16),
        // Notifications
        const SectionLabel('Notifications'),
        _group(ext, [
          _row(ext, null, null, 'Low Stock Alerts', null, trailing: const ToggleSwitch(value: true)),
          _row(ext, null, null, 'Daily Sales Summary', null, trailing: const ToggleSwitch(value: true)),
          _row(ext, null, null, 'AI Suggestions', null, trailing: const ToggleSwitch(value: true)),
          _row(ext, null, null, 'Dealer Order Updates', null, trailing: const ToggleSwitch(value: false)),
        ]),
        const SizedBox(height: 16),
        // Plan
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.star_outline, size: 22, color: AppColors.accent)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pro Plan — Active', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ext.fg)),
              Text('Unlimited bills · AI suggestions · Analytics', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
            ])),
            const AppBadge(label: '₹299/mo'),
          ]),
        ),
        const SizedBox(height: 16),
        // Logout
        GestureDetector(
          onTap: () async {
            final authProvider = context.read<AuthProvider>();
            await authProvider.logout();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.logout, size: 18, color: AppColors.danger),
              SizedBox(width: 8),
              Text('Log Out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.danger)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _group(AppThemeExtension ext, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
      child: Column(children: children),
    );
  }

  Widget _row(AppThemeExtension ext, IconData? icon, Color? iconColor, String title, String? subtitle, {Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ext.border.withValues(alpha: 0.5)))),
      child: Row(children: [
        if (icon != null) ...[
          Container(width: 36, height: 36, decoration: BoxDecoration(color: (iconColor ?? ext.fgMuted).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 18, color: iconColor)),
          const SizedBox(width: 12),
        ],
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ext.fg)),
          if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 12, color: ext.fgMuted)),
        ])),
        if (trailing != null) trailing else Icon(Icons.chevron_right, size: 16, color: ext.fgMuted),
      ]),
    );
  }
}
