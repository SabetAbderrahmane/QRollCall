import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:qrollcall_mobile/core/theme/app_colors.dart';
import 'package:qrollcall_mobile/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:qrollcall_mobile/models/notification_item.dart';

enum NotificationExitAction {
  home,
  scan,
  history,
  profile,
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const _NotificationsBottomBar(),
      body: Stack(
        children: [
          const _NotificationsBackdrop(),
          SafeArea(
            child: RefreshIndicator(
              color: AppColors.primaryContainer,
              onRefresh: controller.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
                children: [
                  _NotificationsHeader(
                    unreadCount: controller.unreadCount,
                    isMutating: controller.isMutating,
                    onBack: () => Navigator.of(context).maybePop(),
                    onMarkAllRead: () async {
                      await context.read<NotificationsController>().markAllRead();

                      if (!context.mounted) return;

                      final error =
                          context.read<NotificationsController>().errorMessage;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            error ?? 'All notifications marked as read.',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  _SummaryBanner(unreadCount: controller.unreadCount),
                  const SizedBox(height: 18),
                  _NotificationFilters(controller: controller),
                  const SizedBox(height: 18),
                  if (controller.isLoading && !controller.hasLoadedOnce)
                    const Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (controller.errorMessage != null &&
                      !controller.hasLoadedOnce)
                    _NotificationsErrorCard(
                      message: controller.errorMessage!,
                      onRetry: () => controller.load(forceRefresh: true),
                    )
                  else if (controller.filteredNotifications.isEmpty)
                    const _EmptyNotificationsCard()
                  else
                    ...List.generate(
                      controller.filteredNotifications.length,
                      (index) {
                        final item = controller.filteredNotifications[index];

                        return _NotificationTile(
                          item: item,
                          index: index,
                          onTap: () async {
                            if (!item.isRead) {
                              await context
                                  .read<NotificationsController>()
                                  .markNotificationRead(
                                    item,
                                    isRead: true,
                                  );
                            }
                          },
                          onMarkReadToggle: () async {
                            await context
                                .read<NotificationsController>()
                                .markNotificationRead(
                                  item,
                                  isRead: !item.isRead,
                                );
                          },
                          onDelete: () async {
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: AppColors.surface,
                                title: const Text(
                                  'Delete notification?',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                content: const Text(
                                  'This will remove this notification from your registry.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (shouldDelete == true && context.mounted) {
                              await context
                                  .read<NotificationsController>()
                                  .deleteNotification(item);
                            }
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 22),
                  const _WeeklyReviewCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.unreadCount,
    required this.isMutating,
    required this.onBack,
    required this.onMarkAllRead,
  });

  final int unreadCount;
  final bool isMutating;
  final VoidCallback onBack;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
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
            'Notifications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        TextButton(
          onPressed: unreadCount == 0 || isMutating ? null : onMarkAllRead,
          child: isMutating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Mark all read'),
        ),
      ],
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.unreadCount,
  });

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final title = unreadCount == 0 ? 'You are all caught up' : 'Stay Updated';
    final message = unreadCount == 0
        ? 'No unread attendance alerts are pending right now.'
        : 'You have $unreadCount unread notification${unreadCount == 1 ? '' : 's'} regarding your attendance registry.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF0B2A61),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.primaryContainer,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationFilters extends StatelessWidget {
  const _NotificationFilters({
    required this.controller,
  });

  final NotificationsController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _FilterButton(
            label: 'All',
            selected: controller.selectedFilter == NotificationsFilter.all,
            onTap: () => controller.setFilter(NotificationsFilter.all),
          ),
          _FilterButton(
            label: 'Unread',
            selected: controller.selectedFilter == NotificationsFilter.unread,
            onTap: () => controller.setFilter(NotificationsFilter.unread),
          ),
          _FilterButton(
            label: 'Read',
            selected: controller.selectedFilter == NotificationsFilter.read,
            onTap: () => controller.setFilter(NotificationsFilter.read),
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
    return Expanded(
      child: Material(
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
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.index,
    required this.onTap,
    required this.onMarkReadToggle,
    required this.onDelete,
  });

  final NotificationItem item;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onMarkReadToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = _NotificationVisuals.fromType(item.notificationType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: item.isRead ? AppColors.surface : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: item.isRead
                    ? AppColors.border
                    : colors.accent.withValues(alpha: 0.34),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    colors.icon,
                    color: colors.accent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: item.isRead
                                        ? FontWeight.w700
                                        : FontWeight.w900,
                                    height: 1.2,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _relativeTime(item.createdAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              if (!item.isRead) ...[
                                const SizedBox(width: 7),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.42,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _TypePill(
                            label: _typeLabel(item.notificationType),
                            color: colors.accent,
                          ),
                          const Spacer(),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: onMarkReadToggle,
                            icon: Icon(
                              item.isRead
                                  ? Icons.mark_email_unread_rounded
                                  : Icons.done_all_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: onDelete,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _typeLabel(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized == 'attendance_confirmed') return 'Attendance';
    if (normalized == 'missed_event') return 'Missed';
    if (normalized == 'admin_broadcast') return 'Broadcast';
    if (normalized == 'reminder') return 'Reminder';

    return 'Notice';
  }

  static String _relativeTime(DateTime value) {
    final now = DateTime.now();
    final diff = now.difference(value);

    if (diff.inSeconds < 60) return 'NOW';
    if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
    if (diff.inHours < 24) return '${diff.inHours}H AGO';
    if (diff.inDays < 7) return '${diff.inDays}D AGO';

    return '${value.month}/${value.day}';
  }
}

class _NotificationVisuals {
  const _NotificationVisuals({
    required this.icon,
    required this.accent,
    required this.background,
  });

  final IconData icon;
  final Color accent;
  final Color background;

  factory _NotificationVisuals.fromType(String type) {
    final normalized = type.trim().toLowerCase();

    if (normalized == 'attendance_confirmed') {
      return const _NotificationVisuals(
        icon: Icons.check_circle_rounded,
        accent: Color(0xFF57D26C),
        background: Color(0xFF12351A),
      );
    }

    if (normalized == 'missed_event') {
      return const _NotificationVisuals(
        icon: Icons.block_rounded,
        accent: Color(0xFFFF7B7B),
        background: Color(0xFF2A0A11),
      );
    }

    if (normalized == 'admin_broadcast') {
      return const _NotificationVisuals(
        icon: Icons.campaign_rounded,
        accent: Color(0xFFAF52DE),
        background: Color(0xFF251238),
      );
    }

    return const _NotificationVisuals(
      icon: Icons.schedule_rounded,
      accent: AppColors.primaryContainer,
      background: Color(0xFF0B2A61),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _WeeklyReviewCard extends StatelessWidget {
  const _WeeklyReviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -60,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Weekly Review Ready',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Check your attendance alerts and class activity summary.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFD8E4FF),
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyNotificationsCard extends StatelessWidget {
  const _EmptyNotificationsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFF0B2A61),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primaryContainer,
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No notifications found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Attendance confirmations, reminders, class changes, and missed-event alerts will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsErrorCard extends StatelessWidget {
  const _NotificationsErrorCard({
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
            'Unable to load notifications',
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

class _NotificationsBottomBar extends StatelessWidget {
  const _NotificationsBottomBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BottomItem(
              icon: Icons.grid_view_rounded,
              label: 'Home',
              selected: false,
              onTap: () => Navigator.of(context).pop(NotificationExitAction.home),
            ),
            _BottomItem(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan',
              selected: false,
              onTap: () => Navigator.of(context).pop(NotificationExitAction.scan),
            ),
            _BottomItem(
              icon: Icons.notifications_rounded,
              label: 'Alerts',
              selected: true,
              onTap: () {},
            ),
            _BottomItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              selected: false,
              onTap: () =>
                  Navigator.of(context).pop(NotificationExitAction.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
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
    final color = selected ? AppColors.primaryContainer : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? AppColors.primarySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsBackdrop extends StatelessWidget {
  const _NotificationsBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -145,
          left: MediaQuery.of(context).size.width * 0.14,
          child: Container(
            width: 310,
            height: 310,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x221B4FD3),
            ),
          ),
        ),
        Positioned(
          right: -90,
          top: 255,
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
          left: -110,
          bottom: -125,
          child: Container(
            width: 290,
            height: 290,
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