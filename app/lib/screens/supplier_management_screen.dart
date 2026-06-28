import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/services/api_service.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/add_supplier_bottom_sheet.dart';

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() => _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen> {
  final _api = ApiService.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.get('/suppliers/');
      if (!mounted) return;
      setState(() {
        _suppliers = (data as List<dynamic>).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load suppliers'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _addSupplier() async {
    final result = await AddSupplierBottomSheet.show(context);
    if (result != null) {
      _loadSuppliers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Supplier "${result['name']}" added!'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _editSupplier(Map<String, dynamic> supplier) async {
    final result = await AddSupplierBottomSheet.show(context, supplier: supplier);
    if (result != null) {
      _loadSuppliers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Supplier "${result['name']}" updated!'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> supplier) async {
    final ext = context.appTheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ext.surface,
        title: Text('Delete Supplier?', style: TextStyle(color: ext.fg)),
        content: Text(
          'Are you sure you want to delete "${supplier['name']}"? This action cannot be undone.',
          style: TextStyle(color: ext.fgMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: ext.fgMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.delete('/suppliers/${supplier['id']}');
        _loadSuppliers();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supplier deleted'), backgroundColor: AppColors.success),
        );
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete supplier'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;

    return Scaffold(
      backgroundColor: ext.bg,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Manage Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_outlined),
            onPressed: _addSupplier,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : _suppliers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 64,
                            color: ext.fgMuted.withValues(alpha: 0.15),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No suppliers registered',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ext.fg),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add suppliers to order stock and manage dealer purchases directly.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: ext.fgMuted),
                          ),
                          const SizedBox(height: 20),
                          AppButton(
                            label: 'Add First Supplier',
                            onPressed: _addSupplier,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _suppliers.length,
                    itemBuilder: (context, idx) {
                      final supplier = _suppliers[idx];
                      final name = supplier['name'] ?? 'Supplier';
                      final phone = supplier['phone'] ?? '';
                      final address = supplier['address'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ext.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ext.border),
                        ),
                        child: Row(
                          children: [
                            // Avatar Icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: ext.surface2,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text('🏪', style: TextStyle(fontSize: 18)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: ext.fg,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  if (phone.isNotEmpty)
                                    Text(
                                      phone,
                                      style: TextStyle(fontSize: 12, color: ext.fgMuted),
                                    ),
                                  if (address.isNotEmpty)
                                    Text(
                                      address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: ext.fgMuted),
                                    ),
                                ],
                              ),
                            ),
                            // Action buttons
                            IconButton(
                              icon: Icon(Icons.edit_outlined, size: 18, color: ext.fgMuted),
                              onPressed: () => _editSupplier(supplier),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                              onPressed: () => _confirmDelete(supplier),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
