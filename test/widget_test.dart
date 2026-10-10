import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laban_pwa/constants/api_endpoints.dart';
import 'package:laban_pwa/main.dart';
import 'package:laban_pwa/models/odoo_company.dart';
import 'package:laban_pwa/models/odoo_customer.dart';
import 'package:laban_pwa/models/odoo_order.dart';
import 'package:laban_pwa/models/odoo_product.dart';
import 'package:laban_pwa/models/odoo_salesperson.dart';
import 'package:laban_pwa/models/sale_order_model.dart';
import 'package:laban_pwa/models/sales_model.dart';
import 'package:laban_pwa/services/auth_service.dart';
import 'package:laban_pwa/services/company_service.dart';
import 'package:laban_pwa/services/customer_service.dart';
import 'package:laban_pwa/services/product_service.dart';
import 'package:laban_pwa/services/sale_order_service.dart';
import 'package:laban_pwa/services/salesperson_service.dart';
import 'package:laban_pwa/views/customer_directory_view.dart';
import 'package:laban_pwa/views/product_catalog_view.dart';
import 'package:laban_pwa/widgets/add_product_modal.dart';
import 'package:laban_pwa/widgets/branch_directory_modal.dart';
import 'package:laban_pwa/widgets/create_sale_order_modal.dart';
import 'package:laban_pwa/widgets/orders_detail_modal.dart';
import 'package:laban_pwa/widgets/salesperson_directory_modal.dart';

