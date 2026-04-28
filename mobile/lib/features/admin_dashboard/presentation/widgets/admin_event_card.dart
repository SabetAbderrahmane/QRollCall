import 'package:flutter/material.dart';

import 'package:qrollcall_mobile/core/theme/app_colors.dart';
import 'package:qrollcall_mobile/features/admin_dashboard/models/admin_dashboard_models.dart';

class AdminEventCard extends StatelessWidget {
  const AdminEventCard({
    super.key,
    required this.event,
    required this.now,
    this.onEditTap,
  });

  final AdminEventSummary event;
  final DateTime now;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final isLive = event.isLiveAt(now);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _EventBadge(
                label: event.badgeLabel(now),
                isLive: isLive,
              ),
              const Spacer(),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2A61),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isLive ? Icons.qr_code_scanner_rounded : Icons.more_vert_rounded,
                  color: AppColors.primaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            event.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            event.subtitle(now),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 20),
          if (isLive) ...[
            Row(
              children: [
                Text(
                  'Student Attendance',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.labelLarge,
                    children: [
                      TextSpan(
                        text: '${event.presentCount}',
                        style: const TextStyle(
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: '/${event.totalRecords}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: event.attendanceProgress,
                backgroundColor: const Color(0xFF172036),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryContainer,
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                ...event.previewAudienceChips().map(
                  (chip) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF18233B),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        chip,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: onEditTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    backgroundColor: const Color(0xFF18233B),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Edit Details'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EventBadge extends StatelessWidget {
  const _EventBadge({
    required this.label,
    required this.isLive,
  });

  final String label;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFF12351A) : const Color(0xFF18233B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF57D26C),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isLive ? const Color(0xFF57D26C) : AppColors.textSecondary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
          ),
        ],
      ),
    );
  }
}