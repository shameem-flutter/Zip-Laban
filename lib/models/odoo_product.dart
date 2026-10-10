class OdooProduct {
  final String itemId;
  final String name;
  final String? arabicName;
  final String? productCategory;
  final double price;
  final double purchasePrice;
  final String barcode;
  final double stockQty;
  final double tax;
  final String uom;
  final String shortDescription;
  final String arabicDescription;
  final List<int> companyIds;
  final List<String> companyNames;

  const OdooProduct({
    required this.itemId,
    required this.name,
    this.arabicName,
    this.productCategory,
    required this.price,
    required this.purchasePrice,
    required this.barcode,
    required this.stockQty,
    required this.tax,
    required this.uom,
    required this.shortDescription,
    required this.arabicDescription,
    required this.companyIds,
    required this.companyNames,
  });

  factory OdooProduct.fromJson(Map<String, dynamic> json) {
    String? parseStringOrNull(dynamic value) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
      return null;
    }

    final companyIdsRaw = json['company_id'];
    final List<int> companyIdsList = [];
    if (companyIdsRaw is List) {
      for (final e in companyIdsRaw) {
        final parsed = int.tryParse(e.toString());
        if (parsed != null) companyIdsList.add(parsed);
      }
    }

    final companyNamesRaw = json['company_name'];
    final List<String> companyNamesList = [];
    if (companyNamesRaw is List) {
      for (final e in companyNamesRaw) {
        if (e != null) companyNamesList.add(e.toString());
      }
    }

    return OdooProduct(
      itemId: json['item_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Product',
      arabicName: parseStringOrNull(json['arabic_name']),
      productCategory: parseStringOrNull(json['product_category']),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0.0,
      barcode: json['barcode']?.toString() ?? '',
      stockQty: (json['stock_qty'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      uom: json['uom']?.toString() ?? 'Units',
      shortDescription: json['short_description']?.toString() ?? '',
      arabicDescription: json['arabic_description']?.toString() ?? '',
      companyIds: companyIdsList,
      companyNames: companyNamesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'name': name,
      'arabic_name': arabicName,
      'product_category': productCategory,
      'price': price,
      'purchase_price': purchasePrice,
      'barcode': barcode,
      'stock_qty': stockQty,
      'tax': tax,
      'uom': uom,
      'short_description': shortDescription,
      'arabic_description': arabicDescription,
      'company_id': companyIds,
      'company_name': companyNames,
    };
  }
}

class CreateProductInput {
  final String itemId;
  final String itemName;
  final String itemNameArabic;
  final String printingName;
  final String barcode;
  final String unitName;
  final double salePrice;
  final double costPrice;
  final double purchasePrice;
  final double currentStock;
  final String remarks;
  final String brandId;
  final String groupName;

  const CreateProductInput({
    required this.itemId,
    required this.itemName,
    this.itemNameArabic = '',
    this.printingName = '',
    required this.barcode,
    this.unitName = 'PCS',
    required this.salePrice,
    this.costPrice = 1.0,
    this.purchasePrice = 1.0,
    this.currentStock = 0.0,
    this.remarks = 'NO REMARK',
    this.brandId = 'ZZZZ',
    this.groupName = 'Food',
  });

  Map<String, dynamic> toOdooParams() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'item_name_arabic': itemNameArabic.isNotEmpty ? itemNameArabic : itemName,
      'printing_name': printingName.isNotEmpty ? printingName : itemName,
      'barcode': barcode,
      'unit_name': unitName,
      'sale_price': salePrice.toStringAsFixed(1),
      'cost_price': costPrice.toStringAsFixed(0),
      'purchase_price': purchasePrice.toStringAsFixed(0),
      'current_stock': currentStock.toStringAsFixed(1),
      'remarks': remarks.isNotEmpty ? remarks : 'NO REMARK',
      'brand_id': brandId.isNotEmpty ? brandId : 'ZZZZ',
      'group_name': groupName.isNotEmpty ? groupName : 'Food',
    };
  }
}

class CreateProductResult {
  final bool success;
  final String? message;
  final String? error;

  const CreateProductResult({
    required this.success,
    this.message,
    this.error,
  });

  factory CreateProductResult.fromOdooResult(Map<String, dynamic> result) {
    return CreateProductResult(
      success: result['success'] == true,
      message: result['message']?.toString(),
      error: result['error']?.toString(),
    );
  }
}
