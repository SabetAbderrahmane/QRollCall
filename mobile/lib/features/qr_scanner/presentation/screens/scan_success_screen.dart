import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qrollcall_mobile/features/qr_scanner/models/scan_result_models.dart';

class ScanSuccessScreen extends StatefulWidget {
  const ScanSuccessScreen({
    super.key,
    required this.data,
  });

  final ScanSuccessViewData data;

  @override
  State<ScanSuccessScreen> createState() => _ScanSuccessScreenState();
}

class _ScanSuccessScreenState extends State<ScanSuccessScreen>
    with TickerProviderStateMixin {
  static const Color _brandBlue = Color(0xFF0A63FF);

  static const Color _baseTop = Color(0xFF071226);
  static const Color _baseMid = Color(0xFF040C1C);
  static const Color _baseBottom = Color(0xFF020817);

  static const Color _successTop = Color(0xFF1D6E38);
  static const Color _successMid = Color(0xFF0B4B22);
  static const Color _successBottom = Color(0xFF052A12);

  static const Color _cardColor = Color(0xFF091A3A);
  static const Color _cardIconBg = Color(0xFF142D5E);

  late final AnimationController _controller;
  late final AnimationController _sparkleController;

  late final Animation<double> _iconScale;
  late final Animation<double> _iconLift;
  late final Animation<double> _contentFade;
  late final Animation<double> _actionsFade;
  late final Animation<double> _ringExpand;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _iconScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.52, curve: Curves.elasticOut),
    );

    _iconLift = Tween<double>(begin: 120, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.32, curve: Curves.easeOutCubic),
      ),
    );

    _contentFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 0.78, curve: Curves.easeOut),
    );

    _actionsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.68, 1.0, curve: Curves.easeOut),
    );

    _ringExpand = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.42, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  double _washStrength(double t) {
    if (t <= 0.24) {
      return t / 0.24;
    }
    if (t <= 0.58) {
      return 1 - ((t - 0.24) / 0.34);
    }
    return 0;
  }

  Color _pulseColor(Color base, Color accent, double t) {
    return Color.lerp(base, accent, t)!;
  }

  @override
  Widget build(BuildContext context) {
    final verifiedAtLabel = _formatDateTime(widget.data.verifiedAt);

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_controller, _sparkleController]),
        builder: (context, _) {
          final wash = _washStrength(_controller.value);

          final topColor = _pulseColor(_baseTop, _successTop, wash);
          final midColor = _pulseColor(_baseMid, _successMid, wash);
          final bottomColor = _pulseColor(_baseBottom, _successBottom, wash);

          final iconScale = _iconScale.value.clamp(0.001, 1.0);
          final rotateX = (1 - iconScale) * 0.8;
          final rotateY = (1 - iconScale) * -0.35;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topColor, midColor, bottomColor],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: _SuccessBackdrop(
                      wash: wash,
                      sparkleValue: _sparkleController.value,
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Column(
                      children: [
                        const _ResultTopBar(),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Column(
                            children: [
                              const Spacer(flex: 2),
                              SizedBox(
                                width: 280,
                                height: 280,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Transform.scale(
                                      scale: 0.65 + (_ringExpand.value * 0.95),
                                      child: Container(
                                        width: 230,
                                        height: 230,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF57E684).withValues(
                                              alpha: 0.15 + (wash * 0.35),
                                            ),
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Transform.scale(
                                      scale: 0.78 + (_ringExpand.value * 0.45),
                                      child: Container(
                                        width: 260,
                                        height: 260,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              const Color(0xFF57E684).withValues(
                                                alpha: 0.16 + (wash * 0.28),
                                              ),
                                              const Color(0xFF57E684).withValues(
                                                alpha: 0.05 + (wash * 0.16),
                                              ),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.0012)
                                        ..translate(0.0, _iconLift.value)
                                        ..rotateX(rotateX)
                                        ..rotateY(rotateY)
                                        ..scale(iconScale),
                                      child: Container(
                                        width: 134,
                                        height: 134,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(42),
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF65E18A),
                                              Color(0xFF37C75F),
                                              Color(0xFF189E40),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF45E06E).withValues(
                                                alpha: 0.34,
                                              ),
                                              blurRadius: 38,
                                              spreadRadius: 3,
                                              offset: const Offset(0, 18),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(42),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.white.withValues(alpha: 0.18),
                                                      Colors.transparent,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const Center(
                                              child: Icon(
                                                Icons.check_rounded,
                                                size: 76,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Opacity(
                                opacity: _contentFade.value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - _contentFade.value)),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Attendance Marked\nSuccessfully!',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              height: 1.05,
                                            ),
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0E2A18),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          widget.data.statusLabel,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: const Color(0xFF41D36A),
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.7,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 26),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(22),
                                        decoration: BoxDecoration(
                                          color: _cardColor,
                                          borderRadius: BorderRadius.circular(30),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.06),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.22),
                                              blurRadius: 20,
                                              spreadRadius: 1,
                                              offset: const Offset(0, 12),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Event Details',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                    color: const Color(0xFF6E7FA6),
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 1.3,
                                                  ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              widget.data.eventName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    color: _brandBlue,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                            const SizedBox(height: 18),
                                            Divider(
                                              height: 1,
                                              color:
                                                  Colors.white.withValues(alpha: 0.06),
                                            ),
                                            const SizedBox(height: 18),
                                            Row(
                                              children: [
                                                const _DetailIcon(
                                                  icon: Icons.access_time_rounded,
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: _DetailTextBlock(
                                                    label: 'Timestamp',
                                                    value: verifiedAtLabel,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                const _DetailIcon(
                                                  icon: Icons.location_on_outlined,
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: _DetailTextBlock(
                                                    label: 'Location Check',
                                                    value: widget.data.locationLabel,
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
                              const Spacer(flex: 2),
                              Opacity(
                                opacity: _actionsFade.value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - _actionsFade.value)),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(ScanFlowExitAction.done);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1A7B23),
                                            foregroundColor: Colors.white,
                                            minimumSize:
                                                const Size.fromHeight(62),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                            ),
                                          ),
                                          child: const Text('Done'),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(
                                              ScanFlowExitAction.openHistory,
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            minimumSize:
                                                const Size.fromHeight(58),
                                            side: BorderSide(
                                              color: Colors.white.withValues(alpha: 0.10),
                                            ),
                                            backgroundColor: const Color(0xFF07183A),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                            ),
                                          ),
                                          child: const Text('View My History'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
            ? value.hour - 12
            : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';

    return '${value.month}/${value.day}/${value.year} • $hour:$minute $suffix';
  }
}

class _SuccessBackdrop extends StatelessWidget {
  const _SuccessBackdrop({
    required this.wash,
    required this.sparkleValue,
  });

  final double wash;
  final double sparkleValue;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                const Color(0xFF0C2A63).withValues(alpha: 0.55),
                const Color(0xFF35C862).withValues(alpha: 0.28),
                wash,
              ),
            ),
          ),
        ),
        Positioned(
          right: -90,
          top: 120,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                const Color(0xFF0B214A).withValues(alpha: 0.32),
                const Color(0xFF2FAC54).withValues(alpha: 0.22),
                wash,
              ),
            ),
          ),
        ),
        Positioned(
          left: -60,
          bottom: -120,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                const Color(0xFF0B2452).withValues(alpha: 0.42),
                const Color(0xFF2AA850).withValues(alpha: 0.18),
                wash,
              ),
            ),
          ),
        ),
        ...List.generate(10, (index) {
          final angle = (index / 10) * math.pi * 2;
          final radius = 150 +
              (16 * math.sin((sparkleValue * math.pi * 2) + index));
          final dx = math.cos(angle) * radius;
          final dy = math.sin(angle) * radius;
          final size = index.isEven ? 7.0 : 5.0;

          return Positioned(
            left: screenSize.width / 2 + dx,
            top: screenSize.height * 0.26 + dy,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(
                  Colors.white.withValues(alpha: 0.22),
                  const Color(0xFF7DFFAA).withValues(alpha: 0.26),
                  wash,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ResultTopBar extends StatelessWidget {
  const _ResultTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'QRollCall',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _ScanSuccessScreenState._brandBlue,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _DetailIcon extends StatelessWidget {
  const _DetailIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _ScanSuccessScreenState._cardIconBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: _ScanSuccessScreenState._brandBlue,
      ),
    );
  }
}

class _DetailTextBlock extends StatelessWidget {
  const _DetailTextBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF6E7FA6),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}