import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laban_pwa/constants/api_endpoints.dart';
import 'package:laban_pwa/main.dart';
import 'package:laban_pwa/models/odoo_company.dart';
import 'package:laban_pwa/models/odoo_order.dart';
import 'package:laban_pwa/models/sales_model.dart';
import 'package:laban_pwa/services/auth_service.dart';
import 'package:laban_pwa/services/company_service.dart';
import 'package:laban_pwa/services/sale_order_service.dart';
import 'package:laban_pwa/views/more_view.dart';
import 'package:laban_pwa/widgets/custom_bottom_nav_bar.dart';
import 'package:laban_pwa/widgets/daily_snapshot_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laban_pwa/views/sales_view.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

    // Verify text fields exist
    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(3));

    // Pump MainAppShell to verify Sales Overview Dashboard
    await tester.pumpWidget(
      const MaterialApp(
        home: MainAppShell(
          branches: [
            OutletInfo(
              id: '1',
              name: 'ZIP LABAN BRANCH',
              shortName: 'Zip Laban',
              location: '',
              posTerminalId: '',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sales Overview'), findsOneWidget);
    expect(find.text('TOTAL SALES'), findsOneWidget);
    expect(find.text('DINE IN'), findsOneWidget);
    expect(find.text('PICK UP'), findsOneWidget);
    expect(find.text('DELIVERY'), findsOneWidget);
    expect(find.text('PAYMENT DETAILS'), findsOneWidget);
    expect(find.text('TOTAL ORDERS'), findsOneWidget);

    // Verify bottom navigation has only Analytics and More (Operations removed)
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Operation'), findsNothing);
  });

  test('UserSession.fromOdooResult parses real response and does not fabricate fallback branch', () {
    // Test 1: Result with allowed companies
    final resultWithBranches = {
      'uid': 2,
      'name': 'Zip Laban Admin',
      'username': 'ziplabanadmin',
      'db': 'ziplaban_db',
      'server_version': '18.0',
      'user_companies': {
        'allowed_companies': {
          '2': {'id': 2, 'name': 'Branch Two', 'city': 'Malappuram'},
        }
      }
    };

    final session = UserSession.fromOdooResult(resultWithBranches);
    expect(session.name, 'Zip Laban Admin');
    expect(session.username, 'ziplabanadmin');
    expect(session.branches.length, 1);
    expect(session.branches.first.name, 'Branch Two');
    expect(session.branches.first.location, 'Malappuram');

    // Test 2: Result without allowed companies does not produce fake fallback branches
    final resultEmpty = {
      'uid': 5,
      'name': 'No Branch User',
      'username': 'nobranch',
    };
    final emptySession = UserSession.fromOdooResult(resultEmpty);
    expect(emptySession.branches, isEmpty);

    // Test 3: Logout clears session
    final auth = AuthService();
    auth.logout();
    expect(auth.isAuthenticated, isFalse);
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
    expect(outlet.posTerminalId, '');
  });

  test('CompanyService default companies and outlets are empty', () {
    final service = CompanyService();
    service.clear();
    expect(service.companies.isEmpty, isTrue);
    expect(service.outlets.isEmpty, isTrue);
  });

  testWidgets('MoreView renders without Store Operations section', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    const testOutlet = OutletInfo(
      id: '1',
      name: 'ZIP LABAN BRANCH',
      shortName: 'Zip Laban',
      location: 'Malappuram',
      posTerminalId: '',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: MoreView(outlet: testOutlet),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('More & Settings'), findsOneWidget);
    expect(find.text('Install as PWA App'), findsOneWidget);
    expect(find.text('System Information'), findsOneWidget);
    expect(find.text('Sign Out / Switch Terminal'), findsOneWidget);

    // Verify Store Operations & Management items are completely gone
    expect(find.text('Store Operations & Management'), findsNothing);
    expect(find.text('Menu & Products Catalog'), findsNothing);
    expect(find.text('Customer Directory & Accounts'), findsNothing);
    expect(find.text('Staff & Waiters Directory'), findsNothing);
  });

  testWidgets('CustomBottomNavBar renders 2 pure analytics tabs', (WidgetTester tester) async {
    int tappedIndex = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: 0,
            onTap: (idx) => tappedIndex = idx,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
    expect(find.text('Operation'), findsNothing);

    await tester.tap(find.text('More'));
    expect(tappedIndex, 1);
  });

  test('ApiEndpoints configuration verification', () {
    expect(ApiEndpoints.baseDomain, 'ziplaban.odoo.waslasoft.com');
    expect(ApiEndpoints.baseUrl, 'https://ziplaban.odoo.waslasoft.com');
    expect(ApiEndpoints.authenticate, 'https://ziplaban.odoo.waslasoft.com/web/session/authenticate');
    expect(ApiEndpoints.getCompanyData, 'https://ziplaban.odoo.waslasoft.com/api/get_company_data');
    expect(ApiEndpoints.listOrders, 'https://ziplaban.odoo.waslasoft.com/api/list/orders');
  });

  test('SaleOrderService dynamic sales and channel calculations', () {
    final saleService = SaleOrderService();
    saleService.clear();
    saleService.setActiveOutlet(null);
    expect(saleService.totalSales, 0.0);
    expect(saleService.dineInSales, 0.0);
    expect(saleService.pickUpSales, 0.0);
    expect(saleService.dineInOrderCount, 0);
    expect(saleService.pickUpOrderCount, 0);
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
  });

  testWidgets('DailySnapshotModal renders realtime analytics snapshot', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DailySnapshotModal(dateText: '13 Oct 2026'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daily Snapshot'), findsOneWidget);
    expect(find.text('Realtime'), findsOneWidget);
    expect(find.text('13 Oct 2026'), findsOneWidget);
    expect(find.text('Total Revenue'), findsOneWidget);
  });

  test('SaleOrderService date filtering presets and custom ranges', () {
    final saleService = SaleOrderService();
    saleService.clear();

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final fiveDaysAgo = now.subtract(const Duration(days: 5));
    final lastYear = DateTime(now.year - 1, 1, 1);

    String toDateStr(DateTime dt) =>
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

    final orderToday = OdooOrder.fromJson({
      "invoice_number": "ORD-1",
      "invoice_date": toDateStr(now),
      "partner_name": "Customer 1",
      "order_type": "dine_in",
      "company_id": 1,
      "company_name": "MAIN BRANCH",
      "amount_untaxed": 100.0,
      "amount_tax": 0.0,
      "amount_total": 100.0,
      "amount_paid": 100.0,
      "payments": [
        {"name": "Cash", "amount": 100.0}
      ]
    });

    final orderYesterday = OdooOrder.fromJson({
      "invoice_number": "ORD-2",
      "invoice_date": toDateStr(yesterday),
      "partner_name": "Customer 2",
      "order_type": "takeaway",
      "company_id": 1,
      "company_name": "MAIN BRANCH",
      "amount_untaxed": 200.0,
      "amount_tax": 0.0,
      "amount_total": 200.0,
      "amount_paid": 200.0,
      "payments": [
        {"name": "Card", "amount": 200.0}
      ]
    });

    final orderFiveDaysAgo = OdooOrder.fromJson({
      "invoice_number": "ORD-3",
      "invoice_date": toDateStr(fiveDaysAgo),
      "partner_name": "Customer 3",
      "order_type": "delivery",
      "company_id": 1,
      "company_name": "MAIN BRANCH",
      "amount_untaxed": 300.0,
      "amount_tax": 0.0,
      "amount_total": 300.0,
      "amount_paid": 300.0,
      "payments": [
        {"name": "Cash", "amount": 300.0}
      ]
    });

    final orderLastYear = OdooOrder.fromJson({
      "invoice_number": "ORD-4",
      "invoice_date": toDateStr(lastYear),
      "partner_name": "Customer 4",
      "order_type": "dine_in",
      "company_id": 1,
      "company_name": "MAIN BRANCH",
      "amount_untaxed": 400.0,
      "amount_tax": 0.0,
      "amount_total": 400.0,
      "amount_paid": 400.0,
      "payments": []
    });

    saleService.setOrdersForTesting([
      orderToday,
      orderYesterday,
      orderFiveDaysAgo,
      orderLastYear,
    ]);

    const testOutlet = OutletInfo(
      id: '1',
      name: 'MAIN BRANCH',
      shortName: 'MB',
      location: 'Main',
      posTerminalId: 'POS-01',
    );
    saleService.setActiveOutlet(testOutlet);

    // 1. Test Today preset
    saleService.setDateFilterPreset(DateFilterPreset.today);
    expect(saleService.dateFilterPreset, DateFilterPreset.today);
    expect(saleService.totalSales, 100.0);
    expect(saleService.dineInSales, 100.0);
    expect(saleService.pickUpSales, 0.0);
    expect(saleService.deliverySales, 0.0);
    expect(saleService.totalOrderCount, 1);

    // 2. Test Yesterday preset
    saleService.setDateFilterPreset(DateFilterPreset.yesterday);
    expect(saleService.dateFilterPreset, DateFilterPreset.yesterday);
    expect(saleService.totalSales, 200.0);
    expect(saleService.dineInSales, 0.0);
    expect(saleService.pickUpSales, 200.0);
    expect(saleService.totalOrderCount, 1);

    // 3. Test Last 7 Days preset
    saleService.setDateFilterPreset(DateFilterPreset.last7Days);
    expect(saleService.dateFilterPreset, DateFilterPreset.last7Days);
    expect(saleService.totalSales, 600.0); // 100 + 200 + 300
    expect(saleService.totalOrderCount, 3);

    // 4. Test All Time preset
    saleService.setDateFilterPreset(DateFilterPreset.all);
    expect(saleService.dateFilterPreset, DateFilterPreset.all);
    expect(saleService.totalSales, 1000.0); // 100 + 200 + 300 + 400
    expect(saleService.totalOrderCount, 4);

    // 5. Test Custom Date Range
    saleService.setCustomDateRange(fiveDaysAgo, yesterday);
    expect(saleService.dateFilterPreset, DateFilterPreset.custom);
    expect(saleService.totalSales, 500.0); // 200 + 300
    expect(saleService.totalOrderCount, 2);
  });

  testWidgets('SalesView date filter modal switches presets and updates header', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final saleService = SaleOrderService();
    saleService.clear();

    const outlet = OutletInfo(
      id: '2',
      name: 'KOTTAKKAL BRANCH',
      shortName: 'KB',
      location: 'Kottakkal',
      posTerminalId: 'POS-02',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SalesView(
            selectedOutlet: outlet,
            outlets: const [outlet],
            onOutletChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial header date button shows Today's label
    expect(find.text(saleService.dateFilterLabel), findsWidgets);

    // Tap the calendar icon / date pill button to open Select Date Filter modal
    final calendarIcon = find.byIcon(Icons.calendar_today_outlined);
    expect(calendarIcon, findsOneWidget);
    await tester.tap(calendarIcon);
    await tester.pumpAndSettle();

    // Verify bottom sheet title and options
    expect(find.text('Select Date Filter'), findsOneWidget);
    expect(find.text('Last 7 Days'), findsOneWidget);
    expect(find.text('Custom Date Range'), findsOneWidget);
    expect(find.text('All Time'), findsOneWidget);

    // Tap "Last 7 Days"
    await tester.tap(find.text('Last 7 Days'));
    await tester.pumpAndSettle();

    // Verify modal is dismissed and service preset updated to last7Days
    expect(find.text('Select Date Filter'), findsNothing);
    expect(saleService.dateFilterPreset, DateFilterPreset.last7Days);
    expect(find.text('Last 7 Days'), findsOneWidget);
  });

  test('UserSession persistence and restoreSession across app restarts', () async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthService();
    await auth.logout();

    final testUser = UserSession(
      uid: 101,
      name: 'Manager',
      username: 'manager_pos',
      db: 'ziplaban',
      serverVersion: '16.0',
      sessionId: 'test_session_token_123',
      branches: const [
        OutletInfo(
          id: '2',
          name: 'KOTTAKKAL BRANCH',
          shortName: 'KB',
          location: 'Kottakkal',
          posTerminalId: 'POS-02',
        ),
      ],
    );

    // Save session to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('waslasoft_user_session', jsonEncode(testUser.toJson()));

    // Verify restoreSession restores user
    await auth.restoreSession();
    expect(auth.isAuthenticated, isTrue);
    expect(auth.currentUser?.uid, 101);
    expect(auth.currentUser?.username, 'manager_pos');
    expect(auth.currentUser?.sessionId, 'test_session_token_123');
    expect(auth.currentUser?.branches.length, 1);
    expect(auth.currentUser?.branches.first.name, 'KOTTAKKAL BRANCH');

    // Logout clears the saved session
    await auth.logout();
    expect(auth.isAuthenticated, isFalse);
    expect(prefs.containsKey('waslasoft_user_session'), isFalse);
  });

  test('CompanyService restores cached companies from SharedPreferences', () async {
    final companyService = CompanyService();
    companyService.clear();

    final testCompanyJson = [
      {'id': 2, 'name': 'KOTTAKKAL BRANCH'},
      {'id': 3, 'name': 'KADAMPUZHA BRANCH'},
    ];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('waslasoft_cached_companies', jsonEncode(testCompanyJson));

    await companyService.restoreCachedCompanies();
    expect(companyService.companies.length, 2);
    expect(companyService.outlets.length, 2);
    expect(companyService.outlets.first.name, 'KOTTAKKAL BRANCH');
  });

  test('SaleOrderService restores cached orders from SharedPreferences', () async {
    final saleService = SaleOrderService();
    saleService.clear();

    final testOrderJson = [
      {
        "invoice_number": "POS-V2-33",
        "invoice_date": "2026-10-09",
        "partner_name": "Test Customer",
        "order_type": "takeaway",
        "company_id": 2,
        "company_name": "KOTTAKKAL BRANCH",
        "amount_untaxed": 402.5,
        "amount_tax": 0.0,
        "amount_total": 402.5,
        "amount_paid": 402.5,
        "payments": []
      }
    ];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('waslasoft_cached_orders', jsonEncode(testOrderJson));
    await prefs.setString('waslasoft_cached_orders_sync_time', DateTime.now().toIso8601String());

    await saleService.restoreCachedOrders();
    saleService.clearDateFilter();
    expect(saleService.odooOrders.length, 1);
    expect(saleService.isUsingCachedData, isTrue);
    expect(saleService.odooOrders.first.invoiceNumber, 'POS-V2-33');
    expect(saleService.getTotalSalesForOutlet(const OutletInfo(
      id: '2',
      name: 'KOTTAKKAL BRANCH',
      shortName: 'KB',
      location: '',
      posTerminalId: '',
    )), 402.5);
  });
}
