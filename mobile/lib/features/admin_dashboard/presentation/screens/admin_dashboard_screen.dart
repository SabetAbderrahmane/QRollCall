import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:qrollcall_mobile/core/theme/app_colors.dart';
import 'package:qrollcall_mobile/features/admin_dashboard/presentation/controllers/admin_dashboard_controller.dart';
import 'package:qrollcall_mobile/features/admin_dashboard/presentation/widgets/admin_activity_tile.dart';
import 'package:qrollcall_mobile/features/admin_dashboard/presentation/widgets/admin_event_card.dart';
import 'package:qrollcall_mobile/features/admin_dashboard/presentation/widgets/admin_stat_card.dart';
import 'package:qrollcall_mobile/features/auth/presentation/controllers/auth_controller.dart';


import 'package:qrollcall_mobile/features/auth/data/firebase_auth_service.dart';
import 'package:qrollcall_mobile/features/create_event/data/create_event_api_service.dart';
import 'package:qrollcall_mobile/features/create_event/presentation/controllers/create_event_controller.dart';
import 'package:qrollcall_mobile/features/create_event/presentation/screens/create_event_screen.dart';
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final adminController = context.watch<AdminDashboardController>();
    final user = authController.currentUser;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _CreateEventFloatingButton(
        onTap: _openCreateEvent,
      ),
      bottomNavigationBar: _AdminBottomNavBar(
        selectedIndex: _selectedTabIndex,
        onTap: (index) {
          setState(() => _selectedTabIndex = index);
          final labels = ['Dashboard', 'Schedule', 'Activity', 'Settings'];
          if (index != 0) {
            _showSoonMessage('${labels[index]} page will be added in the next batch.');
          }
        },
      ),
      body: Stack(
        children: [
          const _AdminBackdrop(),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.primaryContainer,
              onRefresh: adminController.refreshDashboard,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF0B2A61),
                        backgroundImage: (user?.profileImageUrl?.trim().isNotEmpty ?? false)
                            ? NetworkImage(user!.profileImageUrl!)
                            : null,
                        child: (user?.profileImageUrl?.trim().isNotEmpty ?? false)
                            ? null
                            : Text(
                                _initials(user?.fullName ?? 'Admin'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Welcome, ${_firstName(user?.fullName ?? 'Admin')}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showSoonMessage('Notifications panel will be added in the next batch.'),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (adminController.isLoading && !adminController.hasLoadedOnce)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (adminController.errorMessage != null &&
                      !adminController.hasLoadedOnce)
                    _AdminErrorCard(
                      message: adminController.errorMessage!,
                      onRetry: () => adminController.loadDashboard(forceRefresh: true),
                    )
                  else if (adminController.snapshot == null)
                    _AdminErrorCard(
                      message: 'No admin dashboard data is available yet.',
                      onRetry: () => adminController.loadDashboard(forceRefresh: true),
                    )
                  else ...[
                    SizedBox(
                      height: 132,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          AdminStatCard(
                            label: 'Total Events Today',
                            value: '${adminController.snapshot!.totalEventsToday}',
                            accentColor: AppColors.primaryContainer,
                          ),
                          const SizedBox(width: 14),
                          AdminStatCard(
                            label: 'Students Present Now',
                            value: '${adminController.snapshot!.studentsPresentNow}',
                            accentColor: AppColors.primaryContainer,
                            showPulse: true,
                          ),
                          const SizedBox(width: 14),
                          AdminStatCard(
                            label: 'Pending Manual Checks',
                            value: '${adminController.snapshot!.pendingManualChecks}',
                            accentColor: const Color(0xFFAF52DE),
                            trailingIcon: Icons.pending_actions_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Live & Upcoming Events',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showSoonMessage('Schedule page will be added in the next batch.'),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('View Schedule'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (adminController.snapshot!.liveAndUpcomingEvents.isEmpty)
                      _AdminEmptyBlock(
                        title: 'No live or upcoming events',
                        subtitle: 'Create an event to start tracking QR attendance from the admin dashboard.',
                      )
                    else
                      ...adminController.snapshot!.liveAndUpcomingEvents.map(
                        (event) => AdminEventCard(
                          event: event,
                          now: now,
                          onEditTap: () => _showSoonMessage('Event editing will be added in the next batch.'),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Recent Scan Activity',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Container(
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
                      child: adminController.snapshot!.recentActivity.isEmpty
                          ? _AdminEmptyBlock(
                              title: 'No scan activity yet',
                              subtitle: 'Once students begin scanning active event QR codes, recent activity will appear here.',
                              compact: true,
                            )
                          : Column(
                              children: List.generate(
                                adminController.snapshot!.recentActivity.length,
                                (index) => AdminActivityTile(
                                  activity: adminController.snapshot!.recentActivity[index],
                                  now: now,
                                  index: index,
                                ),
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSoonMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openCreateEvent() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => CreateEventController(
            apiService: CreateEventApiService(
              firebaseAuthService: context.read<FirebaseAuthService>(),
            ),
          ),
          child: const CreateEventScreen(),
        ),
      ),
    );

    if (!mounted || created != true) {
      return;
    }

    await context.read<AdminDashboardController>().refreshDashboard();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event created successfully. Admin dashboard refreshed.'),
        ),
      );
    }
  }

  static String _firstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'Admin';
    return parts.first;
  }

  static String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _AdminBackdrop extends StatelessWidget {
  const _AdminBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -150,
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
          right: -90,
          top: 220,
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

class _AdminBottomNavBar extends StatelessWidget {
  const _AdminBottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.grid_view_rounded, 'Dashboard'),
      (Icons.calendar_month_rounded, 'Schedule'),
      (Icons.history_rounded, 'Activity'),
      (Icons.settings_rounded, 'Settings'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.border),
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
          children: List.generate(items.length, (index) {
            final (icon, label) = items[index];
            final selected = index == selectedIndex;

            return InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: selected ? AppColors.primaryContainer : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: selected ? AppColors.primaryContainer : AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
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

class _AdminErrorCard extends StatelessWidget {
  const _AdminErrorCard({
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF48222A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unable to load admin dashboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
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

class _CreateEventFloatingButton extends StatelessWidget {
  const _CreateEventFloatingButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Create New Event',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
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

class _AdminEmptyBlock extends StatelessWidget {
  const _AdminEmptyBlock({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 18),
      decoration: BoxDecoration(
        color: compact ? const Color(0xFF111827) : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            color: AppColors.textSecondary,
            size: compact ? 28 : 42,
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}