import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../screens/login_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentBottomNavIndex = 1;
  bool _isUpdatingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getCurrentUser();
      
      if (mounted && response['success'] == true) {
        setState(() {
          _userData = response['data'] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      
      // Check if it's a 401/authentication error
      if (errorMsg.contains('401') || 
          errorMsg.contains('Not authenticated') || 
          errorMsg.contains('Session expired')) {
        // Navigate to login
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }
      
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Clear token via API service
      await ApiService.logout();
      
      // Clear auth service state
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      
      if (!mounted) return;
      
      // Navigate to login and clear navigation stack
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _pickProfileImage(BuildContext context, AuthService authService) async {
    try {
      // Show image source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      setState(() {
        _isUpdatingImage = true;
      });

      // Request permissions first
      bool hasPermission = false;
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        hasPermission = status.isGranted;
        if (!hasPermission) {
          if (mounted) {
            setState(() {
              _isUpdatingImage = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Camera permission is required. Please grant permission in app settings.'),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return;
        }
      } else {
        // For gallery, check storage permission
        PermissionStatus status;
        if (await Permission.photos.isRestricted) {
          status = await Permission.storage.request();
        } else {
          status = await Permission.photos.request();
          if (status.isDenied) {
            status = await Permission.storage.request();
          }
        }
        hasPermission = status.isGranted;
        if (!hasPermission) {
          if (mounted) {
            setState(() {
              _isUpdatingImage = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Storage permission is required. Please grant permission in app settings.'),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return;
        }
      }

      // Pick image with better error handling
      XFile? pickedFile;
      try {
        // Use a fresh ImagePicker instance to avoid channel issues
        // Allow all image formats (JPEG, PNG, GIF, WEBP, etc.)
        final ImagePicker picker = ImagePicker();
        pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
          // Don't force format - preserve original format
        );
      } catch (e) {
        // Handle platform-specific errors
        if (mounted) {
          setState(() {
            _isUpdatingImage = false;
          });
          
          String errorMessage = 'Failed to pick image';
          if (e.toString().contains('permission')) {
            errorMessage = 'Permission denied. Please grant camera/storage permission in app settings.';
          } else if (e.toString().contains('channel') || e.toString().contains('pigeon')) {
            errorMessage = 'Image picker error. Please:\n1. Stop the app completely\n2. Rebuild the app (flutter run)\n3. Try again';
          } else {
            errorMessage = 'Failed to pick image: ${e.toString().replaceAll('Exception: ', '').replaceAll('PlatformException: ', '')}';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      // Convert image to base64 with proper format detection
      final File imageFile = File(pickedFile!.path);
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      
      // Detect image format from file extension or MIME type
      String mimeType = 'image/jpeg'; // default
      final String fileExtension = pickedFile.path.toLowerCase().split('.').last;
      
      switch (fileExtension) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'bmp':
          mimeType = 'image/bmp';
          break;
        case 'heic':
        case 'heif':
          mimeType = 'image/heic';
          break;
        default:
          mimeType = 'image/jpeg'; // fallback to JPEG
      }
      
      final String imageDataUrl = 'data:$mimeType;base64,$base64Image';

      // Upload to backend
      final response = await ApiService.updateProfileImage(imageDataUrl);

      if (response['success'] == true && mounted) {
        // Validate response structure
        if (response['data'] == null) {
          throw Exception('Invalid response: data field is missing');
        }
        
        final updatedProfileImage = response['data']['profileImage'];
        
        if (updatedProfileImage == null || updatedProfileImage.toString().isEmpty) {
          throw Exception('Profile image was not returned from server');
        }
        
        // Update AuthService first
        await authService.updateProfileImage(updatedProfileImage);

        // Update local _userData immediately
        setState(() {
          if (_userData != null) {
            _userData!['profileImage'] = updatedProfileImage;
          }
        });

        // Refresh user data from API to ensure consistency
        await _loadUserData();

        if (mounted) {
          // Force UI rebuild
          setState(() {});
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile photo updated! Please restart the app to see the change.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile photo: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingImage = false;
        });
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).pushReplacementNamed('/patient/home');
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            'My Profile',
            style: AppTypography.h2(context).copyWith(
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.danger,
                          ),
                          const SizedBox(height: AppSpacing.s16),
                          Text(
                            'Failed to load profile',
                            style: AppTypography.h3(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            _errorMessage!,
                            style: AppTypography.body2(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.s24),
                          ElevatedButton.icon(
                            onPressed: _loadUserData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.s24),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.s40),
                        // Profile Image from AuthService or API (Clickable)
                        Consumer<AuthService>(
                          builder: (context, authService, child) {
                            final userName = authService.userName ?? _userData?['name'] ?? 'User';
                            // Get profile image with priority: AuthService > _userData > default
                            String profileImage = authService.userProfileImage ?? 
                                _userData?['profileImage'] ?? 
                                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&background=0D8ABC&color=fff';
                            
                            // Add cache-busting parameter to force image refresh
                            if (profileImage.contains('data:image') || profileImage.contains('ui-avatars.com')) {
                              // For base64 or default images, no cache-busting needed
                            } else {
                              // Add timestamp to force refresh
                              final separator = profileImage.contains('?') ? '&' : '?';
                              profileImage = '$profileImage${separator}t=${DateTime.now().millisecondsSinceEpoch}';
                            }
                            
                            return GestureDetector(
                              onTap: _isUpdatingImage ? null : () => _pickProfileImage(context, authService),
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                                    backgroundImage: NetworkImage(profileImage),
                                    onBackgroundImageError: (exception, stackTrace) {
                                      // Image load error handled by fallback
                                      print('Image load error: $exception');
                                    },
                                  ),
                                  if (_isUpdatingImage)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.surface,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.s24),
                        // Name from AuthService or API
                        Consumer<AuthService>(
                          builder: (context, authService, child) {
                            final userName = authService.userName ?? _userData?['name'] ?? 'Unknown';
                            return Text(
                              userName,
                              style: AppTypography.h2(context),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        // Role badge from AuthService or API
                        Consumer<AuthService>(
                          builder: (context, authService, child) {
                            final userRole = (authService.userRole ?? _userData?['role'] ?? 'PATIENT').toUpperCase();
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s16,
                                vertical: AppSpacing.s8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.success,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                userRole,
                                style: AppTypography.body2(context).copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.s24),
                        // Info Card
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.s24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Consumer<AuthService>(
                                builder: (context, authService, child) {
                                  final userEmail = authService.userEmail ?? _userData?['email'] ?? 'N/A';
                                  return _buildInfoRow(
                                    context,
                                    Icons.email,
                                    'Email',
                                    userEmail,
                                  );
                                },
                              ),
                              const Divider(height: AppSpacing.s24),
                              if (_userData?['assignedDevice'] != null)
                                _buildInfoRow(
                                  context,
                                  Icons.devices,
                                  'Assigned Device',
                                  _userData!['assignedDevice'],
                                ),
                              if (_userData?['assignedDevice'] != null)
                                const Divider(height: AppSpacing.s24),
                              _buildInfoRow(
                                context,
                                Icons.calendar_today,
                                'Member Since',
                                _formatDate(_userData?['createdAt']),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s24),
                        // Logout Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.danger,
                                AppColors.danger.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.danger.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _handleLogout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Theme.of(context).colorScheme.onError,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.logout, size: 22),
                                const SizedBox(width: AppSpacing.s8),
                                Text(
                                  'Logout',
                                  style: AppTypography.button(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentBottomNavIndex,
            onDestinationSelected: (index) {
              if (_currentBottomNavIndex == index) return;
              setState(() {
                _currentBottomNavIndex = index;
              });
              if (!mounted) return;
              switch (index) {
                case 0:
                  Navigator.of(context).pushReplacementNamed('/patient/home');
                  break;
                case 1:
                  // Already on profile
                  break;
              }
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: AppColors.primaryBlue.withOpacity(0.2),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryBlue,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.s16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption(context),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTypography.body1(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
