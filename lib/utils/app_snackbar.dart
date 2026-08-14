import 'dart:async';

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// A custom overlay snackbar that positions between the FAB and BottomNavBar.
///
/// Unlike `ScaffoldMessenger.showSnackBar()` which is constrained within the
/// Scaffold, this renders into the app's [Overlay] so it can overlap both the
/// FAB and Bottom Navigation Bar for a modern floating effect.
class AppSnackbar {
  AppSnackbar._();

  /// The vertical offset from the screen bottom edge where the snackbar sits,
  /// placing it between the FAB (~72dp) and BottomNavBar (~104dp).
  static const double _bottomOffset = 88;

  /// Horizontal margins on left and right.
  static const double _horizontalMargin = 16;

  // ── API ────────────────────────────────────────────────────────────────

  /// Show an info/neutral snackbar.
  static void show({
    required BuildContext context,
    required String message,
    Duration duration = AppColors.snackBarDuration,
  }) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.snackbarNeutral,
      duration: duration,
    );
  }

  /// Show a success snackbar.
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = AppColors.snackBarDuration,
  }) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.snackbarSuccess,
      duration: duration,
    );
  }

  /// Show an error snackbar.
  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = AppColors.snackBarDuration,
  }) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.snackbarError,
      duration: duration,
    );
  }

  /// Show a snackbar with an undo action.
  static void showWithAction({
    required BuildContext context,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Color backgroundColor = AppColors.snackbarError,
    Duration duration = AppColors.deletionSnackBarDuration,
  }) {
    _show(
      context: context,
      message: message,
      backgroundColor: backgroundColor,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Tracks the current active overlay entry so we can remove it before
  /// showing a new one.
  static OverlayEntry? _currentEntry;

  // ── Internal ──────────────────────────────────────────────────────────

  static void _show({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Remove any existing overlay snackbar first
    if (_currentEntry != null) {
      try {
        _currentEntry!.remove();
      } catch (_) {}
      _currentEntry = null;
    }

    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (ctx) => _OverlaySnackbar(
        message: message,
        backgroundColor: backgroundColor,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismissed: () {
          try {
            entry?.remove();
          } catch (_) {}
          if (_currentEntry == entry) {
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(entry);
  }
}

/// The actual snackbar widget rendered inside the [Overlay].
class _OverlaySnackbar extends StatefulWidget {
  const _OverlaySnackbar({
    required this.message,
    required this.backgroundColor,
    required this.duration,
    this.actionLabel,
    this.onAction,
    required this.onDismissed,
  });

  final String message;
  final Color backgroundColor;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  @override
  State<_OverlaySnackbar> createState() => _OverlaySnackbarState();
}

class _OverlaySnackbarState extends State<_OverlaySnackbar>
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
      duration: const Duration(milliseconds: 240),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.38), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    // Play entrance
    unawaited(_controller.forward());

    // Auto-dismiss
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
    final bottomOffset = AppSnackbar._bottomOffset + bottomInset;

    return Positioned(
      left: AppSnackbar._horizontalMargin,
      right: AppSnackbar._horizontalMargin,
      bottom: bottomOffset,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onHorizontalDragEnd: (_) => _dismiss(),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: widget.backgroundColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.actionLabel != null &&
                        widget.onAction != null) ...[
                      const SizedBox(width: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          widget.onAction?.call();
                          _dismiss();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            widget.actionLabel!,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