void main() {
  testWidgets('App smoke test - Login and Dashboard', (WidgetTester tester) async {
    // Set standard mobile device test size
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const SipLabanApp());
    await tester.pumpAndSettle();

    // Verify Login page renders Waslasoft Restaurant branding
    expect(find.text('WASLASOFT'), findsOneWidget);
    expect(find.text('Sign In to Terminal'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Enter credentials into the login fields
    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(3));
    await tester.enterText(textFields.at(0), 'test_ziplaban');
    await tester.enterText(textFields.at(1), 'ziplabanadmin');
    await tester.enterText(textFields.at(2), '#ZIPADMIN');
    await tester.pumpAndSettle();

    // Tap Sign In
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Verify transition to Sales Overview Dashboard
    expect(find.text('Sales Overview'), findsOneWidget);
    expect(find.text('TOTAL SALES'), findsOneWidget);
    expect(find.text('DINE IN'), findsOneWidget);
    expect(find.text('PICK UP'), findsOneWidget);
    expect(find.text('DELIVERY'), findsOneWidget);
    expect(find.text('PAYMENT DETAILS'), findsOneWidget);
    expect(find.text('TOTAL ORDERS'), findsOneWidget);

    // Verify Column Chart Dropdown works and can switch chart type
    final columnDropdown = find.text('Column');
    await tester.scrollUntilVisible(columnDropdown, 500);
    await tester.pumpAndSettle();
    expect(columnDropdown, findsOneWidget);

    await tester.tap(columnDropdown);
    await tester.pumpAndSettle();

    // Verify popup menu options appear
    expect(find.text('Line'), findsOneWidget);
    expect(find.text('Area'), findsOneWidget);

    // Tap Line
    await tester.tap(find.text('Line'));
    await tester.pumpAndSettle();
    expect(find.text('Line'), findsOneWidget);
  });

  test('AuthService accurate error messages and branch authentication test', () async {
    final auth = AuthService();

    // Test 1: Non-existent database
    final badDbResult = await auth.login(
      db: 'unknown_db',
      login: 'ziplabanadmin',
      password: '#ZIPADMIN',
    );
    expect(badDbResult, isFalse);
    expect(auth.errorMessage, contains("Database 'unknown_db' not found"));

    // Test 2: Incorrect password for recognized branch user
    final wrongPassResult = await auth.login(
      db: 'test_ziplaban',
      login: 'kottakkaladmin',
      password: '#WRONGPASS',
    );
    expect(wrongPassResult, isFalse);
    expect(auth.errorMessage, contains("Incorrect password for user 'kottakkaladmin'"));

    // Test 3: Unrecognized user
    final unknownUserResult = await auth.login(
      db: 'test_ziplaban',
      login: 'randomperson',
      password: 'somepassword',
    );
    expect(unknownUserResult, isFalse);
    expect(auth.errorMessage, contains("Invalid username or password"));

    // Test 4: Correct credentials for branch admin kottakkaladmin
    final successResult = await auth.login(
      db: 'test_ziplaban',
      login: 'kottakkaladmin',
      password: '#KTKADMIN',
    );
    expect(successResult, isTrue);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.currentUser?.name, 'KOTTAKKAL ADMIN');
    expect(auth.currentUser!.branches.first.name, 'KOTTAKKAL BRANCH');

    // Clean up
    auth.logout();
    expect(auth.isAuthenticated, isFalse);
  });

  test('OdooProduct model parsing test', () {
    final rawItem = {
      "item_id": "20",
      "name": "BEEF MANDHI",
      "arabic_name": false,
      "product_category": false,
      "price": 230,
      "purchase_price": 0,
      "barcode": "1000000004543",
      "stock_qty": 0,
      "tax": 0,
      "uom": "Units",
      "short_description": "",
      "arabic_description": "",
      "company_id": [1],
      "company_name": ["ZIP LABAN"]
    };

    final product = OdooProduct.fromJson(rawItem);
    expect(product.itemId, '20');
    expect(product.name, 'BEEF MANDHI');
    expect(product.arabicName, isNull);
    expect(product.price, 230.0);
    expect(product.barcode, '1000000004543');
    expect(product.companyNames.first, 'ZIP LABAN');
  });

  test('ProductService fetch and search filtering', () async {
    final productService = ProductService();
    await productService.fetchProducts();

    expect(productService.products.isNotEmpty, isTrue);

    // Filter by Mandhi search query
    productService.setSearchQuery('CHICKEN');
    expect(productService.filteredProducts.any((p) => p.name.contains('CHICKEN')), isTrue);

    // Search by Barcode
    productService.setSearchQuery('1000000004542');
    expect(productService.filteredProducts.any((p) => p.barcode == '1000000004542'), isTrue);

    // Reset query
    productService.setSearchQuery('');
  });

  testWidgets('ProductCatalogView renders Waslasoft Restaurant products', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: ProductCatalogView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Menu & Products Catalog'), findsOneWidget);
    expect(find.text('BEEF MANDHI'), findsOneWidget);
    expect(find.text('CHICKEN MANDHI'), findsOneWidget);
  });

  test('CreateProductInput to Odoo parameters mapping', () {
    const input = CreateProductInput(
      itemId: '00001',
      itemName: 'SHAWAYA MEAL HALF',
      itemNameArabic: 'شواية نصف وجبة',
      printingName: 'SHAWAYA MEAL HALF',
      barcode: '1000000004542',
      unitName: 'PCS',
      salePrice: 22.0,
      costPrice: 1.0,
      purchasePrice: 1.0,
      currentStock: 0.0,
      remarks: 'NO REMARK',
      brandId: 'ZZZZ',
      groupName: 'Food',
    );

    final params = input.toOdooParams();
    expect(params['item_id'], '00001');
    expect(params['item_name'], 'SHAWAYA MEAL HALF');
    expect(params['barcode'], '1000000004542');
    expect(params['sale_price'], '22.0');
    expect(params['unit_name'], 'PCS');
    expect(params['group_name'], 'Food');
  });

  test('CreateProductResult parsing test for success and duplicate barcode error', () {
    final failureJson = {
      "success": false,
      "error": null,
      "message": "[SHAWAYA MEAL HALF] Product exist with same barcode!"
    };

    final failureResult = CreateProductResult.fromOdooResult(failureJson);
    expect(failureResult.success, isFalse);
    expect(failureResult.message, contains('Product exist with same barcode!'));

    final successJson = {
      "success": true,
      "error": null,
      "message": "[MUTTON SHAWARMA] Created Successfully"
    };

    final successResult = CreateProductResult.fromOdooResult(successJson);
    expect(successResult.success, isTrue);
    expect(successResult.message, contains('Created Successfully'));
  });

  testWidgets('AddProductModal renders form and sample fill', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AddProductModal(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Menu Product'), findsOneWidget);
    expect(find.text('Dish Details & Pricing'), findsOneWidget);
    expect(find.text('Save Product'), findsOneWidget);
  });

  test('CreateCustomerInput to Odoo parameters mapping', () {
    const input = CreateCustomerInput(
      customerId: '000001',
      customerName: 'Test Customer 2',
      street: 'Street 1',
      street2: 'Street 2',
      city: 'City',
      zip: '12345',
      mobile: '0000000000',
      vat: '',
      openBalance: 400.0,
    );

    final params = input.toOdooParams();
    expect(params['customer_id'], '000001');
    expect(params['customer_name'], 'Test Customer 2');
    expect(params['street'], 'Street 1');
    expect(params['street2'], 'Street 2');
    expect(params['city'], 'City');
    expect(params['zip'], '12345');
    expect(params['mobile'], '0000000000');
    expect(params['vat'], '');
    expect(params['open_balance'], 400);
  });

  test('CreateCustomerResult parsing test for success and error', () {
    final successJson = {
      "success": true,
      "error": null,
      "msg": "Test Customer 2 created Successfully"
    };

    final result = CreateCustomerResult.fromOdooResult(successJson);
    expect(result.success, isTrue);
    expect(result.msg, 'Test Customer 2 created Successfully');

    final failureJson = {
      "success": false,
      "error": "Odoo Server Error",
      "msg": "Validation failed"
    };
    final failResult = CreateCustomerResult.fromOdooResult(failureJson);
    expect(failResult.success, isFalse);
    expect(failResult.error, 'Odoo Server Error');
  });

  test('CustomerService search and filtering test', () async {
    final customerService = CustomerService();
    expect(customerService.customers.isNotEmpty, isTrue);

    final first = customerService.customers.first;
    customerService.setSearchQuery(first.name);
    expect(customerService.filteredCustomers.any((c) => c.customerId == first.customerId), isTrue);
    customerService.setSearchQuery('');
  });

  testWidgets('CustomerDirectoryView render test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: CustomerDirectoryView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Customer Directory'), findsOneWidget);
  });

  test('OdooCompany model parsing and toOutletInfo', () {
    final company = OdooCompany.fromJson(const {
      'id': 2,
      'name': 'KOTTAKKAL BRANCH',
    });
    expect(company.id, 2);
    expect(company.name, 'KOTTAKKAL BRANCH');

    final outlet = company.toOutletInfo();
    expect(outlet.id, '2');
    expect(outlet.name, 'KOTTAKKAL BRANCH');
    expect(outlet.posTerminalId, 'POS-02');
  });

  test('CompanyService default companies and outlets', () {
    final service = CompanyService();
    expect(service.companies.isNotEmpty, isTrue);
    expect(service.outlets.isNotEmpty, isTrue);
    expect(service.companies.any((c) => c.id == 2), isTrue);
    expect(service.companies.any((c) => c.id == 3), isTrue);
  });

  testWidgets('BranchDirectoryModal render test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BranchDirectoryModal(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Branches & Companies'), findsOneWidget);
    expect(find.text('Connected Outlets & Locations'), findsOneWidget);
    expect(find.text('KOTTAKKAL BRANCH'), findsOneWidget);
    expect(find.text('KADAMPUZHA BRANCH'), findsOneWidget);
  });

  test('OdooCustomer.fromJson parses /api/get_contact_data record correctly', () {
    final contact = OdooCustomer.fromJson(const {
      "customer_id": 12,
      "name": "Test Customer 1",
      "phone": "0000000000",
      "vat_number": false,
      "credit_period": 0,
      "outstanding_balance": 0,
      "available_balance": 0,
      "company_id": 1,
      "company": "ZIP LABAN",
      "email": false,
      "address": [
        "Street 1",
        "City",
        "India"
      ]
    });

    expect(contact.customerId, '12');
    expect(contact.name, 'Test Customer 1');
    expect(contact.mobile, '0000000000');
    expect(contact.companyName, 'ZIP LABAN');
    expect(contact.street, 'Street 1');
    expect(contact.city, 'City');
    expect(contact.street2, 'India');
  });

  test('CreateSaleOrderInput parameter mapping and serialization', () {
    const outlet = OutletInfo(
      id: '2',
      name: 'WASLASOFT KOTTAKKAL BRANCH',
      shortName: 'Kottakkal Branch',
      location: 'Kottakkal, Malappuram',
      posTerminalId: 'POS-02',
    );

    final input = CreateSaleOrderInput(
      syncOrderId: 10001,
      tmpId: 1,
      companyId: int.parse(outlet.id),
      companyName: outlet.name,
      invSequence: '10001',
      invSequenceId: '10001',
      isCreated: true,
      isUpdated: false,
      isCreateSync: false,
      isUpdateSync: false,
      createdAt: '2026-10-09 10:00:00',
      orderId: '10001',
      orderNo: '10001',
      orderTrnNo: '10001',
      saleDate: '2026-10-09 00:00:00',
      saleDateOdoo: '2026-10-09 00:00:00',
      orderDate: '2026-10-09 10:00:00',
      orderType: 'Dine In',
      orderTypeSlug: 'dine_in',
      tableNo: 'IN01',
      waiterName: 'ADMIN',
      invoiceAmount: 22.0,
      paymentModeCash: 22.0,
      paymentModeCreditCard: 0.0,
      creditTotal: 0.0,
      grandTotal: 22.0,
      cashier: 'ADMIN',
      salespersonName: 'ADMIN',
      entryDate: '2026-10-09 10:00:00',
      deliveryCustomerId: '0',
      name: '',
      billClosedBy: 'ADMIN',
      billClosedTime: '2026-10-09 10:00:00',
      customerBillNo: '0',
      productData: const [
        SaleOrderProductItem(
          orderDetId: '1',
          orderId: '10001',
          itemId: '71366',
          itemCode: '1000000024',
          product: 'SHAWAYA MEAL HALF',
          packageName: 'PCS',
          unitRate: 22.0,
          price: 22.0,
          discountPercentage: 0.0,
          discount: 0.0,
          qty: 1.0,
          returnQty: 0.0,
          itemPrice: '22.000',
          subPrice: 22.0,
          taxPercentage: 15.0,
          taxAmount: 2.87,
          enteredBy: 'ADMIN',
          entryDate: '2026-10-09 10:00:00',
          arabicName: 'شواية نصف وجبة',
        ),
      ],
    );
    final params = input.toOdooParams();

    expect(params['company_id'], 2);
    expect(params['CompanyName'], 'WASLASOFT KOTTAKKAL BRANCH');
    expect(params['OrderType'], 'Dine In');
    expect(params['is_created'], true);
    expect(params['product_data'] is List, true);
    expect((params['product_data'] as List).isNotEmpty, true);
  });

  test('CreateSaleOrderResult parsing for order_id and success messages', () {
    final successJson = {
      "message": "Order created successfully..",
      "order_id": "S00173",
      "inv_id": "999"
    };
    final res1 = CreateSaleOrderResult.fromOdooResult(successJson);
    expect(res1.success, true);
    expect(res1.orderId, 'S00173');
    expect(res1.invId, '999');

    final alreadyCreatedJson = {
      "success": true,
      "error": null,
      "message": "Invoice is already created with the invoice number 1"
    };
    final res2 = CreateSaleOrderResult.fromOdooResult(alreadyCreatedJson);
    expect(res2.success, true);
    expect(res2.message?.contains('already created'), true);
  });

  testWidgets('CreateSaleOrderModal renders form and products', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    const outlet = OutletInfo(
      id: '2',
      name: 'WASLASOFT KOTTAKKAL BRANCH',
      shortName: 'Kottakkal Branch',
      location: 'Kottakkal, Malappuram',
      posTerminalId: 'POS-02',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CreateSaleOrderModal(outlet: outlet),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New POS Sale Order'), findsOneWidget);
    expect(find.text('Direct Counter POS Invoicing'), findsOneWidget);
    expect(find.text('Dine In'), findsOneWidget);
    expect(find.text('Credit Card'), findsOneWidget);
    expect(find.text('Confirm & Print Order'), findsOneWidget);
  });

  test('OdooSalesperson model parsing test', () {
    final staff = OdooSalesperson.fromJson(const {
      "id": 5,
      "name": "ADMIN",
      "company_id": 1,
      "company_name": "ZIP LABAN"
    });
    expect(staff.id, 5);
    expect(staff.name, 'ADMIN');
    expect(staff.companyId, 1);
    expect(staff.companyName, 'ZIP LABAN');
  });

  test('SalespersonService default dataset', () {
    final service = SalespersonService();
    expect(service.salespersons.isNotEmpty, true);
    expect(service.salespersons.any((s) => s.id == 5), true);
    expect(service.salespersons.any((s) => s.id == 2), true);
  });

  testWidgets('SalespersonDirectoryModal renders staff list', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SalespersonDirectoryModal(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Salespersons & Staff'), findsOneWidget);
    expect(find.text('Active Waiters & Cashiers'), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);
  });

  test('ApiEndpoints configuration verification', () {
    expect(ApiEndpoints.baseDomain, 'ziplaban.odoo.waslasoft.com');
    expect(ApiEndpoints.baseUrl, 'https://ziplaban.odoo.waslasoft.com');
    expect(ApiEndpoints.authenticate, 'https://ziplaban.odoo.waslasoft.com/web/session/authenticate');
    expect(ApiEndpoints.getProductsData, 'https://ziplaban.odoo.waslasoft.com/api/get_products_data');
    expect(ApiEndpoints.getContactData, 'https://ziplaban.odoo.waslasoft.com/api/get_contact_data');
    expect(ApiEndpoints.getCompanyData, 'https://ziplaban.odoo.waslasoft.com/api/get_company_data');
    expect(ApiEndpoints.listOrders, 'https://ziplaban.odoo.waslasoft.com/api/list/orders');
    expect(ApiEndpoints.getSalespersonData, 'https://ziplaban.odoo.waslasoft.com/api/get_salesperson_data');
  });

  test('SaleOrderService dynamic sales and channel calculations', () {
    final saleService = SaleOrderService();
    saleService.setActiveOutlet(null);
    expect(saleService.totalSales, greaterThan(0));
    expect(saleService.dineInSales, greaterThan(0));
    expect(saleService.pickUpSales, greaterThan(0));
    expect(saleService.dineInOrderCount, greaterThan(0));
    expect(saleService.pickUpOrderCount, greaterThan(0));
    expect(saleService.totalSales, saleService.dineInSales + saleService.pickUpSales);
    expect(saleService.pickUpAverageOrderValue, saleService.pickUpSales / saleService.pickUpOrderCount);

    final dineInOrders = saleService.getOrdersByChannel('DINE IN');
    expect(dineInOrders.isNotEmpty, isTrue);
    expect(dineInOrders.every((o) => o['orderType'].toString().toLowerCase().contains('dine')), isTrue);
  });

  test('OdooOrder model parsing, sorting, and branch filtering', () {
    final rawItem = {
      "invoice_number": "999",
      "invoice_date": "2026-10-08",
      "partner_name": "Default Customer (Kottakkal)",
      "order_type": "dine_in",
      "company_id": 2,
      "company_name": "KOTTAKKAL BRANCH",
      "amount_untaxed": 22.0,
      "amount_tax": 0.0,
      "amount_total": 22.0,
      "amount_paid": 0.0,
      "payments": []
    };

    final order = OdooOrder.fromJson(rawItem);
    expect(order.invoiceNumber, '999');
    expect(order.companyId, 2);
    expect(order.companyName, 'KOTTAKKAL BRANCH');
    expect(order.isDineIn, isTrue);
    expect(order.isPickUp, isFalse);
    expect(order.channelDisplay, 'Dine In');
    expect(order.amountTotal, 22.0);

    final saleService = SaleOrderService();

    // Kottakkal Branch (id: 2) filtering
    const kottakkalOutlet = OutletInfo(
      id: '2',
      name: 'KOTTAKKAL BRANCH',
      shortName: 'Kottakkal...',
      location: 'Kottakkal',
      posTerminalId: 'POS-02',
    );
    final kottakkalOrders = saleService.getOrdersForOutlet(kottakkalOutlet);
    expect(kottakkalOrders.isNotEmpty, isTrue);
    expect(kottakkalOrders.every((o) => o.companyId == 2), isTrue);
    expect(saleService.getDineInCountForOutlet(kottakkalOutlet), 1);
    expect(saleService.getTotalSalesForOutlet(kottakkalOutlet), 597.0);

    // Kadampuzha Branch (id: 3) filtering
    const kadampuzhaOutlet = OutletInfo(
      id: '3',
      name: 'KADAMPUZHA BRANCH',
      shortName: 'Kadampuzha...',
      location: 'Kadampuzha',
      posTerminalId: 'POS-03',
    );
    final kadampuzhaOrders = saleService.getOrdersForOutlet(kadampuzhaOutlet);
    expect(kadampuzhaOrders.length, 8);
    expect(kadampuzhaOrders.every((o) => o.companyId == 3), isTrue);
    expect(saleService.getDineInCountForOutlet(kadampuzhaOutlet), 0);
    expect(saleService.getPickUpCountForOutlet(kadampuzhaOutlet), 8);
    expect(saleService.getTotalSalesForOutlet(kadampuzhaOutlet), 2670.5);

    // Sorting verification: latest order POS-V2-33 (2026-10-09) must be first
    final allSorted = saleService.getOrdersForOutlet(null);
    expect(allSorted.first.invoiceNumber, 'POS-V2-33');
  });

  testWidgets('OrdersDetailModal renders dynamic orders from SaleOrderService', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final saleService = SaleOrderService();
    saleService.setActiveOutlet(null);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrdersDetailModal(
            categoryTitle: 'DINE IN',
            totalAmount: saleService.dineInSales,
            orderCount: saleService.dineInOrderCount,
            metricInfo: '12 Min Turn Around Time',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DINE IN Orders'), findsOneWidget);
    expect(find.textContaining('Orders Today'), findsOneWidget);
    expect(find.text('#999'), findsOneWidget);
  });
}

