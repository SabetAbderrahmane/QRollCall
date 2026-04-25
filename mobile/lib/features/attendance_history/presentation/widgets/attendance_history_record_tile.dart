import 'package:flutter/material.dart';

import 'package:qrollcall_mobile/features/attendance_history/models/attendance_history_entry.dart';

class AttendanceHistoryRecordTile extends StatelessWidget {
  const AttendanceHistoryRecordTile({
    super.key,
    required this.entry,
    required this.index,
  });

  final AttendanceHistoryEntry entry;
  final int index;

  static const Color _brandBlue = Color(0xFF0056D2);
  static const Color _textPrimary = Color(0xFFF8FAFC);
  static const Color _textSecondary = Color(0xFF94A3B8);

  static const Color _surfaceA = Color(0xFF0F172A);
  static const Color _surfaceB = Color(0xFF111827);
  static const Color _border = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    final accent = _accentForTitle(entry.eventName);
    final statusColors = _statusPalette(entry);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: index.isEven ? _surfaceA : _surfaceB,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              accent.icon,
              color: accent.foreground,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.eventName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(entry.primaryTimestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColors.background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              entry.normalizedStatusLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: statusColors.foreground,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  static _TileAccent _accentForTitle(String title) {
    final normalized = title.toLowerCase();

    if (normalized.contains('software')) {
      return const _TileAccent(
        icon: Icons.school_rounded,
        background: Color(0xFF0B2A61),
        foreground: _brandBlue,
      );
    }
    if (normalized.contains('data') || normalized.contains('structure')) {
      return const _TileAccent(
        icon: Icons.terminal_rounded,
        background: Color(0xFF10264E),
        foreground: Color(0xFF5CA4FF),
      );
    }
    if (normalized.contains('design') || normalized.contains('system')) {
      return const _TileAccent(
        icon: Icons.architecture_rounded,
        background: Color(0xFF352207),
        foreground: Color(0xFFFFB454),
      );
    }
    if (normalized.contains('math') || normalized.contains('science')) {
      return const _TileAccent(
        icon: Icons.science_rounded,
        background: Color(0xFF112B17),
        foreground: Color(0xFF57D26C),
      );
    }
    if (normalized.contains('intelligence') || normalized.contains('ai')) {
      return const _TileAccent(
        icon: Icons.psychology_rounded,
        background: Color(0xFF2A184A),
        foreground: Color(0xFFB18BFF),
      );
    }

    return const _TileAccent(
      icon: Icons.menu_book_rounded,
      background: Color(0xFF0B2A61),
      foreground: _brandBlue,
    );
  }

  static _StatusPalette _statusPalette(AttendanceHistoryEntry entry) {
    if (entry.isPresent) {
      return const _StatusPalette(
        background: Color(0xFF12351A),
        foreground: Color(0xFF57D26C),
      );
    }

    return const _StatusPalette(
      background: Color(0xFF3A1212),
      foreground: Color(0xFFFF7B7B),
    );
  }

  static String _formatDateTime(DateTime value) {
    const monthLabels = <String>[
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

    final hour = value.hour == 0
        ? 12
        : value.hour > 12
            ? value.hour - 12
            : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';

    return '${monthLabels[value.month - 1]} ${value.day}, $hour:$minute $suffix';
  }
}

class _TileAccent {
  const _TileAccent({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
}

class _StatusPalette {
  const _StatusPalette({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}