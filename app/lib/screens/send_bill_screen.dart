import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/auth_provider.dart';
import '../widgets/shared_widgets.dart';

class SendBillScreen extends StatefulWidget {
  const SendBillScreen({super.key});
  @override
  State<SendBillScreen> createState() => _SendBillScreenState();
}

class _SendBillScreenState extends State<SendBillScreen> {
  late TextEditingController _phoneController;
  int _selected = 0;
  bool _sent = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final saleData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final customerPhone = saleData?['customer']?['phone'] ?? '';
      if (customerPhone.isNotEmpty) {
        _phoneController.text = customerPhone;
      }
      _initialized = true;
    }
  }

  Future<void> _sendBill() async {
    final saleData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final billId = saleData?['id']?.toString() ?? '—';
    final grandTotal = saleData?['grand_total']?.toString() ?? '0';
    final createdAt = saleData?['created_at'] != null
        ? DateTime.tryParse(saleData!['created_at'])
        : DateTime.now();
    final dateStr = createdAt != null
        ? '${createdAt.day} ${_monthName(createdAt.month)} ${createdAt.year}, ${_timeStr(createdAt)}'
        : '';
    final items = (saleData?['items'] as List<dynamic>?) ?? [];
    final tax = saleData?['tax']?.toString() ?? '0';

    if (_selected == 0) { // WhatsApp
      final rawPhone = _phoneController.text.trim();
      final phoneDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
      if (phoneDigits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid customer phone number'), backgroundColor: AppColors.danger),
        );
        return;
      }
      final finalPhone = phoneDigits.length == 10 ? '91$phoneDigits' : phoneDigits;

      final auth = context.read<AuthProvider>();
      final shopName = auth.shopName.isNotEmpty ? auth.shopName : 'Our Shop';
      final buffer = StringBuffer();
      buffer.writeln('*$shopName*');
      buffer.writeln('BILL #$billId');
      buffer.writeln('Date: $dateStr');
      buffer.writeln('--------------------------------');
      for (final item in items) {
        final productName = item['product']?['name'] ?? 'Item';
        final qty = item['qty']?.toString() ?? '1';
        final unitPrice = double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0;
        final itemQty = int.tryParse(qty) ?? 1;
        final totalAmt = unitPrice * itemQty;
        buffer.writeln('$productName x$qty - ₹${totalAmt.toStringAsFixed(0)}');
      }
      if (double.tryParse(tax) != null && double.tryParse(tax)! > 0) {
        buffer.writeln('Tax: ₹$tax');
      }
      buffer.writeln('--------------------------------');
      buffer.writeln('*Total: ₹$grandTotal*');
      buffer.writeln('Thank you for shopping with us!');

      final url = Uri.parse('https://wa.me/$finalPhone?text=${Uri.encodeComponent(buffer.toString())}');
      final fallbackUrl = Uri.parse('whatsapp://send?phone=$finalPhone&text=${Uri.encodeComponent(buffer.toString())}');

      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else if (await canLaunchUrl(fallbackUrl)) {
          await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
        } else {
          // Bypasses some OS-level package restrictions on newer Android/iOS versions
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch WhatsApp: $e'), backgroundColor: AppColors.danger),
        );
        return;
      }
    }

    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    final auth = context.watch<AuthProvider>();

    // Get sale data from route arguments
    final saleData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Extract data from sale response or fallback
    final billId = saleData?['id']?.toString() ?? '—';
    final grandTotal = saleData?['grand_total']?.toString() ?? '0';
    final createdAt = saleData?['created_at'] != null
        ? DateTime.tryParse(saleData!['created_at'])
        : DateTime.now();
    final dateStr = createdAt != null
        ? '${createdAt.day} ${_monthName(createdAt.month)} ${createdAt.year}, ${_timeStr(createdAt)}'
        : '';
    final items = (saleData?['items'] as List<dynamic>?) ?? [];
    final tax = saleData?['tax']?.toString() ?? '0';

    return Scaffold(
      appBar: _sent ? null : AppBar(leading: const BackButton(), title: const Text('Send Bill')),
      body: SafeArea(
        top: false,
        child: _sent ? _success(ext, billId, _phoneController.text) : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionLabel('Bill Preview'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
              child: Column(children: [
                Text(auth.shopName.isNotEmpty ? auth.shopName : 'Your Shop', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ext.fg)),
                Text('${auth.address}${auth.phoneNo.isNotEmpty ? ' · +91 ${auth.phoneNo}' : ''}', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                const SizedBox(height: 6),
                Text('BILL #$billId · $dateStr', style: TextStyle(fontSize: 11, color: AppColors.accent, letterSpacing: 1)),
                Divider(color: ext.border, height: 24),
                _billRow(ext, 'Item', 'Qty', 'Amount', header: true),
                ...items.map((item) {
                  final productName = item['product']?['name'] ?? 'Item';
                  final qty = item['qty']?.toString() ?? '1';
                  final unitPrice = double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0;
                  final itemQty = int.tryParse(qty) ?? 1;
                  return _billRow(ext, productName, qty, '₹${(unitPrice * itemQty).toStringAsFixed(0)}');
                }),
                _billRow(ext, 'Tax', '', '₹$tax', muted: true),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: ext.border))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ext.fg)),
                    Text('₹$grandTotal', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accent)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            const SectionLabel('Customer Phone'),
            TextField(
              style: TextStyle(fontSize: 15, color: ext.fg),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
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
            AppButton(label: 'Send Bill Now', full: true, icon: const Icon(Icons.send, size: 16, color: Colors.white), onPressed: _sendBill),
          ]),
        ),
      ),
    );
  }

  Widget _billRow(AppThemeExtension ext, String c1, String c2, String c3, {bool header = false, bool muted = false}) {
    final style = TextStyle(fontSize: header ? 11 : 13, color: muted ? ext.fgMuted : ext.fg, fontWeight: header ? FontWeight.w600 : FontWeight.w400, letterSpacing: header ? 0.5 : 0);
    return Padding(padding: EdgeInsets.symmetric(vertical: header ? 6 : 5), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(c1, style: style)), SizedBox(width: 40, child: Text(c2, style: style, textAlign: TextAlign.center)), SizedBox(width: 60, child: Text(c3, style: style, textAlign: TextAlign.right))]));
  }

  Widget _success(AppThemeExtension ext, String billId, String phone) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withValues(alpha: 0.15)),
          child: const Icon(Icons.check, size: 36, color: AppColors.accent)),
        const SizedBox(height: 16),
        Text('Bill Sent!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ext.fg)),
        const SizedBox(height: 8),
        Text('Bill #$billId sent${phone.isNotEmpty ? ' to\n$phone' : ''} via WhatsApp', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: ext.fgMuted, height: 1.5)),
        const SizedBox(height: 24),
        AppButton(label: 'Back to Home', onPressed: () => Navigator.popUntil(context, (r) => r.isFirst)),
        const SizedBox(height: 8),
        AppButton(label: 'New Bill', outline: true, primary: false, onPressed: () => Navigator.pop(context)),
      ]),
    ));
  }

  String _monthName(int m) => const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];
  String _timeStr(DateTime d) => '${d.hour}:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
}
