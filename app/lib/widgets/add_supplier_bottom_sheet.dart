import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/services/api_service.dart';
import 'shared_widgets.dart';

class AddSupplierBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? supplier;

  const AddSupplierBottomSheet({super.key, this.supplier});

  /// Static helper to show the bottom sheet and return the created/updated supplier
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    Map<String, dynamic>? supplier,
  }) async {
    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSupplierBottomSheet(supplier: supplier),
    );
  }

  @override
  State<AddSupplierBottomSheet> createState() => _AddSupplierBottomSheetState();
}

class _AddSupplierBottomSheetState extends State<AddSupplierBottomSheet> {
  final _api = ApiService.instance;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEdit => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.supplier?['name'] ?? '');
    _phoneCtrl = TextEditingController(text: widget.supplier?['phone'] ?? '');
    _addressCtrl = TextEditingController(text: widget.supplier?['address'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Supplier name is required');
      return;
    }

    if (phone.isNotEmpty && phone.length != 10) {
      setState(() => _errorMessage = 'Phone number must be exactly 10 digits');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final body = {
        'name': name,
        'phone': phone.isEmpty ? null : phone,
        'address': address.isEmpty ? null : address,
      };

      Map<String, dynamic> result;
      if (_isEdit) {
        final id = widget.supplier!['id'];
        result = await _api.put('/suppliers/$id', body: body);
      } else {
        result = await _api.post('/suppliers/', body: body);
      }

      if (!mounted) return;
      Navigator.pop(context, result);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'An unexpected error occurred';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: 20 + viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: ext.border),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handlebar indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ext.fgMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Text(
              _isEdit ? 'Edit Supplier' : 'Add New Supplier',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ext.fg,
              ),
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null)
              AlertBanner(
                text: _errorMessage!,
                variant: AlertVariant.red,
                leading: const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
              ),

            // Form Fields
            AppInput(
              label: 'Supplier/Business Name',
              hint: 'e.g., Sharma Traders',
              controller: _nameCtrl,
            ),
            AppInput(
              label: 'Phone Number (Optional)',
              hint: 'e.g., 9876543210',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
            ),
            AppInput(
              label: 'Address (Optional)',
              hint: 'e.g., G-14, Main Market, Sector 15',
              controller: _addressCtrl,
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Buttons
            _isSubmitting
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Cancel',
                          outline: true,
                          primary: false,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: _isEdit ? 'Save Changes' : 'Add Supplier',
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
