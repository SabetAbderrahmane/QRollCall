import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:qrollcall_mobile/core/theme/app_colors.dart';
import 'package:qrollcall_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:qrollcall_mobile/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:qrollcall_mobile/features/dashboard/presentation/widgets/dashboard_stat_card.dart';
import 'package:qrollcall_mobile/features/dashboard/presentation/widgets/upcoming_class_tile.dart';
import 'package:qrollcall_mobile/features/qr_scanner/data/qr_scanner_api_service.dart';
import 'package:qrollcall_mobile/features/qr_scanner/models/scan_result_models.dart';
import 'package:qrollcall_mobile/features/qr_scanner/presentation/controllers/qr_scanner_controller.dart';
import 'package:qrollcall_mobile/features/qr_scanner/presentation/screens/qr_scanner_screen.dart';
import 'package:qrollcall_mobile/features/qr_scanner/presentation/screens/scan_failure_screen.dart';
import 'package:qrollcall_mobile/features/qr_scanner/presentation/screens/scan_success_screen.dart';
import 'package:qrollcall_mobile/models/event_item.dart';
import 'package:qrollcall_mobile/features/attendance_history/data/attendance_history_api_service.dart';
import 'package:qrollcall_mobile/features/attendance_history/presentation/controllers/attendance_history_controller.dart';
import 'package:qrollcall_mobile/features/attendance_history/presentation/screens/attendance_history_screen.dart';
import 'package:qrollcall_mobile/features/auth/data/firebase_auth_service.dart';
import 'package:qrollcall_mobile/features/profile/presentation/screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const List<_DashboardTab> _tabs = [
    _DashboardTab(
      id: 'home',
      label: 'Home',
      icon: Icons.home_rounded,
    ),
    _DashboardTab(
      id: 'history',
      label: 'History',
      icon: Icons.history_rounded,
    ),
    _DashboardTab(
      id: 'classes',
      label: 'Classes',
      icon: Icons.menu_book_rounded,
    ),
    _DashboardTab(
      id: 'profile',
      label: 'Profile',
      icon: Icons.person_rounded,
    ),
  ];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final dashboardController = context.watch<DashboardController>();
    final user = authController.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _DashboardBottomBar(
        selectedIndex: _selectedIndex,
        tabs: _tabs,
        onTap: _handleBottomTabTap,
      ),
      body: Stack(
        children: [
          const _DashboardBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _DashboardHeader(
                  title:
                      '${_greeting()}, ${_firstName(user?.fullName ?? 'User')}',
                  unreadCount: dashboardController.unreadNotificationCount,
                  profileImageUrl: user?.profileImageUrl,
                  initials: _initials(user?.fullName ?? 'QRollCall'),
                  onNotificationsTap: _handleNotificationsTap,
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryContainer,
                    backgroundColor: AppColors.surfaceContainerLow,
                    onRefresh: () => dashboardController.refreshDashboard(),
                    child: dashboardController.isLoading &&
                            !dashboardController.hasLoadedOnce
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                            children: [
                              if (dashboardController.errorMessage != null &&
                                  !dashboardController.hasLoadedOnce)
                                _ErrorCard(
                                  message: dashboardController.errorMessage!,
                                  onRetry: () => context
                                      .read<DashboardController>()
                                      .loadDashboard(forceRefresh: true),
                                )
                              else ...[
                                _StatsGrid(controller: dashboardController),
                                const SizedBox(height: 18),
                                _ScanCallToAction(onTap: _handleScanTap),
                                const SizedBox(height: 24),
                                if (kDebugMode) ...[
                                  _ScanPreviewTestingPanel(
                                    onOpenSuccessPreview:
                                        _openSuccessPreviewFromDashboard,
                                    onOpenFailurePreview:
                                        _openFailurePreviewFromDashboard,
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                _UpcomingClassesSection(
                                  events: dashboardController.upcomingEvents,
                                  onSeeAllTap: () => _showSoonMessage(
                                    'Classes screen will be built in the next batch.',
                                  ),
                                ),
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

  Future<void> _handleBottomTabTap(int index) async {
    if (index == 0) {
      setState(() => _selectedIndex = index);
      return;
    }

    if (index == 1) {
      await _openAttendanceHistory();
      return;
    }

    if (index == 3) {
      await _openProfile();
      return;
    }

    _showSoonMessage(
      '${_tabs[index].label} page will be added in the next batch.',
    );
  }

  Future<void> _handleScanTap() async {
    final result = await Navigator.of(context).push<ScanFlowExitAction>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => QrScannerController(
            qrScannerApiService: context.read<QrScannerApiService>(),
          ),
          child: const QrScannerScreen(),
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    switch (result) {
      case ScanFlowExitAction.retry:
        await _handleScanTap();
        break;
      case ScanFlowExitAction.openHistory:
        await _openAttendanceHistory();
        break;
      case ScanFlowExitAction.done:
      case ScanFlowExitAction.home:
        break;
    }
  }

  Future<void> _openAttendanceHistory() async {
    final result = await Navigator.of(context).push<AttendanceHistoryExitAction>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => AttendanceHistoryController(
            apiService: AttendanceHistoryApiService(
              firebaseAuthService: context.read<FirebaseAuthService>(),
            ),
          )..loadHistory(),
          child: const AttendanceHistoryScreen(),
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    switch (result) {
      case AttendanceHistoryExitAction.home:
        return;
      case AttendanceHistoryExitAction.scan:
        await _handleScanTap();
        break;
      case AttendanceHistoryExitAction.profile:
        await _openProfile();
        break;
    }
  }

  Future<void> _openProfile() async {
    final result = await Navigator.of(context).push<ProfileExitAction>(
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    switch (result) {
      case ProfileExitAction.home:
        setState(() => _selectedIndex = 0);
        break;
      case ProfileExitAction.scan:
        await _handleScanTap();
        break;
      case ProfileExitAction.history:
        await _openAttendanceHistory();
        break;
    }
  }

  Future<void> _openSuccessPreviewFromDashboard() async {
    final result = await Navigator.of(context).push<ScanFlowExitAction>(
      MaterialPageRoute(
        builder: (_) => ScanSuccessScreen(
          data: ScanSuccessViewData(
            eventName: 'Software Engineering Lecture',
            verifiedAt: DateTime.now(),
            statusLabel: 'Verified Present',
            locationLabel: 'Location verified inside 100m geofence',
            eventId: 1,
          ),
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result == ScanFlowExitAction.openHistory) {
      _showSoonMessage('Attendance history page will be built in the next batch.');
    }
  }

  Future<void> _openFailurePreviewFromDashboard() async {
    final result = await Navigator.of(context).push<ScanFlowExitAction>(
      MaterialPageRoute(
        builder: (_) => const ScanFailureScreen(
          data: ScanFailureViewData(
            headline: 'Invalid QR Code',
            badgeLabel: 'Verification Error',
            summary:
                'The scanned code is not recognized by the current event registry.',
            reasons: [
              ScanFailureReasonItem(
                iconKind: ScanFailureIconKind.qrCode,
                title: 'Token not recognized',
                description:
                    'The event QR code may be expired, corrupted, or generated for a different session.',
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result == ScanFlowExitAction.retry) {
      await _handleScanTap();
    }
  }

  void _handleNotificationsTap() {
    _showSoonMessage('Notifications page will be added in the next batch.');
  }

  void _showSoonMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  static String _firstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? 'User' : parts.first;
  }

  static String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'Q';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.title,
    required this.unreadCount,
    required this.profileImageUrl,
    required this.initials,
    required this.onNotificationsTap,
  });

  final String title;
  final int unreadCount;
  final String? profileImageUrl;
  final String initials;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        profileImageUrl != null && profileImageUrl!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceContainerLow,
                backgroundImage: hasImage ? NetworkImage(profileImageUrl!) : null,
                child: hasImage
                    ? null
                    : Text(
                        initials,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.background,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Material(
            color: AppColors.surfaceContainerLow.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: onNotificationsTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surfaceContainerLow,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final nextEvent = controller.nextEvent;

    return Column(
      children: [
        SizedBox(
          height: 210,
          child: Row(
            children: [
              Expanded(
                child: _AttendanceRateCard(
                  percentage: controller.attendanceRatePercentage,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DashboardStatCard(
                  title: 'Classes Attended',
                  value: '${controller.monthlyAttendancePresentCount}',
                  trailing: ' / ${controller.monthlyAttendanceTotalCount}',
                  caption: 'THIS MONTH',
                  highlightColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: nextEvent == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Event',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active events yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Once an organizer creates upcoming sessions, they will appear here.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Event',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      nextEvent.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _buildEventMeta(nextEvent),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  static String _buildEventMeta(EventItem event) {
    final location = (event.locationName?.trim().isNotEmpty ?? false)
        ? event.locationName!.trim()
        : 'Location not set';

    return '$location • ${_formatEventDate(event.startTime)}';
  }

  static String _formatEventDate(DateTime value) {
    final now = DateTime.now();
    final isToday = value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;

    if (isToday) {
      return '${_formatTime(value)} Today';
    }

    return '${_monthShort(value.month)} ${value.day}, ${_formatTime(value)}';
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
            ? value.hour - 12
            : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  static String _monthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}

class _AttendanceRateCard extends StatelessWidget {
  const _AttendanceRateCard({required this.percentage});

  final int percentage;

  @override
  Widget build(BuildContext context) {
    final value = (percentage.clamp(0, 100)) / 100;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Attendance Rate',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 104,
                  height: 104,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 10,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryContainer,
                    ),
                  ),
                ),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ScanCallToAction extends StatelessWidget {
  const _ScanCallToAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(32),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryContainer,
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.primaryGlow,
              blurRadius: 34,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 22),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Scan QR Code',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Log attendance instantly',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFD8E4FF),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanPreviewTestingPanel extends StatelessWidget {
  const _ScanPreviewTestingPanel({
    required this.onOpenSuccessPreview,
    required this.onOpenFailurePreview,
  });

  final VoidCallback onOpenSuccessPreview;
  final VoidCallback onOpenFailurePreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temporary Scanner UI Testing',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'These buttons are only for previewing the QR success and failure screens without camera or backend scanning.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpenSuccessPreview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Open Success Preview'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpenFailurePreview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.error_outline_rounded),
              label: const Text('Open Failure Preview'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingClassesSection extends StatelessWidget {
  const _UpcomingClassesSection({
    required this.events,
    required this.onSeeAllTap,
  });

  final List<EventItem> events;
  final VoidCallback onSeeAllTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Upcoming Classes',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            TextButton(
              onPressed: onSeeAllTap,
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              'No upcoming classes available right now.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          )
        else
          ...events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: UpcomingClassTile(
                icon: _iconForEvent(event.name),
                title: event.name,
                subtitle: _subtitleForEvent(event),
                timeLabel: _timeLabel(event.startTime),
                isUpcoming: event.startTime.isAfter(DateTime.now()),
                onTap: onSeeAllTap,
              ),
            ),
          ),
      ],
    );
  }

  static IconData _iconForEvent(String name) {
    final normalized = name.toLowerCase();

    if (normalized.contains('design')) {
      return Icons.palette_outlined;
    }
    if (normalized.contains('software') || normalized.contains('engineering')) {
      return Icons.code_rounded;
    }
    if (normalized.contains('data') || normalized.contains('analytics')) {
      return Icons.bar_chart_rounded;
    }
    if (normalized.contains('mobile')) {
      return Icons.phone_android_rounded;
    }

    return Icons.menu_book_rounded;
  }

  static String _subtitleForEvent(EventItem event) {
    final location = (event.locationName?.trim().isNotEmpty ?? false)
        ? event.locationName!.trim()
        : 'Location not set';

    return '$location • ${_monthShort(event.startTime.month)} ${event.startTime.day}';
  }

  static String _timeLabel(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
            ? value.hour - 12
            : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  static String _monthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}

class _DashboardBackdrop extends StatelessWidget {
  const _DashboardBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -170,
          left: MediaQuery.of(context).size.width * 0.18,
          child: Container(
            width: 320,
            height: 320,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x221B4FD3),
            ),
          ),
        ),
        Positioned(
          left: -140,
          bottom: -140,
          child: Container(
            width: 300,
            height: 300,
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

class _DashboardBottomBar extends StatelessWidget {
  const _DashboardBottomBar({
    required this.selectedIndex,
    required this.tabs,
    required this.onTap,
  });

  final int selectedIndex;
  final List<_DashboardTab> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow.withValues(alpha: 0.93),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 28,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final isActive = index == selectedIndex;

            return InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primarySoft
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        tab.icon,
                        size: 22,
                        color: isActive
                            ? AppColors.primaryContainer
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: isActive ? 1 : 0,
                      child: Text(
                        tab.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primaryContainer,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unable to load dashboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _DashboardTab {
  const _DashboardTab({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}