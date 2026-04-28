import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:qrollcall_mobile/core/theme/app_colors.dart';
import 'package:qrollcall_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:qrollcall_mobile/models/app_user.dart';

enum ProfileExitAction {
  home,
  scan,
  history,
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final user = authController.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const _ProfileBottomBar(),
      body: Stack(
        children: [
          const _ProfileBackdrop(),
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
              children: [
                _ProfileTopBar(
                  onBackTap: () => Navigator.of(context).maybePop(
                    ProfileExitAction.home,
                  ),
                  onSettingsTap: () => _showSoon(
                    context,
                    'Profile settings editing will be added in a later batch.',
                  ),
                ),
                const SizedBox(height: 26),
                _ProfileIdentityCard(user: user),
                const SizedBox(height: 26),
                _ProfileSectionLabel(label: 'Account'),
                const SizedBox(height: 12),
                _ProfileMenuCard(
                  children: [
                    _ProfileMenuItem(
                      icon: Icons.history_rounded,
                      title: 'My Attendance History',
                      subtitle: 'View your last 30 days of records',
                      onTap: () => Navigator.of(context).pop(
                        ProfileExitAction.history,
                      ),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'New announcements will appear here',
                      showDot: true,
                      onTap: () => _showSoon(
                        context,
                        'Notifications page will be added in a later batch.',
                      ),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.switch_account_rounded,
                      title: 'Switch Role',
                      subtitle: _switchRoleSubtitle(user),
                      onTap: () => _showRoleInfo(context, user),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _ProfileSectionLabel(label: 'Preferences'),
                const SizedBox(height: 12),
                _ProfileMenuCard(
                  children: [
                    _PreferenceToggleItem(
                      icon: Icons.dark_mode_rounded,
                      title: 'Dark Mode',
                      subtitle: 'Dark-blue theme active',
                      value: true,
                      onTap: () => _showSoon(
                        context,
                        'Light mode switching will be added later. For now, QRollCall uses the dark-blue system theme.',
                      ),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      subtitle: 'English',
                      onTap: () => _showSoon(
                        context,
                        'Language switching will be added later.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _ProfileSectionLabel(label: 'Session'),
                const SizedBox(height: 12),
                _ProfileMenuCard(
                  children: [
                    _ProfileMenuItem(
                      icon: Icons.verified_user_rounded,
                      title: 'Backend Session',
                      subtitle: _sessionSubtitle(user),
                      onTap: () => _showSessionDetails(context, user),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      subtitle: 'End this device session',
                      destructive: true,
                      showChevron: false,
                      onTap: () => _confirmLogout(context),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                const _ProfileFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _switchRoleSubtitle(AppUser? user) {
    if (user == null) return 'No active profile loaded';

    final role = user.role.toLowerCase();

    if (role == 'admin') {
      return 'Admin tools enabled for this account';
    }

    return 'Ask an admin to promote this backend account';
  }

  static String _sessionSubtitle(AppUser? user) {
    if (user == null) return 'No backend user loaded';

    return 'User ID ${user.id} • ${user.isActive ? 'Active' : 'Inactive'}';
  }

  static void _showSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static void _showRoleInfo(BuildContext context, AppUser? user) {
    final role = user?.role.toLowerCase() ?? 'unknown';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileInfoSheet(
        title: 'Current Role',
        icon: Icons.switch_account_rounded,
        lines: [
          'Role: ${_formatRole(role)}',
          if (role == 'admin')
            'This account can access admin tools when routed through the admin dashboard.'
          else
            'This account is a student account. Promotion to admin must happen in the backend users table.',
        ],
      ),
    );
  }

  static void _showSessionDetails(BuildContext context, AppUser? user) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileInfoSheet(
        title: 'Backend Session',
        icon: Icons.verified_user_rounded,
        lines: [
          'Email: ${user?.email ?? 'Unavailable'}',
          'Backend user ID: ${user?.id ?? 'Unavailable'}',
          'Firebase UID: ${user?.firebaseUid ?? 'Unavailable'}',
          'Role: ${_formatRole(user?.role ?? 'unknown')}',
          'Status: ${user?.isActive == true ? 'Active' : 'Inactive'}',
        ],
      ),
    );
  }

  static Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Log out?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: const Text(
          'You will need to sign in again before scanning attendance or viewing your records.',
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    await context.read<AuthController>().signOut();

    if (!context.mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static String _formatRole(String role) {
    final normalized = role.trim().toLowerCase();

    if (normalized == 'admin') return 'Admin';
    if (normalized == 'student') return 'Student';

    return 'Unknown';
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.onBackTap,
    required this.onSettingsTap,
  });

  final VoidCallback onBackTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBackTap,
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
            'Profile',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(width: 14),
        IconButton(
          onPressed: onSettingsTap,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
          ),
          icon: const Icon(
            Icons.settings_rounded,
            color: AppColors.primaryContainer,
          ),
        ),
      ],
    );
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({
    required this.user,
  });

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final name = _displayName(user);
    final email = user?.email ?? 'No email loaded';
    final role = ProfileScreen._formatRole(user?.role ?? 'student');
    final hasImage =
        user?.profileImageUrl != null && user!.profileImageUrl!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 126,
                height: 126,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryContainer,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryContainer.withValues(alpha: 0.22),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: hasImage
                      ? Image.network(
                          user!.profileImageUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.surfaceContainerHigh,
                          child: Center(
                            child: Text(
                              _initials(name),
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF12351A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surface,
                      width: 4,
                    ),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF57D26C),
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _IdentityChip(
                icon: role.toLowerCase() == 'admin'
                    ? Icons.admin_panel_settings_rounded
                    : Icons.school_rounded,
                label: role,
              ),
              _IdentityChip(
                icon: Icons.badge_rounded,
                label: user?.studentId?.trim().isNotEmpty == true
                    ? user!.studentId!.trim()
                    : 'ID ${user?.id ?? '--'}',
              ),
              _IdentityChip(
                icon: user?.isActive == true
                    ? Icons.check_circle_rounded
                    : Icons.block_rounded,
                label: user?.isActive == true ? 'Active' : 'Inactive',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _displayName(AppUser? user) {
    final fullName = user?.fullName.trim();

    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }

    final email = user?.email.trim();

    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'QRollCall User';
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'Q';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _IdentityChip extends StatelessWidget {
  const _IdentityChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2A61),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primaryContainer.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.primaryContainer,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionLabel extends StatelessWidget {
  const _ProfileSectionLabel({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children,
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
    this.showDot = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;
  final bool showDot;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.error : AppColors.primaryContainer;
    final iconBackground =
        destructive ? const Color(0xFF2A0A11) : const Color(0xFF0B2A61);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        icon,
                        color: accent,
                        size: 25,
                      ),
                    ),
                    if (showDot)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: iconBackground,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: destructive
                                  ? AppColors.error
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                if (showChevron) ...[
                  const SizedBox(width: 10),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: destructive ? AppColors.error : AppColors.textMuted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreferenceToggleItem extends StatelessWidget {
  const _PreferenceToggleItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ProfileMenuItemShell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF0B2A61),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 56,
            height: 32,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: value ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Align(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItemShell extends StatelessWidget {
  const _ProfileMenuItemShell({
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ProfileBottomBar extends StatelessWidget {
  const _ProfileBottomBar();

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
            _ProfileBottomItem(
              icon: Icons.grid_view_rounded,
              label: 'Home',
              selected: false,
              onTap: () => Navigator.of(context).pop(ProfileExitAction.home),
            ),
            _ProfileBottomItem(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan',
              selected: false,
              onTap: () => Navigator.of(context).pop(ProfileExitAction.scan),
            ),
            _ProfileBottomItem(
              icon: Icons.history_rounded,
              label: 'History',
              selected: false,
              onTap: () => Navigator.of(context).pop(ProfileExitAction.history),
            ),
            _ProfileBottomItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              selected: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBottomItem extends StatelessWidget {
  const _ProfileBottomItem({
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

class _ProfileInfoSheet extends StatelessWidget {
  const _ProfileInfoSheet({
    required this.title,
    required this.icon,
    required this.lines,
  });

  final String title;
  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFF0B2A61),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryContainer,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 18),
          ...lines.map(
            (line) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                line,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 1,
          color: AppColors.border,
        ),
        const SizedBox(height: 18),
        Text(
          'QROLLCALL INTELLIGENCE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.4,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'v1.0.0 • Mobile Build',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted.withValues(alpha: 0.65),
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _ProfileBackdrop extends StatelessWidget {
  const _ProfileBackdrop();

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