import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Premium iOS-inspired glassmorphism toast notification.
///
/// Features:
/// - Frosted glass effect with BackdropFilter blur
/// - Semi-transparent background
/// - Smooth fade + slide animations
/// - Auto-dismiss with configurable duration
/// - Reusable across the app
class GlassToast {
  GlassToast._();

  /// Tracks the current active overlay entry to prevent duplicates.
  static OverlayEntry? _currentEntry;

  /// Shows a glassmorphism toast notification.
  ///
  /// [context] - Build context for overlay insertion
  /// [message] - The message to display
  /// [icon] - Optional icon to display before the message
  /// [duration] - How long the toast remains visible (default: 2 seconds)
  static void show({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    // Remove any existing toast first
    _currentEntry?.remove();
    _currentEntry = null;

    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (ctx) => _GlassToastWidget(
        message: message,
        icon: icon,
        duration: duration,
        onDismissed: () {
          entry?.remove();
          _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(entry);
  }

  /// Hides the currently visible toast if any.
  static void hide(BuildContext context) {
    _OverlayGlassToastState? state;
    context.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is _OverlayGlassToastState) {
        state = element.state as _OverlayGlassToastState;
        return false;
      }
      return true;
    });
    state?._dismiss();
  }
}

/// The actual toast widget rendered in the overlay.
class _GlassToastWidget extends StatefulWidget {
  const _GlassToastWidget({
    required this.message,
    this.icon,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_GlassToastWidget> createState() => _OverlayGlassToastState();
}

class _OverlayGlassToastState extends State<_GlassToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // Slide up from bottom
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    // Fade in/out
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    // Play entrance animation
    unawaited(_controller.forward());

    // Auto-dismiss after duration
    _autoDismissTimer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    unawaited(
      _controller.reverse().then((_) {
        if (mounted) {
          widget.onDismissed();
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // Position between FAB (~72dp) and BottomNavBar (~104dp)
    const baseOffset = 88.0;
    final bottomOffset = baseOffset + bottomInset;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomOffset,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _GlassToastContent(
            message: widget.message,
            icon: widget.icon,
          ),
        ),
      ),
    );
  }
}

/// The glassmorphism toast content widget.
class _GlassToastContent extends StatelessWidget {
  const _GlassToastContent({
    required this.message,
    this.icon,
  });

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            // Premium frosted glass with subtle gradient
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.white.withValues(alpha: 0.78),
                AppColors.white.withValues(alpha: 0.65),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            // Subtle border
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.5),
              width: 1.2,
            ),
            // Soft elevation shadows
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.highlight.withValues(alpha: 0.25),
                        AppColors.highlight.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: AppColors.highlight,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    letterSpacing: 0.1,
                    decoration: TextDecoration.none,
                  ) ?? const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    letterSpacing: 0.1,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}