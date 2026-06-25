import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});
  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int _tab = 0;
  bool _showDetail = false;
  String _detailType = 'bill';

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Scaffold(
      appBar: _showDetail
          ? AppBar(leading: BackButton(onPressed: () => setState(() => _showDetail = false)), title: Text(_detailType == 'bill' ? 'Bill #1043' : 'Order #D-88'))
          : AppBar(leading: const BackButton(), title: const Text('Order History')),
      body: SafeArea(
        top: false,
        child: _showDetail ? _detail(ext) : Column(children: [
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
          Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: _tab == 0 ? _salesCards(ext) : _dealerCards(ext))),
        ]),
      ),
    );
  }

  List<Widget> _salesCards(AppThemeExtension ext) => [
    _orderCard(ext, 'BILL #1043', 'Priya Sharma', 'Tata Salt, Fortune Oil, Maggi × 2', '₹205', 'Today, 9:38 AM · WhatsApp sent', 'Paid', BadgeVariant.green, 'bill'),
    _orderCard(ext, 'BILL #1042', 'Walk-in Customer', 'Dove Soap, Coca-Cola × 3', '₹340', 'Today, 9:12 AM', 'Paid', BadgeVariant.green, 'bill'),
    _orderCard(ext, 'BILL #1041', 'Mohan Lal', 'India Gate Basmati 2kg, Fortune Oil × 2', '₹620', 'Yesterday, 6:45 PM', 'Pending', BadgeVariant.warn, 'bill'),
    _orderCard(ext, 'BILL #1040', 'Sunita Devi', 'Maggi × 5, Tata Salt, Dove Soap', '₹185', 'Yesterday, 4:20 PM · SMS sent', 'Paid', BadgeVariant.green, 'bill'),
  ];

  List<Widget> _dealerCards(AppThemeExtension ext) => [
    _orderCard(ext, 'ORDER #D-88', 'Sharma Traders', 'Tata Salt ×12, India Gate ×10, Coca-Cola ×24', '₹1,704', 'Today, 8:30 AM', 'Delivered', BadgeVariant.blue, 'dealer'),
    _orderCard(ext, 'ORDER #D-87', 'Gupta Wholesale', 'Maggi ×200, Coca-Cola ×48', '₹4,420', 'Yesterday, 3:00 PM · ETA: Tomorrow', 'In Transit', BadgeVariant.warn, 'dealer'),
    _orderCard(ext, 'ORDER #D-86', 'Sharma Traders', 'Fortune Oil ×30, Dove Soap ×50', '₹6,300', '11 May 2026', 'Delivered', BadgeVariant.blue, 'dealer'),
  ];

  Widget _orderCard(AppThemeExtension ext, String id, String name, String items, String total, String date, String status, BadgeVariant badge, String type) {
    return GestureDetector(
      onTap: () => setState(() { _showDetail = true; _detailType = type; }),
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
          Text(items, style: TextStyle(fontSize: 12, color: ext.fgMuted)),
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
    final isBill = _detailType == 'bill';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isBill ? 'Priya Sharma' : 'Sharma Traders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ext.fg)),
                Text(isBill ? '+91 98765 43210' : 'Grocery & FMCG Dealer', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
              ]),
              AppBadge(label: isBill ? 'Paid' : 'Delivered', variant: isBill ? BadgeVariant.green : BadgeVariant.blue),
            ]),
            const SizedBox(height: 6),
            Text(isBill ? 'BILL #1043 · 14 May 2026, 9:38 AM' : 'ORDER #D-88 · 14 May 2026, 8:30 AM', style: TextStyle(fontSize: 11, color: ext.fgMuted, letterSpacing: 1)),
          ]),
        ),
        const SizedBox(height: 12),
        SectionLabel(isBill ? 'Items' : 'Items Ordered'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
          child: Column(children: [
            if (isBill) ...[
              BillLine(label: 'Tata Salt 500g × 1', value: '₹22'),
              BillLine(label: 'Fortune Oil 1L × 1', value: '₹145'),
              BillLine(label: 'Maggi Noodles × 2', value: '₹28'),
              BillLine(label: 'GST (5%)', value: '₹10', valueColor: ext.fgMuted),
              BillLine(label: 'Total', value: '₹205', isTotal: true, valueColor: AppColors.accent),
            ] else ...[
              BillLine(label: 'Tata Salt 500g × 12', value: '₹216'),
              BillLine(label: 'India Gate Basmati × 10', value: '₹1,050'),
              BillLine(label: 'Coca-Cola 600ml × 24', value: '₹768'),
              BillLine(label: 'Total', value: '₹1,704', isTotal: true),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        SectionLabel(isBill ? 'Delivery' : 'Status'),
        TimelineWidget(items: isBill
            ? [const TimelineItem(label: 'Bill Created', time: '9:38 AM', done: true), const TimelineItem(label: 'Sent via WhatsApp', time: '9:38 AM', done: true), const TimelineItem(label: 'Payment Received', time: '9:40 AM · Cash', done: true)]
            : [const TimelineItem(label: 'Order Placed', time: '8:30 AM', done: true), const TimelineItem(label: 'Confirmed by Dealer', time: '8:45 AM', done: true), const TimelineItem(label: 'Out for Delivery', time: '9:00 AM', done: true), const TimelineItem(label: 'Delivered', time: '10:15 AM', done: true)]),
        if (isBill) AppButton(label: 'Resend Bill', full: true, outline: true, primary: false, onPressed: () {}),
      ]),
    );
  }
}
