import 'package:flutter/material.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isLarge;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isLarge ? AppSpacing.s24 : AppSpacing.s20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: isLarge ? 28 : 24,
            ),
          ),
          SizedBox(height: isLarge ? AppSpacing.s16 : AppSpacing.s12),
          Text(
            title,
            style: AppTypography.body2(context),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            value,
            style: AppTypography.h3(context).copyWith(
              color: color,
              fontSize: isLarge ? 28 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

