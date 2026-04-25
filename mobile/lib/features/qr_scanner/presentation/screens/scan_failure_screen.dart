import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qrollcall_mobile/features/qr_scanner/models/scan_result_models.dart';

class ScanFailureScreen extends StatefulWidget {
  const ScanFailureScreen({
    super.key,
    required this.data,
  });

  final ScanFailureViewData data;

  @override
  State<ScanFailureScreen> createState() => _ScanFailureScreenState();
}

class _ScanFailureScreenState extends State<ScanFailureScreen>
    with TickerProviderStateMixin {
  static const Color _brandBlue = Color(0xFF0A63FF);

  static const Color _baseTop = Color(0xFF071226);
  static const Color _baseMid = Color(0xFF040C1C);
  static const Color _baseBottom = Color(0xFF020817);

  static const Color _dangerTop = Color(0xFF64111A);
  static const Color _dangerMid = Color(0xFF35080E);
  static const Color _dangerBottom = Color(0xFF1B0408);

  static const Color _cardColor = Color(0xFF091A3A);
  static const Color _cardIconBg = Color(0xFF142D5E);

  late final AnimationController _controller;
  late final AnimationController _pulseController;

  late final Animation<double> _contentFade;
  late final Animation<double> _actionsFade;
  late final Animation<double> _heroScale;
  late final Animation<double> _heroLift;
  late final Animation<double> _shockwave;
  late final Animation<double> _ringExpand;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _contentFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 0.80, curve: Curves.easeOut),
    );

    _actionsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.68, 1.0, curve: Curves.easeOut),
    );

    _heroScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.42, curve: Curves.easeOutBack),
    );

    _heroLift = Tween<double>(begin: 90, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.02, 0.26, curve: Curves.easeOutCubic),
      ),
    );

    _shockwave = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.24, curve: Curves.easeOutCubic),
    );

    _ringExpand = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.10, 0.46, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  double _washStrength(double t) {
    if (t <= 0.20) {
      return t / 0.20;
    }
    if (t <= 0.56) {
      return 1 - ((t - 0.20) / 0.36);
    }
    return 0;
  }

  Color _blend(Color base, Color accent, double t) {
    return Color.lerp(base, accent, t)!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_controller, _pulseController]),
        builder: (context, _) {
          final wash = _washStrength(_controller.value);

          final topColor = _blend(_baseTop, _dangerTop, wash);
          final midColor = _blend(_baseMid, _dangerMid, wash);
          final bottomColor = _blend(_baseBottom, _dangerBottom, wash);

          final heroScale = _heroScale.value.clamp(0.001, 1.0);
          final ringPulse = 1 + (_pulseController.value * 0.05);
          final glowPulse = 0.10 + (_pulseController.value * 0.10);

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
                    child: _FailureBackdrop(wash: wash),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Column(
                      children: [
                        const _FailureTopBar(),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Column(
                            children: [
                              const Spacer(flex: 2),

                              /// HERO
                              SizedBox(
                                width: 300,
                                height: 250,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Transform.scale(
                                      scale: 0.85 + (_shockwave.value * 1.0),
                                      child: Container(
                                        width: 230,
                                        height: 230,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              const Color(0xFFFF4B58).withValues(
                                                alpha: 0.12 + (wash * 0.18),
                                              ),
                                              const Color(0xFFFF4B58).withValues(
                                                alpha: 0.04 + (wash * 0.08),
                                              ),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Transform.scale(
                                      scale: (0.86 + (_ringExpand.value * 0.45)) *
                                          ringPulse,
                                      child: Container(
                                        width: 215,
                                        height: 215,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFFFF4B58)
                                                .withValues(
                                              alpha: 0.10 + glowPulse,
                                            ),
                                            width: 2.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Transform.translate(
                                      offset: Offset(0, _heroLift.value),
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, 0.0012)
                                          ..rotateZ((1 - heroScale) * -0.22)
                                          ..scale(heroScale),
                                        child: SizedBox(
                                          width: 190,
                                          height: 190,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              const _SlashBeam(
                                                angle: -0.62,
                                                width: 168,
                                                height: 18,
                                              ),
                                              const _SlashBeam(
                                                angle: 0.62,
                                                width: 168,
                                                height: 18,
                                              ),
                                              Container(
                                                width: 132,
                                                height: 132,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(36),
                                                  gradient: const LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Color(0xFF29070C),
                                                      Color(0xFF170408),
                                                      Color(0xFF0E0306),
                                                    ],
                                                  ),
                                                  border: Border.all(
                                                    color: const Color(0xFFFF5562)
                                                        .withValues(alpha: 0.42),
                                                    width: 1.6,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFFFF4B58)
                                                          .withValues(
                                                        alpha: 0.18,
                                                      ),
                                                      blurRadius: 28,
                                                      spreadRadius: 2,
                                                      offset:
                                                          const Offset(0, 12),
                                                    ),
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(alpha: 0.28),
                                                      blurRadius: 18,
                                                      offset:
                                                          const Offset(0, 12),
                                                    ),
                                                  ],
                                                ),
                                                child: Stack(
                                                  children: [
                                                    Positioned.fill(
                                                      child: DecoratedBox(
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  36),
                                                          gradient:
                                                              LinearGradient(
                                                            begin:
                                                                Alignment.topCenter,
                                                            end: Alignment.bottomCenter,
                                                            colors: [
                                                              Colors.white
                                                                  .withValues(
                                                                      alpha: 0.10),
                                                              Colors.transparent,
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Center(
                                                      child: Container(
                                                        width: 78,
                                                        height: 78,
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  24),
                                                          border: Border.all(
                                                            color: const Color(
                                                                    0xFFFF4B58)
                                                                .withValues(
                                                              alpha: 0.20,
                                                            ),
                                                          ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.close_rounded,
                                                          color:
                                                              Color(0xFFFF4B58),
                                                          size: 52,
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      left: 28,
                                                      right: 28,
                                                      top: 64,
                                                      child: Transform.rotate(
                                                        angle: -0.18,
                                                        child: Container(
                                                          height: 3,
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(999),
                                                            color: const Color(
                                                                    0xFFFF4B58)
                                                                .withValues(
                                                              alpha: 0.26,
                                                            ),
                                                          ),
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
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              Opacity(
                                opacity: _contentFade.value,
                                child: Transform.translate(
                                  offset:
                                      Offset(0, 20 * (1 - _contentFade.value)),
                                  child: Column(
                                    children: [
                                      Text(
                                        widget.data.headline,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              height: 1.08,
                                            ),
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2A0A11),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 9,
                                              height: 9,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFFF4B58),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              widget.data.badgeLabel,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge
                                                  ?.copyWith(
                                                    color:
                                                        const Color(0xFFFF4B58),
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 0.7,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        widget.data.summary,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: const Color(0xFFAEB8D0),
                                              height: 1.6,
                                            ),
                                      ),
                                      const SizedBox(height: 26),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(22),
                                        decoration: BoxDecoration(
                                          color: _cardColor,
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.06),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.22),
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
                                            if (widget.data.eventName !=
                                                null) ...[
                                              Text(
                                                'Related Event',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      color:
                                                          const Color(0xFF6E7FA6),
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: 1.3,
                                                    ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                widget.data.eventName!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      color: _brandBlue,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                              const SizedBox(height: 18),
                                              Divider(
                                                height: 1,
                                                color: Colors.white
                                                    .withValues(alpha: 0.06),
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                            ...List.generate(
                                              widget.data.reasons.length,
                                              (index) {
                                                final reason =
                                                    widget.data.reasons[index];

                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                    top: index == 0 ? 0 : 14,
                                                  ),
                                                  child: _FailureReasonTile(
                                                    reason: reason,
                                                  ),
                                                );
                                              },
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
                                  offset:
                                      Offset(0, 18 * (1 - _actionsFade.value)),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).pop(
                                              ScanFlowExitAction.retry,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _brandBlue,
                                            foregroundColor: Colors.white,
                                            minimumSize:
                                                const Size.fromHeight(62),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                            ),
                                          ),
                                          icon:
                                              const Icon(Icons.refresh_rounded),
                                          label: const Text('Try Again'),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).pop(
                                              ScanFlowExitAction.home,
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            minimumSize:
                                                const Size.fromHeight(58),
                                            side: BorderSide(
                                              color: Colors.white
                                                  .withValues(alpha: 0.10),
                                            ),
                                            backgroundColor:
                                                const Color(0xFF07183A),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                            ),
                                          ),
                                          icon: const Icon(Icons.home_outlined),
                                          label: const Text('Return Home'),
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
}

class _FailureBackdrop extends StatelessWidget {
  const _FailureBackdrop({
    required this.wash,
  });

  final double wash;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -95,
          left: -100,
          child: Transform.rotate(
            angle: -0.28,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Color.lerp(
                    const Color(0xFF17325E).withValues(alpha: 0.18),
                    const Color(0xFFFF4B58).withValues(alpha: 0.14),
                    wash,
                  )!,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -70,
          top: 120,
          child: Transform.rotate(
            angle: 0.26,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Color.lerp(
                    const Color(0xFF17325E).withValues(alpha: 0.14),
                    const Color(0xFFFF4B58).withValues(alpha: 0.12),
                    wash,
                  )!,
                  width: 1.8,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          top: MediaQuery.of(context).size.height * 0.24,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                const Color(0xFF15335F).withValues(alpha: 0.14),
                const Color(0xFFFF4B58).withValues(alpha: 0.08),
                wash,
              ),
            ),
          ),
        ),
        Positioned(
          right: -50,
          bottom: -110,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                const Color(0xFF0F234A).withValues(alpha: 0.18),
                const Color(0xFFFF4B58).withValues(alpha: 0.07),
                wash,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SlashBeam extends StatelessWidget {
  const _SlashBeam({
    required this.angle,
    required this.width,
    required this.height,
  });

  final double angle;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFFFF4B58).withValues(alpha: 0.10),
              const Color(0xFFFF4B58).withValues(alpha: 0.22),
              const Color(0xFFFF4B58).withValues(alpha: 0.10),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _FailureTopBar extends StatelessWidget {
  const _FailureTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'QRollCall',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _ScanFailureScreenState._brandBlue,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _FailureReasonTile extends StatelessWidget {
  const _FailureReasonTile({required this.reason});

  final ScanFailureReasonItem reason;

  @override
  Widget build(BuildContext context) {
    final icon = failureIconToMaterial(reason.iconKind);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _ScanFailureScreenState._cardIconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF94A3C5),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reason.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                reason.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFAEB8D0),
                      height: 1.45,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}