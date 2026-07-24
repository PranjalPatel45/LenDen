import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_design.dart';
import 'lock_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({this.initialization, super.key});

  /// Work that must finish before leaving the splash screen.
  final Future<void>? initialization;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _progress;
  bool _startupFailed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1, curve: Curves.easeInOutCubic),
    );

    unawaited(_controller.forward());
    unawaited(_openApp());
  }

  Future<void> _openApp() async {
    try {
      await Future.wait<void>([
        Future<void>.delayed(const Duration(milliseconds: 1800)),
        ?widget.initialization,
      ]);
    } catch (_) {
      if (mounted) setState(() => _startupFailed = true);
      return;
    }

    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LockScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.04, end: 1).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scale: _logoScale.value,
                            child: const _LenDenMark(),
                          ),
                          const SizedBox(height: 30),
                          FadeTransition(
                            opacity: _contentOpacity,
                            child: SlideTransition(
                              position: _contentSlide,
                              child: const _BrandContent(),
                            ),
                          ),
                          const SizedBox(height: 42),
                          // Enhanced progress indicator with animation
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: _progress.value * value,
                                child: Container(
                                  width: 140,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.highlight.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: LinearProgressIndicator(
                                    value: _progress.value,
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(10),
                                    backgroundColor: AppColors.primary.withValues(
                                      alpha: 0.16,
                                    ),
                                    color: AppColors.highlight,
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_startupFailed) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'Unable to open your encrypted data. Please restart LenDen.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.snackbarError,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LenDenMark extends StatelessWidget {
  const _LenDenMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardSurface,
            AppColors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.highlight.withValues(alpha: 0.2),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Simplified static design for better performance
          Align(
            alignment: Alignment.topLeft,
            child: _DirectionBadge(
              color: AppColors.lendColor,
              icon: Icons.trending_up_rounded,
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: _DirectionBadge(
              color: AppColors.borrowColor,
              icon: Icons.trending_down_rounded,
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: _DirectionBadge(
              color: AppColors.highlight,
              icon: Icons.north_east_rounded,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: _DirectionBadge(
              color: AppColors.primary,
              icon: Icons.south_west_rounded,
            ),
          ),
          Center(
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 34,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionBadge extends StatelessWidget {
  const _DirectionBadge({
    required this.color,
    required this.icon,
  });

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 21, color: AppColors.primaryText),
    );
  }
}

class _BrandContent extends StatelessWidget {
  const _BrandContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Brand name with gradient
        ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryText,
                AppColors.highlight,
              ],
            ).createShader(bounds);
          },
          child: const Text(
            'LenDen',
            style: TextStyle(
              fontSize: 42,
              height: 1,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: -1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 13),
        // Tagline
        Text(
          'Track income, expenses, lending and borrowing.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 28),
        // Type pills
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: const [
            _TypePill(
              label: 'INCOME',
              icon: Icons.trending_up_rounded,
              color: AppColors.lendColorLight,
              iconColor: AppColors.lendColorDark,
            ),
            _TypePill(
              label: 'EXPENSE',
              icon: Icons.trending_down_rounded,
              color: AppColors.borrowColorLight,
              iconColor: AppColors.borrowColorDark,
            ),
            _TypePill(
              label: 'LENT',
              icon: Icons.north_east_rounded,
              color: AppColors.highlight,
              iconColor: AppColors.highlight,
            ),
            _TypePill(
              label: 'BORROWED',
              icon: Icons.south_west_rounded,
              color: AppColors.primary,
              iconColor: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({
    required this.label,
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.primaryText.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}
