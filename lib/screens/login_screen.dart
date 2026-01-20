import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../components/app_logo.dart';
import '../components/role_selector.dart';
import '../utils/validators.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  UserRole? _selectedRole;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a role'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call backend API for login
      final response = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (response['success'] == true && mounted) {
        final role = response['data']['role'].toLowerCase();
        final backendRole = response['data']['role']; // NURSE or PATIENT
        
        // Verify role matches selected role
        if ((_selectedRole == UserRole.nurse && backendRole != 'NURSE') ||
            (_selectedRole == UserRole.patient && backendRole != 'PATIENT')) {
          throw Exception('Role mismatch. Please select the correct role.');
        }

        // Save complete user data including name, email, role, and profileImage
        await _authService.saveUserData(
          token: response['data']['token'],
          role: role,
          name: response['data']['name'] ?? '',
          email: response['data']['email'] ?? '',
          profileImage: response['data']['profileImage'],
        );

        setState(() {
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login successful! Welcome ${response['data']['name']}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Connect Socket.IO after successful login with token
        final token = response['data']['token'] as String;
        final socketService = Provider.of<SocketService>(context, listen: false);
        if (!socketService.isConnected && !socketService.isConnecting) {
          socketService.connectWithToken(token);
          socketService.joinDeviceRoom("IV001");
        }

        // Navigate after a short delay
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          if (_selectedRole == UserRole.nurse) {
            Navigator.of(context).pushReplacementNamed('/nurse/dashboard');
          } else {
            Navigator.of(context).pushReplacementNamed('/patient/home');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'Login failed';
        final errorString = e.toString().replaceAll('Exception: ', '');
        
        if (errorString.contains('timeout') || errorString.contains('Connection timeout')) {
          errorMessage = 'Connection timeout. Please check your internet connection.';
        } else if (errorString.contains('Cannot connect') || errorString.contains('SocketException')) {
          errorMessage = 'Cannot connect to server. Please check:\n• Backend is running\n• Device is on same network\n• Firewall settings';
        } else if (errorString.contains('Invalid email or password')) {
          errorMessage = 'Invalid email or password. Please try again.';
        } else if (errorString.isNotEmpty) {
          errorMessage = errorString;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryBlue.withOpacity(0.1),
                AppColors.teal.withOpacity(0.05),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.s32),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: AppColors.primaryBlue.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryBlue.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/logo.jpg',
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const AppLogo(size: 100);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s24),
                                if (_selectedRole == UserRole.patient)
                                  Column(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.success.withOpacity(0.3),
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.success.withOpacity(0.3),
                                              blurRadius: 20,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            'assets/patient_image.jpg',
                                            width: 94,
                                            height: 94,
                                            fit: BoxFit.cover,
                                            alignment: const Alignment(0, -0.2),
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                padding: const EdgeInsets.all(20),
                                                decoration: BoxDecoration(
                                                  color: AppColors.success.withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.favorite,
                                                  color: AppColors.success,
                                                  size: 40,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.s16),
                                    ],
                                  ),
                                Text(
                                  'Welcome Back',
                                  style: AppTypography.h2(context).copyWith(
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s8),
                                Text(
                                  'Sign in to continue',
                                  style: AppTypography.body2(context),
                                ),
                                const SizedBox(height: AppSpacing.s32),
                                RoleSelector(
                                  selectedRole: _selectedRole,
                                  onRoleSelected: (role) {
                                    setState(() {
                                      _selectedRole = role;
                                    });
                                  },
                                ),
                                const SizedBox(height: AppSpacing.s24),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: Validators.validateEmail,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    filled: true,
                                    fillColor: AppColors.lightBlue.withOpacity(0.3),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s20),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  validator: Validators.validatePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outlined),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: AppColors.lightBlue.withOpacity(0.3),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                          },
                                          activeColor: AppColors.primaryBlue,
                                        ),
                                        Text(
                                          'Remember me',
                                          style: AppTypography.body2(context),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const ForgotPasswordScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Forgot Password?',
                                        style: AppTypography.body2(context).copyWith(
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.s24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryBlue,
                                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                      disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                                            ),
                                          )
                                        : Text(
                                            _selectedRole == null
                                                ? 'Sign In'
                                                : _selectedRole == UserRole.nurse
                                                    ? 'Sign In as Nurse'
                                                    : 'Sign In as Caretaker',
                                            style: AppTypography.button(context),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Don\'t have an account? ',
                                      style: AppTypography.body2(context),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const SignUpScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Sign Up',
                                        style: AppTypography.body1(context).copyWith(
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.w600,
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
