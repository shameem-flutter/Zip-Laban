import 'dart:math';
import 'package:flutter/material.dart';
import '../models/odoo_product.dart';
import '../services/product_service.dart';
import '../theme/app_colors.dart';

class AddProductModal extends StatefulWidget {
  const AddProductModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddProductModal(),
    );
  }

  @override
  State<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  final _formKey = GlobalKey<FormState>();

  final _itemNameController = TextEditingController();
  final _arabicNameController = TextEditingController();
  final _printingNameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _salePriceController = TextEditingController(text: '180.0');
  final _costPriceController = TextEditingController(text: '70.0');
  final _purchasePriceController = TextEditingController(text: '70.0');
  final _stockController = TextEditingController(text: '15.0');
  final _itemIdController = TextEditingController();
  final _remarksController = TextEditingController(text: 'Fresh Kitchen Preparation');
  final _brandIdController = TextEditingController(text: 'ZZZZ');

  String _selectedUnit = 'PCS';
  String _selectedGroup = 'Food';
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _generateRandomItemIdAndBarcode();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _arabicNameController.dispose();
    _printingNameController.dispose();
    _barcodeController.dispose();
    _salePriceController.dispose();
    _costPriceController.dispose();
    _purchasePriceController.dispose();
    _stockController.dispose();
    _itemIdController.dispose();
    _remarksController.dispose();
    _brandIdController.dispose();
    super.dispose();
  }

  void _generateRandomItemIdAndBarcode() {
    final rand = Random();
    final randomDigits = (1000 + rand.nextInt(9000)).toString();
    _barcodeController.text = '100000000$randomDigits';
    _itemIdController.text = '00$randomDigits';
  }


  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final input = CreateProductInput(
      itemId: _itemIdController.text.trim(),
      itemName: _itemNameController.text.trim(),
      itemNameArabic: _arabicNameController.text.trim(),
      printingName: _printingNameController.text.trim().isNotEmpty
          ? _printingNameController.text.trim()
          : _itemNameController.text.trim(),
      barcode: _barcodeController.text.trim(),
      unitName: _selectedUnit,
      salePrice: double.tryParse(_salePriceController.text.trim()) ?? 0.0,
      costPrice: double.tryParse(_costPriceController.text.trim()) ?? 0.0,
      purchasePrice: double.tryParse(_purchasePriceController.text.trim()) ?? 0.0,
      currentStock: double.tryParse(_stockController.text.trim()) ?? 0.0,
      remarks: _remarksController.text.trim(),
      brandId: _brandIdController.text.trim(),
      groupName: _selectedGroup,
    );

    final result = await ProductService().createProduct(input);

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      if (result.success) {
        _successMessage = result.message ?? '[${input.itemName}] Created Successfully';
      } else {
        _errorMessage = result.message ?? 'Failed to create product in Odoo';
      }
    });

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
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
                    Icons.add_shopping_cart_rounded,
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
                        'Add Menu Product',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Dish Details & Pricing',
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
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
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
                                    'Odoo API Error',
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

                    // Item Name
                    _buildLabel('Item Name *'),
                    TextFormField(
                      controller: _itemNameController,
                      decoration: _buildInputDecoration(
                        hint: 'e.g. SHAWAYA MEAL FULL',
                        icon: Icons.restaurant_rounded,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter item name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    // Arabic Name & Printing Name
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Arabic Name (Optional)'),
                              TextFormField(
                                controller: _arabicNameController,
                                textDirection: TextDirection.rtl,
                                decoration: _buildInputDecoration(
                                  hint: 'اسم الصنف بالعربية',
                                  icon: Icons.translate_rounded,
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
                              _buildLabel('Printing Name'),
                              TextFormField(
                                controller: _printingNameController,
                                decoration: _buildInputDecoration(
                                  hint: 'KOT / Receipt Name',
                                  icon: Icons.print_rounded,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Barcode & Item ID
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Barcode *'),
                              TextFormField(
                                controller: _barcodeController,
                                decoration: _buildInputDecoration(
                                  hint: '1000000004542',
                                  icon: Icons.qr_code_rounded,
                                  suffixIcon: IconButton(
                                    tooltip: 'Generate Barcode',
                                    icon: const Icon(Icons.casino_outlined, size: 18),
                                    onPressed: () {
                                      setState(() => _generateRandomItemIdAndBarcode());
                                    },
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Barcode required';
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
                              _buildLabel('Item ID *'),
                              TextFormField(
                                controller: _itemIdController,
                                decoration: _buildInputDecoration(
                                  hint: '00001',
                                  icon: Icons.tag_rounded,
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

                    // Pricing Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Sale Price (₹) *'),
                              TextFormField(
                                controller: _salePriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _buildInputDecoration(
                                  hint: '22.0',
                                  icon: Icons.currency_rupee_rounded,
                                ),
                                validator: (val) {
                                  if (val == null || double.tryParse(val.trim()) == null) {
                                    return 'Enter valid price';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Cost Price (₹)'),
                              TextFormField(
                                controller: _costPriceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _buildInputDecoration(
                                  hint: '1.0',
                                  icon: Icons.monetization_on_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Group Name & Unit of Measure
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Category / Group'),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedGroup,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
                                    items: ['Food', 'Beverages', 'Desserts', 'Mandhi', 'Grill']
                                        .map((grp) => DropdownMenuItem(
                                              value: grp,
                                              child: Text(
                                                grp,
                                                style: const TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedGroup = val);
                                      }
                                    },
                                  ),
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
                              _buildLabel('Unit (UoM)'),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedUnit,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
                                    items: ['PCS', 'Units', 'Portions', 'Plates']
                                        .map((u) => DropdownMenuItem(
                                              value: u,
                                              child: Text(
                                                u,
                                                style: const TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedUnit = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Initial Stock & Remarks
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Opening Stock'),
                              TextFormField(
                                controller: _stockController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _buildInputDecoration(
                                  hint: '0.0',
                                  icon: Icons.inventory_2_outlined,
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
                              _buildLabel('Brand ID'),
                              TextFormField(
                                controller: _brandIdController,
                                decoration: _buildInputDecoration(
                                  hint: 'ZZZZ',
                                  icon: Icons.storefront_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _buildLabel('Remarks / Kitchen Notes'),
                    TextFormField(
                      controller: _remarksController,
                      decoration: _buildInputDecoration(
                        hint: 'NO REMARK',
                        icon: Icons.note_alt_outlined,
                      ),
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
                            color: const Color(0xFF0F56D9).withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitProduct,
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
                                      'Saving Product...',
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
                                    Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Save Product',
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
