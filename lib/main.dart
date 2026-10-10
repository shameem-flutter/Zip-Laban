import 'package:flutter/material.dart';
import 'models/sales_model.dart';
import 'services/auth_service.dart';
import 'services/company_service.dart';
import 'theme/app_theme.dart';
import 'views/login_view.dart';
import 'views/more_view.dart';
import 'views/operation_view.dart';
import 'views/sales_view.dart';
import 'widgets/custom_bottom_nav_bar.dart';
import 'widgets/responsive_frame.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SipLabanApp());
}

class SipLabanApp extends StatelessWidget {
  const SipLabanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MaterialApp(
      title: 'Waslasoft Restaurant - Sales & Operations',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: ResponsiveFrame(
        child: ListenableBuilder(
          key: const ValueKey('main_app_content'),
          listenable: authService,
          builder: (context, _) {
            if (authService.isAuthenticated) {
              return MainAppShell(
                branches: authService.currentUser?.branches,
              );
            }
            return LoginView(
              onLoginSuccess: () {},
            );
          },
        ),
      ),
    );
  }
}

class MainAppShell extends StatefulWidget {
  final List<OutletInfo>? branches;

  const MainAppShell({super.key, this.branches});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentTabIndex = 0;

  late List<OutletInfo> _outlets;
  late OutletInfo _selectedOutlet;

  @override
  void initState() {
    super.initState();
    _initOutlets();
    CompanyService().addListener(_onCompanyChanged);
  }

  @override
  void dispose() {
    CompanyService().removeListener(_onCompanyChanged);
    super.dispose();
  }

  void _onCompanyChanged() {
    if (mounted) {
      setState(() {
        _outlets = CompanyService().outlets;
        if (!_outlets.any((o) => o.id == _selectedOutlet.id)) {
          _selectedOutlet = _outlets.isNotEmpty ? _outlets.first : _selectedOutlet;
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant MainAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initOutlets();
  }

  void _initOutlets() {
    _outlets = CompanyService().outlets;
    if (_outlets.isNotEmpty) {
      _selectedOutlet = _outlets.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          SalesView(
            selectedOutlet: _selectedOutlet,
            outlets: _outlets,
            onOutletChanged: (outlet) {
              setState(() => _selectedOutlet = outlet);
            },
          ),
          OperationView(
            outlet: _selectedOutlet,
          ),
          MoreView(
            outlet: _selectedOutlet,
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() => _currentTabIndex = index);
        },
      ),
    );
  }
}
