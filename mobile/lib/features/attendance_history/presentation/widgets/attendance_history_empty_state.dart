import 'package:flutter/material.dart';

class AttendanceHistoryEmptyState extends StatelessWidget {
  const AttendanceHistoryEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.showPrimaryAction,
    this.onPrimaryAction,
  });

  final String title;
  final String subtitle;
  final bool showPrimaryAction;
  final VoidCallback? onPrimaryAction;

  static const Color _brandBlue = Color(0xFF0056D2);
  static const Color _surface = Color(0xFF0F172A);
  static const Color _surfaceSoft = Color(0xFF111827);
  static const Color _border = Color(0xFF1E293B);
  static const Color _textPrimary = Color(0xFFF8FAFC);
  static const Color _textSecondary = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: _surfaceSoft,
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                Positioned(
                  top: 18,
                  child: Container(
                    width: 68,
                    height: 82,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B2A61),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF194084),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        _line(width: 34),
                        const SizedBox(height: 8),
                        _line(width: 26),
                        const SizedBox(height: 8),
                        _line(width: 30),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  bottom: 20,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _brandBlue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _brandBlue.withValues(alpha: 0.24),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.search_off_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _textSecondary,
                  height: 1.6,
                ),
          ),
          if (showPrimaryAction) ...[
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPrimaryAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Start Scanning'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _line({required double width}) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFF7BA4F8),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}