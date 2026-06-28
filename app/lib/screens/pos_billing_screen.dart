import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/services/api_service.dart';

class _BillItem {
  int productId;
  String name;
  double sellingPrice;
  double tax;
  int qty;
  String? imageUrl;
  _BillItem({required this.productId, required this.name, required this.sellingPrice, this.tax = 0, required this.qty, this.imageUrl});
}

class PosBillingScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;
  const PosBillingScreen({super.key, this.onBackToDashboard});
  @override
  State<PosBillingScreen> createState() => _PosBillingScreenState();
}

class _PosBillingScreenState extends State<PosBillingScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService.instance;
  final _items = <_BillItem>[];
  final _searchCtrl = TextEditingController();
  final _gstCtrl = TextEditingController(text: '0');
  final _discountCtrl = TextEditingController(text: '0');
  bool _isSearching = false;
  bool _isSubmitting = false;
  bool _showManualSearch = false;
  List<Map<String, dynamic>> _searchResults = [];

  // Scanner
  MobileScannerController? _scannerController;
  late AnimationController _animCtrl;
  late Animation<double> _laserAnim;
  bool _torchOn = false;
  bool _scannerActive = true;
  Timer? _scannerTimeout;
  bool _isScanCooldown = false;
  int _cooldownSecondsLeft = 0;
  Timer? _cooldownTimer;

  // Badge
  String? _scannedItemName;
  bool _showScannedBadge = false;
  String? _lastScannedBarcode;
  DateTime? _lastScanTime;

  double get _sub => _items.fold(0.0, (s, i) => s + i.sellingPrice * i.qty);
  double get _gst => _sub * (double.tryParse(_gstCtrl.text) ?? 0.0) / 100;
  double get _effectiveDiscount => double.tryParse(_discountCtrl.text) ?? 0.0;
  double get _total => _items.isEmpty ? 0 : (_sub + _gst - _effectiveDiscount).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _laserAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
    _startScanner();
  }

  void _startScanner() {
    _scannerController?.dispose();
    _scannerController = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
    _scannerActive = true;
    _resetScannerTimeout();
  }

  void _resetScannerTimeout() {
    _scannerTimeout?.cancel();
    _scannerTimeout = Timer(const Duration(seconds: 10), () {
      if (mounted && _scannerActive) {
        _scannerController?.stop();
        setState(() => _scannerActive = false);
      }
    });
  }

  void _resumeScanner() {
    _startScanner();
    setState(() {});
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _scannerTimeout?.cancel();
    _cooldownTimer?.cancel();
    _scannerController?.dispose();
    _searchCtrl.dispose();
    _gstCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchProducts(String query) async {
    if (query.length < 2) { setState(() => _searchResults = []); return; }
    setState(() => _isSearching = true);
    try {
      final data = await _api.get('/inventory/', queryParams: {'search': query, 'per_page': '10'});
      if (!mounted) return;
      setState(() { _searchResults = (data['items'] as List<dynamic>).cast<Map<String, dynamic>>(); _isSearching = false; });
    } catch (_) { if (!mounted) return; setState(() => _isSearching = false); }
  }

  Future<void> _onBarcodeScanned(String barcode) async {
    if (_isScanCooldown) return;
    _resetScannerTimeout();
    try {
      final product = await _api.get('/products/barcode/$barcode');
      _addProductToBill(product);
      _triggerScannedBadge(product['name'] ?? 'Item');
      _startScanCooldown();
    } on ApiException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product with barcode $barcode not found'), backgroundColor: AppColors.danger, duration: const Duration(seconds: 2)));
    } catch (_) {}
  }

  void _startScanCooldown() {
    _cooldownTimer?.cancel();
    setState(() {
      _isScanCooldown = true;
      _cooldownSecondsLeft = 5;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_cooldownSecondsLeft <= 1) {
        setState(() {
          _isScanCooldown = false;
          _cooldownSecondsLeft = 0;
        });
        timer.cancel();
      } else {
        setState(() {
          _cooldownSecondsLeft--;
        });
      }
    });
  }

  void _triggerScannedBadge(String name) {
    setState(() { _scannedItemName = name; _showScannedBadge = true; });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _scannedItemName == name) setState(() => _showScannedBadge = false);
    });
  }

  Future<void> _addProductToBill(Map<String, dynamic> product) async {
    final productId = product['id'] as int;
    final existing = _items.where((i) => i.productId == productId).toList();
    if (existing.isNotEmpty) {
      setState(() { existing.first.qty++; _searchCtrl.clear(); _searchResults = []; });
      return;
    }
    try {
      final inv = await _api.get('/inventory/$productId');
      final sellingPrice = double.tryParse(inv['selling_price'].toString()) ?? double.tryParse(product['mrp'].toString()) ?? 0.0;
      final tax = double.tryParse(product['tax']?.toString() ?? '5') ?? 5.0;
      final imageUrl = product['img_url'] as String? ?? product['image_url'] as String?;
      if (!mounted) return;
      setState(() {
        _items.add(_BillItem(productId: productId, name: product['name'] ?? 'Unknown', sellingPrice: sellingPrice, tax: tax, qty: 1, imageUrl: imageUrl));
        _searchCtrl.clear(); _searchResults = []; _showManualSearch = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
    }
  }

  Future<void> _checkout(String paymentMethod) async {
    if (_items.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      final saleData = await _api.post('/sales/', body: {
        'discount': _effectiveDiscount, 'tax': _gst, 'payment_method': paymentMethod,
        'items': _items.map((i) => {'product_id': i.productId, 'qty': i.qty, 'discount': 0, 'tax': i.tax}).toList(),
        'payments': [{'amount': _total, 'method': paymentMethod}],
      });
      if (!mounted) return;
      setState(() { _isSubmitting = false; _items.clear(); });
      Navigator.pushNamed(context, '/send-bill', arguments: saleData);
    } on ApiException catch (e) {
      if (!mounted) return; setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
    } catch (_) {
      if (!mounted) return; setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create sale.'), backgroundColor: AppColors.danger));
    }
  }

  IconData _getProductIcon(String name) {
    final l = name.toLowerCase();
    if (l.contains('biscuit') || l.contains('cookie') || l.contains('oreo')) return Icons.cookie;
    if (l.contains('milk') || l.contains('dairy') || l.contains('drink')) return Icons.local_drink;
    if (l.contains('ice cream') || l.contains('vanilla')) return Icons.icecream;
    if (l.contains('chips') || l.contains('snack')) return Icons.fastfood;
    if (l.contains('notebook') || l.contains('pen') || l.contains('book')) return Icons.menu_book;
    return Icons.shopping_bag;
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;

    return Scaffold(
      backgroundColor: ext.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ─── HEADER ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                IconButton(icon: Icon(Icons.arrow_back, color: ext.fg), onPressed: widget.onBackToDashboard),
                Text('New Bill', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ext.fg)),
                const Spacer(),
                IconButton(
                  icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off, color: ext.fg),
                  onPressed: () { _scannerController?.toggleTorch(); setState(() => _torchOn = !_torchOn); },
                ),
                IconButton(icon: Icon(Icons.settings_outlined, color: ext.fg), onPressed: () => Navigator.pushNamed(context, '/settings')),
              ]),
            ),

            // ─── CAMERA (hidden when manual search is active) ───
            if (!_showManualSearch)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Stack(children: [
                      // Scanner or paused overlay
                      if (_scannerActive && _scannerController != null)
                        MobileScanner(
                          controller: _scannerController!,
                          onDetect: (capture) {
                            if (_isScanCooldown) return;
                            final barcodes = capture.barcodes;
                            if (barcodes.isNotEmpty) {
                              final code = barcodes.first.rawValue;
                              if (code != null && code.isNotEmpty) {
                                final now = DateTime.now();
                                if (_lastScannedBarcode == code && _lastScanTime != null && now.difference(_lastScanTime!).inMilliseconds < 2000) return;
                                _lastScannedBarcode = code; _lastScanTime = now;
                                _onBarcodeScanned(code);
                              }
                            }
                          },
                        )
                      else
                        GestureDetector(
                          onTap: _resumeScanner,
                          child: Container(
                            color: ext.surface,
                            child: const Center(
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.touch_app, size: 36, color: AppColors.accent),
                                SizedBox(height: 8),
                                Text('Tap to scan', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Text('Scanner paused to save battery', style: TextStyle(color: Colors.white38, fontSize: 11)),
                              ]),
                            ),
                          ),
                        ),

                      // LIVE / COOLDOWN badge
                      if (_scannerActive)
                        Positioned(top: 12, left: 12, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isScanCooldown ? Colors.black87 : Colors.black54,
                            borderRadius: BorderRadius.circular(100),
                            border: _isScanCooldown ? Border.all(color: AppColors.accent.withValues(alpha: 0.5)) : null,
                          ),
                          child: Row(children: [
                            if (_isScanCooldown)
                              const Icon(Icons.hourglass_empty, size: 10, color: AppColors.accent)
                            else
                              const Icon(Icons.circle, size: 8, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              _isScanCooldown ? 'PAUSED (${_cooldownSecondsLeft}s)' : 'LIVE',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ]),
                        )),

                      // Right buttons
                      Positioned(top: 12, right: 12, bottom: 12, child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _fab(_torchOn ? Icons.flash_on : Icons.flash_off, () { _scannerController?.toggleTorch(); setState(() => _torchOn = !_torchOn); }),
                          _fab(Icons.image_outlined, () {}),
                          _fab(_showManualSearch ? Icons.search_off : Icons.search, () => setState(() => _showManualSearch = !_showManualSearch)),
                        ],
                      )),

                      // Scan reticle with laser
                      if (_scannerActive)
                        Positioned.fill(child: Center(child: Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: _isScanCooldown ? Colors.white10 : Colors.white24, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(children: [
                            if (!_isScanCooldown)
                              AnimatedBuilder(animation: _laserAnim, builder: (_, __) => Positioned(
                                top: _laserAnim.value * 120, left: 4, right: 4,
                                child: Container(height: 2, decoration: BoxDecoration(color: AppColors.success, boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.8), blurRadius: 4)])),
                              )),
                          ]),
                        ))),

                      // Scanned badge
                      if (_showScannedBadge && _scannedItemName != null)
                        Positioned(bottom: 12, left: 16, right: 16, child: Center(child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(100), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 14),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '$_scannedItemName added',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                        ))),
                    ]),
                  ),
                ),
              ),

            // ─── MANUAL SEARCH (collapsible) ───
            if (_showManualSearch)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border)),
                child: Column(children: [
                  Row(children: [
                    Icon(Icons.search, size: 16, color: ext.fgMuted),
                    const SizedBox(width: 6),
                    Text('Manual Search', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.fgMuted)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() { _showManualSearch = false; _searchCtrl.clear(); _searchResults = []; }),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: ext.surface2, shape: BoxShape.circle),
                        child: Icon(Icons.videocam, size: 16, color: AppColors.accent),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchCtrl, style: TextStyle(fontSize: 14, color: ext.fg),
                    decoration: InputDecoration(
                      hintText: 'Type item name or barcode...', hintStyle: TextStyle(color: ext.fgMuted),
                      filled: true, fillColor: ext.surface2, isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: ext.border)),
                      suffixIcon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)) : null,
                    ),
                    onChanged: _searchProducts,
                  ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4), constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(color: ext.surface2, borderRadius: BorderRadius.circular(8), border: Border.all(color: ext.border)),
                      child: ListView.builder(shrinkWrap: true, itemCount: _searchResults.length, itemBuilder: (_, i) {
                        final invItem = _searchResults[i];
                        final p = invItem['product'] as Map<String, dynamic>? ?? {};
                        final sellingPrice = invItem['selling_price'] ?? p['mrp'] ?? 0.0;
                        return ListTile(
                          dense: true,
                          title: Text(p['name'] ?? '', style: TextStyle(fontSize: 13, color: ext.fg)),
                          subtitle: Text('Price: ₹$sellingPrice', style: TextStyle(fontSize: 11, color: ext.fgMuted)),
                          onTap: () => _addProductToBill(p),
                        );
                      }),
                    ),
                ]),
              ),

            // ─── SCANNED ITEMS HEADER ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(children: [
                Text('Scanned Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ext.fg)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: ext.surface2, borderRadius: BorderRadius.circular(100)),
                  child: Text('${_items.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ext.fgMuted)),
                ),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('TOTAL PRICE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: ext.fgMuted)),
                  Text('₹${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.accent)),
                ]),
              ]),
            ),

            // ─── ITEM LIST ───
            Expanded(
              child: _items.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.qr_code_scanner, size: 40, color: ext.fgMuted.withValues(alpha: 0.2)),
                      const SizedBox(height: 10),
                      Text('Scan product barcode to start billing', style: TextStyle(fontSize: 13, color: ext.fgMuted)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        final itemTotal = item.sellingPrice * item.qty;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(color: ext.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.border.withValues(alpha: 0.4))),
                          child: Row(children: [
                            // Thumbnail
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: ext.surface2, borderRadius: BorderRadius.circular(8)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        item.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Icon(_getProductIcon(item.name), color: AppColors.accent, size: 22),
                                      )
                                    : Icon(_getProductIcon(item.name), color: AppColors.accent, size: 22),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Name + price — use Expanded so text gets room
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ext.fg), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('₹${item.sellingPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: ext.fgMuted)),
                            ])),
                            const SizedBox(width: 8),
                            // Qty stepper
                            Container(
                              decoration: BoxDecoration(color: ext.surface2, borderRadius: BorderRadius.circular(8), border: Border.all(color: ext.border.withValues(alpha: 0.5))),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                _stepperBtn(Icons.remove, () => setState(() { if (item.qty > 1) item.qty--; else _items.removeAt(i); }), ext),
                                Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('${item.qty}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ext.fg))),
                                _stepperBtn(Icons.add, () => setState(() => item.qty++), ext),
                              ]),
                            ),
                            const SizedBox(width: 8),
                            // Total
                            SizedBox(width: 58, child: Text('₹${itemTotal.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.accent))),
                            // Delete
                            SizedBox(width: 28, child: IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: Icon(Icons.close, size: 16, color: ext.fgMuted), onPressed: () => setState(() => _items.removeAt(i)))),
                          ]),
                        );
                      },
                    ),
            ),

            // ─── SUMMARY + BUTTONS ───
            if (!_showManualSearch)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(color: ext.surface, border: Border(top: BorderSide(color: ext.border.withValues(alpha: 0.3)))),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(
                    children: [
                      Text('Subtotal', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                      const Spacer(),
                      Text('₹${_sub.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: ext.fg)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('GST (%)', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        height: 24,
                        child: TextField(
                          controller: _gstCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: ext.fg),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: ext.surface2,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: ext.border.withValues(alpha: 0.3))),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const Spacer(),
                      Text('₹${_gst.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: ext.fg)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Discount (₹)', style: TextStyle(fontSize: 12, color: ext.fgMuted)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        height: 24,
                        child: TextField(
                          controller: _discountCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: ext.fg),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: ext.surface2,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: ext.border.withValues(alpha: 0.3))),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const Spacer(),
                      Text('-₹${_effectiveDiscount.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: ext.fg)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ext.fg)),
                    Text('₹${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.accent)),
                  ]),
                  const SizedBox(height: 10),
                  _isSubmitting
                      ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                      : Row(children: [
                          Expanded(child: InkWell(
                            borderRadius: BorderRadius.circular(100),
                            onTap: _items.isEmpty ? null : () => _checkout('cash'),
                            child: Container(
                              height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), border: Border.all(color: _items.isEmpty ? ext.border.withValues(alpha: 0.3) : ext.border.withValues(alpha: 0.6))),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.send_outlined, size: 16, color: _items.isEmpty ? ext.fgMuted : ext.fg),
                                const SizedBox(width: 8),
                                Text('Send Bill', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _items.isEmpty ? ext.fgMuted : ext.fg)),
                              ]),
                            ),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: GestureDetector(
                            onTap: _items.isEmpty ? null : () => _checkout('cash'),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(color: _items.isEmpty ? AppColors.accent.withValues(alpha: 0.3) : AppColors.accent, borderRadius: BorderRadius.circular(100)),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.credit_card, size: 16, color: Colors.white), const SizedBox(width: 8),
                                Text('Collect ₹${_total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                              ]),
                            ),
                          )),
                        ]),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fab(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 36, height: 36, decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 17)),
  );

  Widget _stepperBtn(IconData icon, VoidCallback onTap, AppThemeExtension ext) => InkWell(
    onTap: onTap,
    child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 14, color: ext.fg)),
  );
}
