import 'package:flutter/material.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isCompleted,
    required this.onTap,
    super.key,
  });

  final int index;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isCompleted
        ? (isDark ? cs.primary.withValues(alpha: 0.1) : const Color(0xFFF1F8F5))
        : cs.surfaceContainerLow;
    
    final borderColor = isCompleted
        ? GameificationColors.primaryGreen.withValues(alpha: 0.3)
        : cs.outlineVariant.withValues(alpha: 0.4);

    final iconBg = isCompleted
        ? GameificationColors.primaryGreen
        : cs.surfaceContainerHighest;

    final iconColor = isCompleted
        ? Colors.white
        : cs.onSurfaceVariant;

    final titleColor = isCompleted
        ? (isDark ? GameificationColors.primaryGreenLight : GameificationColors.primaryGreenDark)
        : cs.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconBg,
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : icon,
            color: iconColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11, 
            color: cs.onSurfaceVariant.withValues(alpha: 0.7), 
            fontWeight: FontWeight.bold
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: isCompleted ? GameificationColors.primaryGreen : cs.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
