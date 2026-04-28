import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:qrollcall_mobile/core/theme/app_colors.dart';
import 'package:qrollcall_mobile/features/event_qr/presentation/controllers/event_qr_controller.dart';

class EventQrScreen extends StatelessWidget {
  const EventQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EventQrController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _QrActionBar(
        isRegenerating: controller.isRegenerating,
        isEnding: controller.isEnding,
        canRegenerate: controller.canRegenerate,
        canEnd: controller.canEnd,
        onRegenerate: () async {
          final success = await context.read<EventQrController>().regenerateCode();

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'QR code regenerated.'
                    : context.read<EventQrController>().errorMessage ??
                        'Unable to regenerate QR code.',
              ),
            ),
          );
        },
        onEnd: () async {
          final shouldEnd = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text(
                'End event attendance?',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              content: const Text(
                'This will deactivate the event. Students will no longer be able to mark attendance with this QR code.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'End Event',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          );

          if (shouldEnd != true || !context.mounted) return;

          final success = await context.read<EventQrController>().endEvent();

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Event attendance ended.'
                    : context.read<EventQrController>().errorMessage ??
                        'Unable to end event.',
              ),
            ),
          );

          if (success && context.mounted) {
            Navigator.of(context).pop(true);
          }
        },
      ),
      body: Stack(
        children: [
          const _QrBackdrop(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 190),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
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
                        'Event QR Code',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showSoon(context, 'More actions will be added later.'),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                      ),
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _EventHeader(controller: controller),
                const SizedBox(height: 28),
                _QrDisplayCard(controller: controller),
                const SizedBox(height: 22),
                _QuickActions(controller: controller),
                const SizedBox(height: 22),
                const _InfoBanner(),
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: 18),
                  _ErrorBanner(message: controller.errorMessage!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _copy(BuildContext context, String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static void _showSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _EventHeader extends StatelessWidget {
  const _EventHeader({
    required this.controller,
  });

  final EventQrController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          controller.event.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                controller.timeRangeLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QrDisplayCard extends StatelessWidget {
  const _QrDisplayCard({
    required this.controller,
  });

  final EventQrController controller;

  @override
  Widget build(BuildContext context) {
    final expiredOrEnded = controller.windowState == EventQrWindowState.expired ||
        controller.windowState == EventQrWindowState.ended;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(width: 300, height: 300),
              const _CornerBrackets(),
              Container(
                width: 242,
                height: 242,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF013540),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryContainer.withValues(alpha: 0.14),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'SESSION',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.38),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.2,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Event Registration',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Stack(
                          children: [
                            Opacity(
                              opacity: expiredOrEnded ? 0.28 : 1,
                              child: QrImageView(
                                data: controller.qrPayloadJson,
                                version: QrVersions.auto,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Colors.black,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            if (controller.isRegenerating)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                            if (expiredOrEnded && !controller.isRegenerating)
                              Positioned.fill(
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.92),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      controller.windowState == EventQrWindowState.ended
                                          ? 'ENDED'
                                          : 'EXPIRED',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'QROLLCALL SECURE SESSION',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _TimerPill(controller: controller),
        ],
      ),
    );
  }
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets();

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primaryContainer;

    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        children: [
          _corner(top: 0, left: 0, topBorder: true, leftBorder: true, color: color),
          _corner(top: 0, right: 0, topBorder: true, rightBorder: true, color: color),
          _corner(bottom: 0, left: 0, bottomBorder: true, leftBorder: true, color: color),
          _corner(bottom: 0, right: 0, bottomBorder: true, rightBorder: true, color: color),
        ],
      ),
    );
  }

  static Widget _corner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool topBorder = false,
    bool bottomBorder = false,
    bool leftBorder = false,
    bool rightBorder = false,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          border: Border(
            top: topBorder ? BorderSide(color: color, width: 4) : BorderSide.none,
            bottom: bottomBorder ? BorderSide(color: color, width: 4) : BorderSide.none,
            left: leftBorder ? BorderSide(color: color, width: 4) : BorderSide.none,
            right: rightBorder ? BorderSide(color: color, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({
    required this.controller,
  });

  final EventQrController controller;

  @override
  Widget build(BuildContext context) {
    final isActive = controller.windowState == EventQrWindowState.active;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0B2A61) : const Color(0xFF2A0A11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive
              ? AppColors.primaryContainer.withValues(alpha: 0.28)
              : AppColors.error.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryContainer : AppColors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timer_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${controller.validityLabel} ',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            controller.countdownText,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isActive ? AppColors.primaryContainer : AppColors.error,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.controller,
  });

  final EventQrController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.ios_share_rounded,
            label: 'Share',
            onTap: () async {
              await SharePlus.instance.share(
                ShareParams(
                  text:
                      'QRollCall event QR payload for ${controller.event.name}:\n${controller.qrPayloadJson}',
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.print_rounded,
            label: 'Print',
            onTap: () {
              EventQrScreen._showSoon(
                context,
                'Print/PDF export will be added in the reports batch.',
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.link_rounded,
            label: 'Copy',
            onTap: () {
              EventQrScreen._copy(
                context,
                controller.qrPayloadJson,
                'QR payload copied.',
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2A61),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryContainer,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2F16).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF34C759).withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF34C759),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.info_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Keep this screen visible for students to scan. The backend still validates token, time window, location, and authentication.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFA7F3B9),
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A0A11),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFFFC8CC),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrActionBar extends StatelessWidget {
  const _QrActionBar({
    required this.isRegenerating,
    required this.isEnding,
    required this.canRegenerate,
    required this.canEnd,
    required this.onRegenerate,
    required this.onEnd,
  });

  final bool isRegenerating;
  final bool isEnding;
  final bool canRegenerate;
  final bool canEnd;
  final VoidCallback onRegenerate;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.96),
          border: const Border(
            top: BorderSide(color: AppColors.border),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canRegenerate ? onRegenerate : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.surfaceContainerHigh,
                  minimumSize: const Size.fromHeight(60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                icon: isRegenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.qr_code_2_rounded),
                label: Text(
                  isRegenerating ? 'Generating...' : 'Regenerate Code',
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: canEnd ? onEnd : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  disabledForegroundColor: AppColors.textMuted,
                  minimumSize: const Size.fromHeight(54),
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.22),
                  ),
                  backgroundColor: AppColors.error.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: isEnding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined),
                label: Text(isEnding ? 'Ending Event...' : 'End Event Attendance'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrBackdrop extends StatelessWidget {
  const _QrBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -140,
          left: MediaQuery.of(context).size.width * 0.18,
          child: Container(
            width: 310,
            height: 310,
            decoration: const BoxDecoration(
              color: Color(0x221B4FD3),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: -90,
          top: 240,
          child: Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              color: Color(0x14133EAF),
              shape: BoxShape.circle,
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
              color: Color(0x22133EAF),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}