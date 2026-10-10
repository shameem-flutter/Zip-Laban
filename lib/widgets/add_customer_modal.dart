import 'dart:math';
import 'package:flutter/material.dart';
import '../models/odoo_customer.dart';
import '../services/customer_service.dart';
import '../theme/app_colors.dart';

class AddCustomerModal extends StatefulWidget {
  const AddCustomerModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddCustomerModal(),
    );
  }

  @override
  State<AddCustomerModal> createState() => _AddCustomerModalState();
}

class _AddCustomerModalState extends State<AddCustomerModal> {
  final _formKey = GlobalKey<FormState>();

  final _customerIdController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _streetController = TextEditingController(text: 'Commercial Avenue');
  final _street2Controller = TextEditingController(text: 'Suite 204');
  final _cityController = TextEditingController(text: 'Calicut');
  final _zipController = TextEditingController(text: '673001');
  final _vatController = TextEditingController();
  final _balanceController = TextEditingController(text: '400.0');

  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _generateRandomIdAndMobile();
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _customerNameController.dispose();
    _mobileController.dispose();
    _streetController.dispose();
    _street2Controller.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _vatController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _generateRandomIdAndMobile() {
    final rand = Random();
    final randomId = (100000 + rand.nextInt(900000)).toString();
    final randomMobile = '98${10000000 + rand.nextInt(90000000)}';
    _customerIdController.text = randomId;
    if (_mobileController.text.isEmpty) {
      _mobileController.text = randomMobile;
    }
  }



  Future<void> _submitCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final input = CreateCustomerInput(
      customerId: _customerIdController.text.trim(),
      customerName: _customerNameController.text.trim(),
      mobile: _mobileController.text.trim(),
      street: _streetController.text.trim(),
      street2: _street2Controller.text.trim(),
      city: _cityController.text.trim(),
      zip: _zipController.text.trim(),
      vat: _vatController.text.trim(),
      openBalance: double.tryParse(_balanceController.text.trim()) ?? 0.0,
    );

    final result = await CustomerService().createCustomer(input);

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      if (result.success) {
        _successMessage =
            result.msg ?? '${input.customerName} created Successfully';
      } else {
        _errorMessage = result.msg ?? 'Failed to create customer in Odoo';
      }
    });

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _successMessage!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Auto dismiss modal on success after brief pause
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F56D9), Color(0xFF0038A8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Add Customer',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Profile & Contact Details',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F56D9),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Form Body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // Error Banner if Odoo rejected the payload
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Validation Error',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      color: Color(0xFFB91C1C),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF7F1D1D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Success Banner
                    if (_successMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF059669),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Customer Name
                    _buildLabel('Customer Name *'),
                    TextFormField(
                      controller: _customerNameController,
                      decoration: _buildInputDecoration(
                        hint: 'e.g. Test Customer 2',
                        icon: Icons.person_outline_rounded,
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter customer name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Mobile & Customer ID
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Mobile Phone *'),
                              TextFormField(
                                controller: _mobileController,
                                keyboardType: TextInputType.phone,
                                decoration: _buildInputDecoration(
                                  hint: '9847012345',
                                  icon: Icons.phone_outlined,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Phone number required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Customer ID *'),
                              TextFormField(
                                controller: _customerIdController,
                                decoration: _buildInputDecoration(
                                  hint: '000001',
                                  icon: Icons.badge_outlined,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Opening Balance & VAT
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Opening Balance (₹ / SAR)'),
                              TextFormField(
                                controller: _balanceController,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: _buildInputDecoration(
                                  hint: '400',
                                  icon: Icons.account_balance_wallet_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Tax / VAT (Optional)'),
                              TextFormField(
                                controller: _vatController,
                                decoration: _buildInputDecoration(
                                  hint: 'Leave blank if none',
                                  icon: Icons.receipt_long_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Street & Street 2
                    _buildLabel('Street Address'),
                    TextFormField(
                      controller: _streetController,
                      decoration: _buildInputDecoration(
                        hint: 'e.g. Street 1',
                        icon: Icons.location_on_outlined,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildLabel('Street Line 2'),
                    TextFormField(
                      controller: _street2Controller,
                      decoration: _buildInputDecoration(
                        hint: 'e.g. Street 2 / Floor / Suite',
                        icon: Icons.signpost_outlined,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // City & Zip
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('City'),
                              TextFormField(
                                controller: _cityController,
                                decoration: _buildInputDecoration(
                                  hint: 'e.g. Calicut',
                                  icon: Icons.location_city_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Postal / ZIP'),
                              TextFormField(
                                controller: _zipController,
                                decoration: _buildInputDecoration(
                                  hint: '12345',
                                  icon: Icons.pin_drop_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Submit Action Button
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F56D9), Color(0xFF0038A8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F56D9)
                                .withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitCustomer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Saving Customer...',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded,
                                        color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Save Customer',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFF94A3B8),
      ),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      suffixIcon: suffixIcon,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0F56D9), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}
