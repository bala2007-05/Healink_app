import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

enum UserRole { nurse, patient }

class RoleSelector extends StatefulWidget {
  final UserRole? selectedRole;
  final Function(UserRole) onRoleSelected;

  const RoleSelector({
    super.key,
    this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  State<RoleSelector> createState() => _RoleSelectorState();
}

class _RoleSelectorState extends State<RoleSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.selectedRole;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectRole(UserRole role) {
    setState(() {
      _selectedRole = role;
    });
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onRoleSelected(role);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildRoleCard(
            context,
            role: UserRole.nurse,
            icon: Icons.local_hospital,
            title: 'Nurse',
            color: AppColors.primaryBlue,
            isSelected: _selectedRole == UserRole.nurse,
          ),
        ),
        const SizedBox(width: AppSpacing.s16),
        Expanded(
          child: _buildRoleCard(
            context,
            role: UserRole.patient,
            icon: Icons.favorite,
            title: 'Caretaker',
            color: AppColors.success,
            isSelected: _selectedRole == UserRole.patient,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required UserRole role,
    required IconData icon,
    required String title,
    required Color color,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _selectRole(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.s20),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : Theme.of(context).colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          children: [
            // Show images for both roles
            Container(
              width: 70,
              height: 70,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: role == UserRole.nurse
                    ? Image.asset(
                        'assets/nurse_image.jpg',
                        width: 62,
                        height: 62,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.3),
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(AppSpacing.s16),
                            decoration: BoxDecoration(
                              color: color.withOpacity(isSelected ? 0.2 : 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: color,
                              size: 32,
                            ),
                          );
                        },
                      )
                    : Image.asset(
                        'assets/patient_image.jpg',
                        width: 62,
                        height: 62,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.3),
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(AppSpacing.s16),
                            decoration: BoxDecoration(
                              color: color.withOpacity(isSelected ? 0.2 : 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: color,
                              size: 32,
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              title,
              style: AppTypography.body1(context).copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

