import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../components/app_logo.dart';
import '../utils/validators.dart';
import '../services/api_service.dart';
import 'otp_verify_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _userEmail;

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
    super.dispose();
  }

  Future<void> _handleRequestOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.requestOtp(_emailController.text.trim());
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _userEmail = _emailController.text.trim();
        });

        // Check if email was actually sent
        if (response['success'] == true && response['emailSent'] == true) {
          // Email sent successfully
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'OTP has been sent to your email. Please check your inbox (and spam folder).',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );

          // Navigate to OTP verification screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerifyScreen(
                email: _userEmail!,
              ),
            ),
          );
        } else {
          // Email failed to send
          final errorMsg = response['message'] ?? 'Failed to send OTP email';
          final debugOtp = response['debugOtp'] as String?;
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Email Sending Failed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(errorMsg),
                  if (debugOtp != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'For testing, use this OTP:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Text(
                        debugOtp,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Note: Check backend console for email configuration errors.',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
              actions: [
                if (debugOtp != null)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to OTP screen with debug OTP
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OtpVerifyScreen(
                            email: _userEmail!,
                          ),
                        ),
                      );
                    },
                    child: const Text('Continue with OTP'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        final errorMsg = e.toString().replaceAll('Exception: ', '');
        
        // Show a more helpful dialog for backend connection errors
        if (errorMsg.contains('HTML') || 
            errorMsg.contains('connection') || 
            errorMsg.contains('timeout') ||
            errorMsg.contains('SocketException')) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Connection Error'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    errorMsg.contains('timeout') 
                        ? 'Request timed out. Render free tier may be waking up.'
                        : 'Unable to connect to the backend server.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text('Please try:'),
                  const SizedBox(height: 8),
                  const Text('1. Wait 30-60 seconds (Render wake-up time)'),
                  const SizedBox(height: 8),
                  const Text('2. Check your internet connection'),
                  const SizedBox(height: 8),
                  const Text('3. Try again'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleRequestOtp(); // Retry
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.s32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: AppColors.primaryBlue.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: _buildResetForm(),
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

  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo(size: 80),
          const SizedBox(height: AppSpacing.s24),
          Text(
            'Forgot Password?',
            style: AppTypography.h2(context).copyWith(
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Enter your email to receive a password reset OTP',
            style: AppTypography.body2(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s32),
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
          const SizedBox(height: AppSpacing.s32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRequestOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Request OTP',
                      style: AppTypography.button(context),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Back to Sign In',
              style: AppTypography.body1(context).copyWith(
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
