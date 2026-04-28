import 'package:flutter/material.dart';

import 'package:qrollcall_mobile/core/theme/app_colors.dart';
import 'package:qrollcall_mobile/features/live_attendance/models/live_attendance_models.dart';

class LiveAttendanceStudentTile extends StatelessWidget {
  const LiveAttendanceStudentTile({
    super.key,
    required this.student,
    required this.index,
  });

  final LiveAttendanceStudent student;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isPresent = student.isPresent;
    final hasImage =
        student.profileImageUrl != null && student.profileImageUrl!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: index.isEven ? AppColors.surface : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isPresent
                ? const Color(0xFF0B2A61)
                : const Color(0xFF2A0A11),
            backgroundImage: hasImage ? NetworkImage(student.profileImageUrl!) : null,
            child: hasImage
                ? null
                : Text(
                    student.avatarLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  student.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isPresent ? const Color(0xFF12351A) : const Color(0xFF3A1212),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPresent ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: isPresent ? const Color(0xFF57D26C) : const Color(0xFFFF7B7B),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}