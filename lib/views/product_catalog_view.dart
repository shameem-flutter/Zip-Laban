import 'package:flutter/material.dart';
import '../models/odoo_product.dart';
import '../services/company_service.dart';
import '../services/product_service.dart';
import '../services/sale_order_service.dart';
import '../theme/app_colors.dart';

class ProductCatalogView extends StatefulWidget {
  final bool isModal;

  const ProductCatalogView({super.key, this.isModal = false});

  static Future<void> showModal(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const SizedBox(
        height: 680,
        child: ProductCatalogView(isModal: true),
      ),
    );
  }

  @override
  State<ProductCatalogView> createState() => _ProductCatalogViewState();
}

class _ProductCatalogViewState extends State<ProductCatalogView>
    with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _syncAnimController;

  @override
  void initState() {
    super.initState();
    _syncAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _productService.fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _syncAnimController.dispose();
    super.dispose();
  }

  void _triggerRefresh() async {
    _syncAnimController.repeat();
    await _productService.fetchProducts(forceRefresh: true);
    if (mounted) {
      _syncAnimController.stop();
      _syncAnimController.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Products refreshed from server'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showProductDetails(OdooProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (product.arabicName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            product.arabicName!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlueLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.iceBlue),
                    ),
                    child: Text(
                      '₹ ${product.price.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.cardBorder, height: 24),
              _detailRow('Item ID', product.itemId),
              _detailRow('Barcode', product.barcode),
              _detailRow('Unit of Measure', product.uom),
              _detailRow('Stock Quantity', '${product.stockQty.toStringAsFixed(0)} ${product.uom}'),
              _detailRow('Tax', '${product.tax.toStringAsFixed(0)}%'),
              _detailRow('Company', product.companyNames.join(', ')),
              if (product.shortDescription.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.shortDescription,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Menu & Products Catalog',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Live Items & Pricing',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sync Products',
            onPressed: _triggerRefresh,
            icon: RotationTransition(
              turns: _syncAnimController,
              child: const Icon(Icons.sync_rounded, color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _productService,
        builder: (context, _) {
          if (_productService.isLoading && _productService.products.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }

          final products = _productService.filteredProducts;

          return Column(
            children: [
              // Search & Filter header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      onChanged: _productService.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Search product name, barcode (1000000004543)...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _productService.setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primaryBlue, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Category scroll chips
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _productService.availableCategories.map((cat) {
                          final isSelected = (_productService.selectedCategory == cat) ||
                              (_productService.selectedCategory == null && cat == 'All');
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                              selectedColor: AppColors.primaryBlue,
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.cardBorder,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              onSelected: (_) {
                                _productService.setSelectedCategory(
                                    cat == 'All' ? null : cat);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.cardBorder),

              // Product count header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${products.length} Products Found',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlueLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Store: ${SaleOrderService().activeOutlet?.name ?? (CompanyService().outlets.isNotEmpty ? CompanyService().outlets.first.name : 'All Outlets')}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Product List
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No products match your query',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: products.length,
                        itemBuilder: (context, i) {
                          final product = products[i];
                          return _buildProductCard(product);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );

    if (widget.isModal) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: content,
      );
    }

    return content;
  }

  Widget _buildProductCard(OdooProduct product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showProductDetails(product),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: ID pill + Category pill + Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlueLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${product.itemId}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          if (product.productCategory != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.skyBlueLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product.productCategory!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.skyBlue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹ ${product.price.toStringAsFixed(product.price % 1 == 0 ? 0 : 2)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Product Name
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                if (product.arabicName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.arabicName!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // Barcode + Stock Quantity row
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // Barcode pill
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.qr_code_2_rounded,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.barcode,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Stock Qty Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: product.stockQty > 0
                            ? AppColors.primaryBlueLight
                            : (product.stockQty == 0
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFFFEF2F2)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.stockQty > 0
                            ? '${product.stockQty.toStringAsFixed(0)} ${product.uom} in stock'
                            : (product.stockQty == 0
                                ? '0 ${product.uom}'
                                : '${product.stockQty.toStringAsFixed(0)} ${product.uom}'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: product.stockQty > 0
                              ? AppColors.primaryBlue
                              : (product.stockQty == 0
                                  ? AppColors.textSecondary
                                  : const Color(0xFFDC2626)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
