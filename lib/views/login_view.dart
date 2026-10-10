import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';

class LoginView extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginView({super.key, required this.onLoginSuccess});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dbController = TextEditingController();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _dbController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin({bool isAuto = false}) async {
    FocusScope.of(context).unfocus();
    if (!isAuto &&
        _formKey.currentState != null &&
        !_formKey.currentState!.validate()) {
      return;
    }

    final success = await _authService.login(
      db: _dbController.text,
      login: _loginController.text,
      password: _passwordController.text,
    );

    if (success && mounted) {
      widget.onLoginSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF4F7FC),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top Brand Header (B.Laban White & Blue Aesthetics)
                    _buildBrandHeader(),

                    const SizedBox(height: 24),

                    // Login Form Card
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF0F56D9,
                            ).withValues(alpha: 0.06),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Sign In to Terminal',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Enter your credentials to access sales insights & analytics',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),

                            const SizedBox(height: 22),

                            // Error Banner if any
                            ListenableBuilder(
                              listenable: _authService,
                              builder: (context, _) {
                                if (_authService.errorMessage == null) {
                                  return const SizedBox.shrink();
                                }
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFFCA5A5),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _authService.errorMessage!,
                                          style: const TextStyle(
                                            color: Color(0xFFB91C1C),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // Database Field
                            _buildInputLabel('Database Name'),
                            TextFormField(
                              controller: _dbController,
                              decoration: _buildInputDecoration(
                                hint: 'Enter database name',
                                prefixIcon: Icons.dns_outlined,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Database is required'
                                  : null,
                            ),

                            const SizedBox(height: 16),

                            // Username / Login Field
                            _buildInputLabel('User Login / Email'),
                            TextFormField(
                              controller: _loginController,
                              decoration: _buildInputDecoration(
                                hint: 'Enter username or email',
                                prefixIcon: Icons.person_outline_rounded,
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Login is required'
                                  : null,
                            ),

                            const SizedBox(height: 16),

                            // Password Field
                            _buildInputLabel('Password'),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: _buildInputDecoration(
                                hint: 'Enter your password',
                                prefixIcon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Password is required'
                                  : null,
                              onFieldSubmitted: (_) => _handleLogin(),
                            ),

                            const SizedBox(height: 8),

                            // Sign In Button
                            ListenableBuilder(
                              listenable: _authService,
                              builder: (context, _) {
                                final loading = _authService.isLoading;
                                return ElevatedButton(
                                  onPressed: loading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F56D9),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Server Connection Footer info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Secure Cloud Terminal Connected',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }

  // Waslasoft Restaurant brand logo header (White & Blue Palette)
  Widget _buildBrandHeader() {
    return Column(
      children: [
        // Official Waslasoft Restaurant Dining App Logo
        const AppLogo(
          size: 84,
          borderRadius: 20,
          showShadow: true,
          showBorder: true,
          borderColor: Color(0xFFDBEAFE),
          borderWidth: 1.5,
        ),

        const SizedBox(height: 14),

        // Brand Title
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'WASLASOFT',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F56D9),
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '•',
                style: TextStyle(fontSize: 20, color: Color(0xFF94A3B8)),
              ),
              SizedBox(width: 8),
              Text(
                'وصلة سوفت',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F56D9),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'WASLASOFT RESTAURANT ANALYTICS & SALES PORTAL',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF0F56D9), size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: const BorderSide(color: Color(0xFF0F56D9), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }
}
