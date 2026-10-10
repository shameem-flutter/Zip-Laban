import 'package:flutter/material.dart';
import '../services/company_service.dart';
import '../services/customer_service.dart';
import '../services/product_service.dart';
import '../services/sale_order_service.dart';
import '../services/salesperson_service.dart';
import '../widgets/app_logo.dart';

/// Premium animated splash screen for Waslasoft Restaurant POS
/// Displays official brand identity, performs background sync, and smoothly navigates into the app.
class SplashView extends StatefulWidget {
  final VoidCallback onInitializationComplete;

  const SplashView({
    super.key,
    required this.onInitializationComplete,
  });

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  String _statusText = 'Connecting to POS Terminal...';

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeIn,
      ),
    );

    _animController.forward();
    _startInitializationSequence();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _startInitializationSequence() async {
    if (mounted) {
      setState(() => _statusText = 'Connecting to POS terminal...');
    }

    try {
      // Parallelize all initialization calls with a fast timeout
      await Future.wait([
        CompanyService().fetchCompanies(),
        SaleOrderService().fetchOrders(),
        ProductService().fetchProducts(),
        CustomerService().fetchCustomers(),
        SalespersonService().fetchSalespersons(),
      ]).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Proceed quickly even if network has delay
    }

    if (mounted) {
      setState(() => _statusText = 'Ready');
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        widget.onInitializationComplete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FD),
      body: SafeArea(
        child: Stack(
          children: [
            // Center Logo & Brand Content
            Center(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Waslasoft Brand Logo
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F56D9).withValues(alpha: 0.14),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const AppLogo(
                        size: 80,
                        borderRadius: 18,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Title
                    const Text(
                      'Waslasoft Restaurant POS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    const Text(
                      'Realtime Sales & Operations Suite',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Modern Spinner
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.0,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF0F56D9),
                        ),
                        backgroundColor:
                            const Color(0xFF0F56D9).withValues(alpha: 0.12),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Dynamic Status Text
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _statusText,
                        key: ValueKey<String>(_statusText),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475467),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Version & Build Tag
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'v1.0.4 • PWA Production Suite',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
