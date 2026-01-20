import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? iconColor;
  final bool useImage;
  
  const AppLogo({
    super.key,
    this.size = 120,
    this.showText = false,
    this.iconColor,
    this.useImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: useImage ? null : AppColors.cardGradient,
            color: useImage ? Colors.transparent : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: useImage
              ? ClipOval(
                  child: Image.asset(
                    'assets/logo.jpg',
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultIcon(context);
                    },
                  ),
                )
              : _buildDefaultIcon(context),
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => AppColors.cardGradient.createShader(bounds),
            child: Text(
              'HEALINK',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultIcon(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: size * 0.9,
          height: size * 0.9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // Main icon
        Icon(
          Icons.medical_services_rounded,
          size: size * 0.5,
          color: iconColor ?? Theme.of(context).colorScheme.onPrimary,
        ),
        // Pulse effect
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
      ],
    );
  }
}

