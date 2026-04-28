import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:qrollcall_mobile/core/theme/app_colors.dart';
import 'package:qrollcall_mobile/features/live_attendance/presentation/controllers/live_attendance_controller.dart';
import 'package:qrollcall_mobile/features/live_attendance/presentation/widgets/live_attendance_student_tile.dart';

class LiveAttendanceScreen extends StatefulWidget {
  const LiveAttendanceScreen({super.key});

  @override
  State<LiveAttendanceScreen> createState() => _LiveAttendanceScreenState();
}

class _LiveAttendanceScreenState extends State<LiveAttendanceScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<LiveAttendanceController>();
      controller.load(forceRefresh: true);
      controller.startPolling();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LiveAttendanceController>();
    final snapshot = controller.snapshot;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _LiveAttendanceBackdrop(),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.primaryContainer,
              onRefresh: controller.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(true),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Live Attendance',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: controller.refresh,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (controller.isLoading && !controller.hasLoadedOnce)
                    const Padding(
                      padding: EdgeInsets.only(top: 120),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (controller.errorMessage != null && !controller.hasLoadedOnce)
                    _LiveErrorCard(
                      message: controller.errorMessage!,
                      onRetry: () => controller.load(forceRefresh: true),
                    )
                  else if (snapshot == null)
                    _LiveErrorCard(
                      message: 'No live attendance data is available for this event.',
                      onRetry: () => controller.load(forceRefresh: true),
                    )
                  else ...[
                    _LiveHeader(snapshot: snapshot),
                    const SizedBox(height: 22),
                    _RateCard(snapshot: snapshot),
                    const SizedBox(height: 18),
                    _SearchAndFilters(controller: controller),
                    const SizedBox(height: 24),
                    if (controller.selectedFilter == LiveAttendanceFilter.all) ...[
                      _SectionHeader(
                        title: 'Present Students',
                        count: controller.presentStudents.length,
                        type: _SectionHeaderType.present,
                      ),
                      const SizedBox(height: 12),
                      if (controller.presentStudents.isEmpty)
                        const _EmptyBlock(
                          title: 'No present students yet',
                          subtitle:
                              'When students scan the active QR code, they will appear here in real time.',
                        )
                      else
                        ...List.generate(
                          controller.presentStudents.length,
                          (index) => LiveAttendanceStudentTile(
                            student: controller.presentStudents[index],
                            index: index,
                          ),
                        ),
                      const SizedBox(height: 22),
                      _SectionHeader(
                        title: 'Rejected / Absent Records',
                        count: controller.issueStudents.length,
                        type: _SectionHeaderType.issue,
                      ),
                      const SizedBox(height: 12),
                      if (controller.issueStudents.isEmpty)
                        const _EmptyBlock(
                          title: 'No rejected records',
                          subtitle:
                              'Students with failed geofence/time validation will appear here.',
                        )
                      else
                        ...List.generate(
                          controller.issueStudents.length,
                          (index) => LiveAttendanceStudentTile(
                            student: controller.issueStudents[index],
                            index: index,
                          ),
                        ),
                    ] else ...[
                      _SectionHeader(
                        title: controller.selectedFilter == LiveAttendanceFilter.present
                            ? 'Present Students'
                            : 'Rejected / Absent Records',
                        count: controller.filteredStudents.length,
                        type: controller.selectedFilter == LiveAttendanceFilter.present
                            ? _SectionHeaderType.present
                            : _SectionHeaderType.issue,
                      ),
                      const SizedBox(height: 12),
                      if (controller.filteredStudents.isEmpty)
                        const _EmptyBlock(
                          title: 'No matching students',
                          subtitle:
                              'Try clearing the search box or switching the filter.',
                        )
                      else
                        ...List.generate(
                          controller.filteredStudents.length,
                          (index) => LiveAttendanceStudentTile(
                            student: controller.filteredStudents[index],
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
    );
  }
}

class _LiveHeader extends StatelessWidget {
  const _LiveHeader({
    required this.snapshot,
  });

  final dynamic snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: snapshot.isActive ? const Color(0xFFFF4B58) : AppColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              snapshot.isActive ? 'LIVE • AUTO REFRESH' : 'EVENT ENDED',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: snapshot.isActive
                        ? const Color(0xFFFF4B58)
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          snapshot.eventName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1.08,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 18,
              color: AppColors.primaryContainer,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                snapshot.locationLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.schedule_rounded,
              size: 18,
              color: AppColors.primaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              snapshot.timeLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({
    required this.snapshot,
  });

  final dynamic snapshot;

  @override
  Widget build(BuildContext context) {
    final rate = snapshot.attendanceRate / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'ATTENDANCE RATE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
              ),
              const Spacer(),
              Text(
                '${snapshot.attendanceRate}%',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.primaryContainer,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: rate.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniMetric(
                label: 'Present',
                value: '${snapshot.presentCount}',
                color: const Color(0xFF57D26C),
              ),
              const SizedBox(width: 12),
              _MiniMetric(
                label: 'Issues',
                value: '${snapshot.issueCount}',
                color: const Color(0xFFFF7B7B),
              ),
              const SizedBox(width: 12),
              _MiniMetric(
                label: 'Total',
                value: '${snapshot.totalRecords}',
                color: AppColors.primaryContainer,
              ),
            ],
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
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({
    required this.controller,
  });

  final LiveAttendanceController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: controller.setSearchQuery,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            hintText: 'Search by student name, email, or ID...',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.primaryContainer,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: AppColors.primaryContainer),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: _FilterButton(
                  label: 'All',
                  selected: controller.selectedFilter == LiveAttendanceFilter.all,
                  onTap: () => controller.setFilter(LiveAttendanceFilter.all),
                ),
              ),
              Expanded(
                child: _FilterButton(
                  label: 'Present',
                  selected: controller.selectedFilter == LiveAttendanceFilter.present,
                  onTap: () => controller.setFilter(LiveAttendanceFilter.present),
                ),
              ),
              Expanded(
                child: _FilterButton(
                  label: 'Issues',
                  selected: controller.selectedFilter == LiveAttendanceFilter.issues,
                  onTap: () => controller.setFilter(LiveAttendanceFilter.issues),
                ),
              ),
            ],
          ),
        ),
      ],
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
    return Material(
      color: selected ? AppColors.surface : Colors.transparent,
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
                    color: selected
                        ? AppColors.primaryContainer
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _SectionHeaderType {
  present,
  issue,
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.type,
  });

  final String title;
  final int count;
  final _SectionHeaderType type;

  @override
  Widget build(BuildContext context) {
    final isPresent = type == _SectionHeaderType.present;

    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isPresent ? const Color(0xFF12351A) : const Color(0xFF3A1212),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isPresent ? const Color(0xFF57D26C) : const Color(0xFFFF7B7B),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ],
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            color: AppColors.textSecondary,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class _LiveErrorCard extends StatelessWidget {
  const _LiveErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF48222A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unable to load live attendance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _LiveAttendanceBackdrop extends StatelessWidget {
  const _LiveAttendanceBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -130,
          left: MediaQuery.of(context).size.width * 0.16,
          child: Container(
            width: 300,
            height: 300,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x221B4FD3),
            ),
          ),
        ),
        Positioned(
          right: -90,
          top: 230,
          child: Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x14133EAF),
            ),
          ),
        ),
        Positioned(
          left: -90,
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