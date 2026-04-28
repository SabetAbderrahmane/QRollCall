import 'package:flutter/material.dart';

import 'package:qrollcall_mobile/core/theme/app_colors.dart';

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    this.trendLabel,
    this.accentColor = AppColors.primaryContainer,
    this.trailingIcon,
    this.showPulse = false,
  });

  final String label;
  final String value;
  final String? trendLabel;
  final Color accentColor;
  final IconData? trailingIcon;
  final bool showPulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
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
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
              ),
              if (trendLabel != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    trendLabel!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF57D26C),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
              if (showPulse) ...[
                const SizedBox(width: 8),
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF57D26C),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              const Spacer(),
              if (trailingIcon != null)
                Icon(
                  trailingIcon,
                  color: accentColor.withValues(alpha: 0.8),
                  size: 20,
                ),
            ],
          ),
        ],
      ),
    );
  }
}