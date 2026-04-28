import 'package:flutter/material.dart';

import 'package:qrollcall_mobile/core/theme/app_colors.dart';
import 'package:qrollcall_mobile/features/admin_dashboard/models/admin_dashboard_models.dart';

class AdminActivityTile extends StatelessWidget {
  const AdminActivityTile({
    super.key,
    required this.activity,
    required this.now,
    required this.index,
  });

  final AdminRecentScanActivity activity;
  final DateTime now;
  final int index;

  @override
  Widget build(BuildContext context) {
    final verified = activity.isVerified;

    return Opacity(
      opacity: index == 0 ? 1 : (1 - (index * 0.08)).clamp(0.56, 1.0),
      child: Padding(
        padding: EdgeInsets.only(bottom: index == 7 ? 0 : 16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: verified ? const Color(0xFF12351A) : const Color(0xFF18233B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                verified ? Icons.verified_user_rounded : Icons.person_outline_rounded,
                color: verified ? const Color(0xFF57D26C) : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.userLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Joined ${activity.eventName} • ${activity.relativeTime(now)}',
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
            Text(
              activity.statusLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: verified ? const Color(0xFF57D26C) : const Color(0xFFFF7B7B),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}