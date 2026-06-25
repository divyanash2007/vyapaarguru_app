import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class SendBillScreen extends StatefulWidget {
  const SendBillScreen({super.key});
  @override
  State<SendBillScreen> createState() => _SendBillScreenState();
}

class _SendBillScreenState extends State<SendBillScreen> {
  int _selected = 0;
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Scaffold(
      appBar: _sent ? null : AppBar(leading: const BackButton(), title: const Text('Send Bill')),
      body: SafeArea(
        top: false,
        child: _sent ? _success(ext) : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionLabel('Bill Preview'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
              child: Column(children: [
                Text('Ramesh Kirana Store', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ext.fg)),
                Text('Main Market, Sector 12, Delhi · +91 98765 43210', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                const SizedBox(height: 6),
                Text('BILL #1043 · 14 May 2026, 9:41 AM', style: TextStyle(fontSize: 11, color: AppColors.accent, letterSpacing: 1)),
                Divider(color: ext.border, height: 24),
                _billRow(ext, 'Item', 'Qty', 'Amount', header: true),
                _billRow(ext, 'Tata Salt 500g', '1', '₹22'),
                _billRow(ext, 'Fortune Oil 1L', '1', '₹145'),
                _billRow(ext, 'Maggi Noodles 70g', '2', '₹28'),
                _billRow(ext, 'GST (5%)', '', '₹10', muted: true),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: ext.border))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ext.fg)),
                    const Text('₹205', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accent)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            const SectionLabel('Customer Phone'),
            TextField(
              style: TextStyle(fontSize: 15, color: ext.fg),
              controller: TextEditingController(text: '+91 98765 43210'),
              decoration: InputDecoration(filled: true, fillColor: ext.surface2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: ext.border)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11)),
            ),
            const SizedBox(height: 16),
            const SectionLabel('Send Via'),
            ...[
              ('WhatsApp', 'Send bill as message — most popular', Icons.message, const Color(0xFF25D366), true),
              ('SMS', 'Send bill summary via text message', Icons.phone, AppColors.blue, false),
              ('Email', 'Send PDF bill to customer\'s email', Icons.email, AppColors.warn, false),
              ('Print', 'Print on thermal / A4 printer', Icons.print, AppColors.accent, false),
            ].asMap().entries.map((e) {
              final i = e.key;
              final o = e.value;
              final sel = i == _selected;
              return GestureDetector(
                onTap: () => setState(() => _selected = i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.accent.withValues(alpha: 0.05) : ext.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? AppColors.accent : ext.border),
                  ),
                  child: Row(children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: o.$4.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: Icon(o.$3, size: 22, color: o.$4)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o.$1, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ext.fg)),
                      Text(o.$2, style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                    ])),
                    if (sel) const Icon(Icons.check, size: 18, color: AppColors.accent),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 8),
            AppButton(label: 'Send Bill Now', full: true, icon: const Icon(Icons.send, size: 16, color: Colors.white), onPressed: () => setState(() => _sent = true)),
          ]),
        ),
      ),
    );
  }

  Widget _billRow(AppThemeExtension ext, String c1, String c2, String c3, {bool header = false, bool muted = false}) {
    final style = TextStyle(fontSize: header ? 11 : 13, color: muted ? ext.fgMuted : ext.fg, fontWeight: header ? FontWeight.w600 : FontWeight.w400, letterSpacing: header ? 0.5 : 0);
    return Padding(padding: EdgeInsets.symmetric(vertical: header ? 6 : 5), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(c1, style: style)), SizedBox(width: 40, child: Text(c2, style: style, textAlign: TextAlign.center)), SizedBox(width: 60, child: Text(c3, style: style, textAlign: TextAlign.right))]));
  }

  Widget _success(AppThemeExtension ext) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withValues(alpha: 0.15)),
          child: const Icon(Icons.check, size: 36, color: AppColors.accent)),
        const SizedBox(height: 16),
        Text('Bill Sent!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ext.fg)),
        const SizedBox(height: 8),
        Text('Bill #1043 sent to\n+91 98765 43210 via WhatsApp', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: ext.fgMuted, height: 1.5)),
        const SizedBox(height: 24),
        AppButton(label: 'Back to Home', onPressed: () => Navigator.popUntil(context, (r) => r.isFirst)),
        const SizedBox(height: 8),
        AppButton(label: 'New Bill', outline: true, primary: false, onPressed: () => Navigator.pop(context)),
      ]),
    ));
  }
}
