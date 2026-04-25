import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:qrollcall_mobile/features/attendance_history/presentation/controllers/attendance_history_controller.dart';
import 'package:qrollcall_mobile/features/attendance_history/presentation/widgets/attendance_history_empty_state.dart';
import 'package:qrollcall_mobile/features/attendance_history/presentation/widgets/attendance_history_record_tile.dart';
import 'package:qrollcall_mobile/features/auth/presentation/controllers/auth_controller.dart';

enum AttendanceHistoryExitAction {
  home,
  scan,
  profile,
}

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  static const Color _pageBackground = Color(0xFF020617);
  static const Color _brandBlue = Color(0xFF0040A1);
  static const Color _brandBlueBright = Color(0xFF0056D2);
  static const Color _surface = Color(0xFF0F172A);
  static const Color _surfaceElevated = Color(0xFF111827);
  static const Color _outlineVariant = Color(0xFF1E293B);
  static const Color _textPrimary = Color(0xFFF8FAFC);
  static const Color _textSecondary = Color(0xFF94A3B8);
  static const Color _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AttendanceHistoryController>();
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;

    return Scaffold(
      backgroundColor: _pageBackground,
      bottomNavigationBar: _HistoryBottomBar(
        onHomeTap: () =>
            Navigator.of(context).pop(AttendanceHistoryExitAction.home),
        onScanTap: () =>
            Navigator.of(context).pop(AttendanceHistoryExitAction.scan),
        onProfileTap: () =>
            Navigator.of(context).pop(AttendanceHistoryExitAction.profile),
      ),
      body: Stack(
        children: [
          const _HistoryBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _HistoryTopBar(
                  initials: _initials(user?.fullName ?? 'QR'),
                  profileImageUrl: user?.profileImageUrl,
                ),
                Expanded(
                  child: controller.isLoading && !controller.hasLoadedOnce
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : RefreshIndicator(
                          color: _brandBlueBright,
                          onRefresh: controller.refreshHistory,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                            children: [
                              if (controller.errorMessage != null &&
                                  !controller.hasLoadedOnce)
                                _ErrorCard(
                                  message: controller.errorMessage!,
                                  onRetry: () =>
                                      controller.loadHistory(forceRefresh: true),
                                )
                              else ...[
                                if (controller.hasAnyRecords) ...[
                                  _AttendanceOverviewCard(
                                    percentage: controller.attendancePercentage,
                                    performanceLabel: controller.performanceLabel,
                                    presentCount: controller.presentCount,
                                    totalCount: controller.totalCount,
                                  ),
                                  const SizedBox(height: 20),
                                ] else ...[
                                  Text(
                                    'Attendance History',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: _textPrimary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                _FilterTabs(
                                  selectedFilter: controller.selectedFilter,
                                  onChanged: controller.setFilter,
                                ),
                                const SizedBox(height: 20),
                                if (controller.filteredEntries.isEmpty)
                                  AttendanceHistoryEmptyState(
                                    title: controller.emptyStateTitle,
                                    subtitle: controller.emptyStateSubtitle,
                                    showPrimaryAction:
                                        controller.shouldShowPrimaryEmptyAction,
                                    onPrimaryAction: controller
                                            .shouldShowPrimaryEmptyAction
                                        ? () => Navigator.of(context).pop(
                                              AttendanceHistoryExitAction.scan,
                                            )
                                        : null,
                                  )
                                else ...[
                                  Text(
                                    'Recent Records',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: _textPrimary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 14),
                                  ...List.generate(
                                    controller.filteredEntries.length,
                                    (index) => AttendanceHistoryRecordTile(
                                      entry: controller.filteredEntries[index],
                                      index: index,
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'QR';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _HistoryBackdrop extends StatelessWidget {
  const _HistoryBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -150,
          left: MediaQuery.of(context).size.width * 0.12,
          child: Container(
            width: 290,
            height: 290,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x221B4FD3),
            ),
          ),
        ),
        Positioned(
          right: -110,
          top: 180,
          child: Container(
            width: 240,
            height: 240,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x14133EAF),
            ),
          ),
        ),
        Positioned(
          left: -80,
          bottom: -120,
          child: Container(
            width: 260,
            height: 260,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x22133EAF),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryTopBar extends StatelessWidget {
  const _HistoryTopBar({
    required this.initials,
    required this.profileImageUrl,
  });

  final String initials;
  final String? profileImageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        profileImageUrl != null && profileImageUrl!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menu panel will be added in a later batch.'),
                ),
              );
            },
            style: IconButton.styleFrom(
              backgroundColor: AttendanceHistoryScreen._surface,
              side: const BorderSide(
                color: AttendanceHistoryScreen._outlineVariant,
              ),
            ),
            icon: const Icon(
              Icons.menu_rounded,
              color: AttendanceHistoryScreen._brandBlueBright,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Attendance Registry',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AttendanceHistoryScreen._textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF0B2A61),
            backgroundImage: hasImage ? NetworkImage(profileImageUrl!) : null,
            child: hasImage
                ? null
                : Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceOverviewCard extends StatelessWidget {
  const _AttendanceOverviewCard({
    required this.percentage,
    required this.performanceLabel,
    required this.presentCount,
    required this.totalCount,
  });

  final int percentage;
  final String performanceLabel;
  final int presentCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final onTrack = percentage >= 75;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AttendanceHistoryScreen._surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AttendanceHistoryScreen._outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Attendance',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AttendanceHistoryScreen._textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$percentage',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AttendanceHistoryScreen._textPrimary,
                            fontWeight: FontWeight.w900,
                            height: 0.95,
                          ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        '%',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AttendanceHistoryScreen._textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: onTrack
                        ? const Color(0xFF12351A)
                        : const Color(0xFF3C2C12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        onTrack
                            ? Icons.check_circle_rounded
                            : Icons.info_rounded,
                        size: 18,
                        color: onTrack
                            ? const Color(0xFF57D26C)
                            : const Color(0xFFFFC266),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        performanceLabel,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: onTrack
                                  ? const Color(0xFF57D26C)
                                  : const Color(0xFFFFC266),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 88,
            child: Column(
              children: [
                _MiniMetric(
                  label: 'Present',
                  value: '$presentCount',
                  foreground: const Color(0xFF57D26C),
                  background: const Color(0xFF12351A),
                ),
                const SizedBox(height: 10),
                _MiniMetric(
                  label: 'Total',
                  value: '$totalCount',
                  foreground: AttendanceHistoryScreen._brandBlueBright,
                  background: const Color(0xFF0B2A61),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.foreground,
    required this.background,
  });

  final String label;
  final String value;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.selectedFilter,
    required this.onChanged,
  });

  final AttendanceHistoryFilter selectedFilter;
  final ValueChanged<AttendanceHistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AttendanceHistoryScreen._surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AttendanceHistoryScreen._outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterButton(
              label: 'All',
              selected: selectedFilter == AttendanceHistoryFilter.all,
              onTap: () => onChanged(AttendanceHistoryFilter.all),
            ),
          ),
          Expanded(
            child: _FilterButton(
              label: 'Present',
              selected: selectedFilter == AttendanceHistoryFilter.present,
              onTap: () => onChanged(AttendanceHistoryFilter.present),
            ),
          ),
          Expanded(
            child: _FilterButton(
              label: 'Absent',
              selected: selectedFilter == AttendanceHistoryFilter.absent,
              onTap: () => onChanged(AttendanceHistoryFilter.absent),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = AttendanceHistoryScreen._brandBlueBright;
    final idleColor = AttendanceHistoryScreen._textSecondary;

    return Material(
      color: selected
          ? AttendanceHistoryScreen._surface
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? selectedColor : idleColor,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryBottomBar extends StatelessWidget {
  const _HistoryBottomBar({
    required this.onHomeTap,
    required this.onScanTap,
    required this.onProfileTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onScanTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AttendanceHistoryScreen._surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: AttendanceHistoryScreen._outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BottomNavItem(
              icon: Icons.grid_view_rounded,
              label: 'Home',
              selected: false,
              onTap: onHomeTap,
            ),
            _BottomNavItem(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan',
              selected: false,
              onTap: onScanTap,
            ),
            _BottomNavItem(
              icon: Icons.history_edu_rounded,
              label: 'History',
              selected: true,
              onTap: () {},
            ),
            _BottomNavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              selected: false,
              onTap: onProfileTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = AttendanceHistoryScreen._brandBlueBright;
    final idleColor = AttendanceHistoryScreen._textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? selectedColor : idleColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? selectedColor : idleColor,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AttendanceHistoryScreen._surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF48222A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unable to load attendance history',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AttendanceHistoryScreen._textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AttendanceHistoryScreen._textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AttendanceHistoryScreen._brandBlueBright,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}