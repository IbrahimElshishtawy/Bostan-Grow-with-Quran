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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF1F8F5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? GameificationColors.primaryGreen.withValues(alpha: 0.3)
              : Colors.grey[200]!,
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
            color: isCompleted ? GameificationColors.primaryGreen : Colors.grey[100],
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : icon,
            color: isCompleted ? Colors.white : Colors.grey[600],
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isCompleted ? GameificationColors.primaryGreenDark : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: isCompleted ? GameificationColors.primaryGreen : Colors.grey,
        ),
      ),
    );
  }
}
