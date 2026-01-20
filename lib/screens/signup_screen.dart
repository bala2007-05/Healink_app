import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../components/app_logo.dart';
import '../components/role_selector.dart';
import '../utils/validators.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'terms_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final _formKey = GlobalKey<FormState>();
  
  // Common fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Patient-specific fields
  final _patientIdController = TextEditingController();
  final _roomNumberController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  
  // Nurse-specific fields
  final _locationController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _yearsOfExperienceController = TextEditingController();
  
  // Profile image
  final _profileImageController = TextEditingController();
  String? _selectedProfileImageUrl;
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;
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
    _checkTermsAgreement();
  }

  Future<void> _checkTermsAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedRole != null) {
      final roleKey = _selectedRole == UserRole.nurse ? 'agreed_nurse' : 'agreed_patient';
      final hasAgreed = prefs.getBool(roleKey) ?? false;
      setState(() {
        _agreeToTerms = hasAgreed;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _patientIdController.dispose();
    _roomNumberController.dispose();
    _dateOfBirthController.dispose();
    _emergencyContactController.dispose();
    _locationController.dispose();
    _licenseNumberController.dispose();
    _yearsOfExperienceController.dispose();
    _profileImageController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
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

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the terms and conditions'),
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
      // Call backend API for registration
      Map<String, dynamic> response;
      
      // Get profile image URL if provided
      final profileImageUrl = _profileImageController.text.trim();
      final profileImage = profileImageUrl.isNotEmpty ? profileImageUrl : null;
      
      if (_selectedRole == UserRole.nurse) {
        response = await ApiService.registerNurse(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          profileImage: profileImage,
        );
      } else {
        response = await ApiService.registerPatient(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          roomNumber: _roomNumberController.text.trim(),
          profileImage: profileImage,
        );
      }

      if (response['success'] == true && mounted) {
        final role = response['data']['role'].toLowerCase();
        
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedRole == UserRole.nurse
                  ? 'Nurse account created successfully!'
                  : 'Patient account created successfully!',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Navigate after a short delay
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          // Navigate based on role
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

        String errorMessage = 'Registration failed';
        final errorString = e.toString().replaceAll('Exception: ', '');
        
        if (errorString.contains('timeout') || errorString.contains('Connection timeout')) {
          errorMessage = 'Connection timeout. Please check your internet connection.';
        } else if (errorString.contains('Cannot connect') || errorString.contains('SocketException')) {
          errorMessage = 'Cannot connect to server. Please check:\n• Backend is running\n• Device is on same network\n• Firewall settings';
        } else if (errorString.contains('already exists') || errorString.contains('User already exists')) {
          errorMessage = 'An account with this email already exists. Please use a different email or try logging in.';
        } else if (errorString.contains('validation') || errorString.contains('required')) {
          errorMessage = 'Please fill in all required fields correctly.';
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppLogo(size: 80),
                              const SizedBox(height: AppSpacing.s24),
                              Text(
                                'Create Account',
                                style: AppTypography.h2(context).copyWith(
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s8),
                              Text(
                                'Sign up to get started',
                                style: AppTypography.body2(context),
                              ),
                              const SizedBox(height: AppSpacing.s32),
                              // Role Selector
                              RoleSelector(
                                selectedRole: _selectedRole,
                                onRoleSelected: (role) {
                                  setState(() {
                                    _selectedRole = role;
                                  });
                                  _checkTermsAgreement();
                                },
                              ),
                              const SizedBox(height: AppSpacing.s24),
                              // Common Fields
                              TextFormField(
                                controller: _nameController,
                                validator: Validators.validateName,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: const Icon(Icons.person_outline),
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
                              const SizedBox(height: AppSpacing.s16),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                validator: Validators.validatePhone,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: const Icon(Icons.phone_outlined),
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
                              // Profile Image (Optional)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Profile Image (Optional)',
                                    style: AppTypography.body2(context).copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.s8),
                                  Row(
                                    children: [
                                      // Image preview or placeholder
                                      GestureDetector(
                                        onTap: () async {
                                          // Option 1: Image picker from gallery
                                          // For now, using URL input for simplicity
                                          // You can add image_picker functionality here if needed
                                        },
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: AppColors.lightBlue.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppColors.primaryBlue.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: _selectedProfileImageUrl != null && _selectedProfileImageUrl!.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.network(
                                                    _selectedProfileImageUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Icon(
                                                        Icons.person,
                                                        size: 40,
                                                        color: AppColors.primaryBlue,
                                                      );
                                                    },
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.add_photo_alternate,
                                                  size: 40,
                                                  color: AppColors.primaryBlue,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.s12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _profileImageController,
                                          keyboardType: TextInputType.url,
                                          decoration: InputDecoration(
                                            labelText: 'Image URL (optional)',
                                            hintText: 'https://example.com/image.jpg',
                                            prefixIcon: const Icon(Icons.image_outlined),
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
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedProfileImageUrl = value.trim().isNotEmpty ? value.trim() : null;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.s4),
                                  Text(
                                    'Enter image URL or leave empty for default avatar',
                                    style: AppTypography.caption(context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.s16),
                              // Role-specific fields
                              if (_selectedRole == UserRole.patient) ..._buildPatientFields(),
                              if (_selectedRole == UserRole.nurse) ..._buildNurseFields(),
                              const SizedBox(height: AppSpacing.s16),
                              // Password Fields
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
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                validator: (value) => Validators.validateConfirmPassword(
                                  value,
                                  _passwordController.text,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
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
                                children: [
                                  Checkbox(
                                    value: _agreeToTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _agreeToTerms = value ?? false;
                                      });
                                    },
                                    activeColor: AppColors.primaryBlue,
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => TermsScreen(
                                              userRole: _selectedRole == UserRole.nurse ? 'nurse' : 'patient',
                                              onClose: () {
                                                // Check if user has agreed to terms
                                                _checkTermsAgreement();
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'I agree to the Terms & Conditions',
                                              style: AppTypography.body2(context).copyWith(
                                                color: AppColors.primaryBlue,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ],
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
                                  onPressed: _isLoading ? null : _handleSignUp,
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
                                          _selectedRole == null
                                              ? 'Sign Up'
                                              : _selectedRole == UserRole.nurse
                                                  ? 'Sign Up as Nurse'
                                                  : 'Sign Up as Patient',
                                          style: AppTypography.button(context),
                                        ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: AppTypography.body2(context),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      'Sign In',
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
    );
  }

  List<Widget> _buildPatientFields() {
    return [
      TextFormField(
        controller: _patientIdController,
        validator: Validators.validatePatientId,
        decoration: InputDecoration(
          labelText: 'Patient ID',
          prefixIcon: const Icon(Icons.badge_outlined),
          filled: true,
          fillColor: AppColors.success.withOpacity(0.1),
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
      TextFormField(
        controller: _roomNumberController,
        validator: Validators.validateRoomNumber,
        decoration: InputDecoration(
          labelText: 'Room Number',
          prefixIcon: const Icon(Icons.room_outlined),
          filled: true,
          fillColor: AppColors.success.withOpacity(0.1),
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
      TextFormField(
        controller: _dateOfBirthController,
        validator: Validators.validateDateOfBirth,
        readOnly: true,
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() {
              _dateOfBirthController.text =
                  '${picked.day}/${picked.month}/${picked.year}';
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          filled: true,
          fillColor: AppColors.success.withOpacity(0.1),
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
      TextFormField(
        controller: _emergencyContactController,
        validator: Validators.validateEmergencyContact,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: 'Emergency Contact',
          prefixIcon: const Icon(Icons.emergency_outlined),
          filled: true,
          fillColor: AppColors.success.withOpacity(0.1),
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
    ];
  }

  // Google Places API helper
  // Note: You need to add your Google Places API key
  // Get it from: https://console.cloud.google.com/apis/credentials
  // Enable "Places API" in your Google Cloud Console
  Future<List<String>> _getPlacesSuggestions(String query) async {
    if (query.length < 3) return [];
    
    try {
      // TODO: Replace with your actual Google Places API key
      // You can store it in environment variables or a config file
      const String apiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
      
      if (apiKey == 'YOUR_GOOGLE_PLACES_API_KEY') {
        // Return empty list if API key is not configured
        // You can add fallback suggestions here if needed
        return [];
      }
      
      const String baseUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      
      // Search for hospitals and medical establishments
      final String encodedQuery = Uri.encodeComponent(query);
      final String url = '$baseUrl?input=$encodedQuery&types=hospital|establishment&key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['predictions'] != null) {
          return (data['predictions'] as List)
              .map((prediction) => prediction['description'] as String)
              .toList();
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        }
      }
    } catch (e) {
      // If API fails, return empty list
      debugPrint('Error fetching places: $e');
    }
    
    return [];
  }

  List<Widget> _buildNurseFields() {
    return [
      Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) async {
          if (textEditingValue.text.length < 3) {
            return const Iterable<String>.empty();
          }
          return await _getPlacesSuggestions(textEditingValue.text);
        },
        onSelected: (String selection) {
          setState(() {
            _locationController.text = selection;
          });
        },
        fieldViewBuilder: (
          BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted,
        ) {
          // Sync controllers
          if (fieldTextEditingController.text != _locationController.text) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              fieldTextEditingController.text = _locationController.text;
            });
          }
          
          return TextFormField(
            controller: fieldTextEditingController,
            focusNode: fieldFocusNode,
            onFieldSubmitted: (String value) {
              onFieldSubmitted();
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your location or hospital name';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'Location / Hospital Name',
              hintText: 'Type to search for hospital or location',
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: fieldTextEditingController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _locationController.clear();
                          fieldTextEditingController.clear();
                        });
                      },
                    )
                  : const Icon(Icons.search, color: AppColors.primaryBlue),
              filled: true,
              fillColor: AppColors.primaryBlue.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _locationController.text = value;
              });
            },
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: AppColors.primaryBlue),
                      title: Text(
                        option,
                        style: AppTypography.body1(context),
                      ),
                      dense: true,
                      onTap: () {
                        onSelected(option);
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
      const SizedBox(height: AppSpacing.s16),
      TextFormField(
        controller: _licenseNumberController,
        validator: Validators.validateLicenseNumber,
        decoration: InputDecoration(
          labelText: 'Nursing License Number',
          prefixIcon: const Icon(Icons.verified_user_outlined),
          filled: true,
          fillColor: AppColors.primaryBlue.withOpacity(0.1),
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
      TextFormField(
        controller: _yearsOfExperienceController,
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter years of experience';
          }
          final years = int.tryParse(value);
          if (years == null || years < 0) {
            return 'Please enter a valid number';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: 'Years of Experience',
          prefixIcon: const Icon(Icons.work_outline),
          filled: true,
          fillColor: AppColors.primaryBlue.withOpacity(0.1),
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
    ];
  }
}
