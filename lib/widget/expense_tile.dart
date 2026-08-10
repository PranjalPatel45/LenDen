import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:to_do/model/expense_model.dart';
import 'package:to_do/utils/category_helper.dart';
import 'package:to_do/utils/currency_helper.dart';
import 'package:to_do/utils/transaction_type.dart';
import '../utils/app_colors.dart';
import '../utils/app_design.dart';
import '../utils/app_motion.dart';

class TransactionSwipeTile extends StatefulWidget {
  const TransactionSwipeTile({
    super.key,
    required this.expense,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    this.currencySymbol = '\$',
  });

  final Expense expense;
  final String currencySymbol;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  State<TransactionSwipeTile> createState() => _TransactionSwipeTileState();
}

class _TransactionSwipeTileState extends State<TransactionSwipeTile>
    with TickerProviderStateMixin {
  static const double _actionExtent = 164;
  static const double _deleteSlideExtent = 286;
  static final ValueNotifier<Object?> _openTileKey = ValueNotifier<Object?>(
    null,
  );

  late final AnimationController _slideController;
  late final AnimationController _deleteController;
  late final Animation<double> _deleteScale;
  late final Animation<double> _deleteFade;

  double _offset = 0;
  bool _deleting = false;

  Object get _tileKey => widget.expense.key ?? widget.expense.hashCode;

  @override
  void initState() {
    super.initState();
    _slideController =
        AnimationController.unbounded(vsync: this, duration: AppMotion.standard)
          ..addListener(() {
            setState(() => _offset = _slideController.value);
          });
    _deleteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 210),
    );
    final deleteCurve = CurvedAnimation(
      parent: _deleteController,
      curve: Curves.easeInCubic,
    );
    _deleteScale = Tween<double>(begin: 1, end: 0.985).animate(deleteCurve);
    _deleteFade = Tween<double>(begin: 1, end: 0).animate(deleteCurve);
    _openTileKey.addListener(_handleOpenTileChanged);
  }

  @override
  void didUpdateWidget(covariant TransactionSwipeTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expense.key != widget.expense.key) {
      _close(immediate: true);
    }
  }

  @override
  void dispose() {
    _openTileKey.removeListener(_handleOpenTileChanged);
    _slideController.dispose();
    _deleteController.dispose();
    super.dispose();
  }

  void _handleOpenTileChanged() {
    if (_openTileKey.value != _tileKey && _offset != 0) {
      _close();
    }
  }

  void _animateTo(double target) {
    _slideController
      ..stop()
      ..value = _offset;
    unawaited(
      _slideController.animateTo(
        target,
        duration: motionDuration(context, AppMotion.standard),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _open() {
    _openTileKey.value = _tileKey;
    _animateTo(-_actionExtent);
  }

  void _close({bool immediate = false}) {
    if (_openTileKey.value == _tileKey) {
      _openTileKey.value = null;
    }
    if (immediate) {
      _slideController.stop();
      if (mounted) {
        setState(() => _offset = 0);
      } else {
        _offset = 0;
      }
      return;
    }
    _animateTo(0);
  }

  void _handleDragStart(DragStartDetails details) {
    if (_deleting) return;
    _slideController.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_deleting) return;
    final nextOffset = (_offset + details.delta.dx)
        .clamp(-_actionExtent, 0.0)
        .toDouble();
    if (nextOffset == _offset) return;
    if (nextOffset < 0) _openTileKey.value = _tileKey;
    setState(() => _offset = nextOffset);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_deleting) return;
    if (_offset <= -44) {
      _open();
    } else {
      _close();
    }
  }

  Future<void> _delete() async {
    if (_deleting) return;
    _deleting = true;
    _openTileKey.value = null;
    _slideController
      ..stop()
      ..value = _offset;
    await _slideController.animateTo(
      -_deleteSlideExtent,
      duration: motionDuration(context, const Duration(milliseconds: 150)),
      curve: Curves.easeOutCubic,
    );
    await _deleteController.forward();
    if (mounted) {
      await widget.onDelete();
    }
  }

  void _edit() {
    _close(immediate: true);
    widget.onEdit();
  }

  double get _actionProgress =>
      (_offset.abs() / _actionExtent).clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TapRegion(
        enabled: _offset != 0,
        onTapOutside: (_) => _close(),
        child: FadeTransition(
          opacity: _deleteFade,
          child: ScaleTransition(
            scale: _deleteScale,
            child: ClipRect(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: _actionProgress == 0,
                      child: Opacity(
                        opacity: _actionProgress,
                        child: _SwipeActions(onEdit: _edit, onDelete: _delete),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(_offset, 0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_offset != 0) {
                          _close();
                        } else {
                          widget.onTap?.call();
                        }
                      },
                      onHorizontalDragStart: _handleDragStart,
                      onHorizontalDragUpdate: _handleDragUpdate,
                      onHorizontalDragEnd: _handleDragEnd,
                      onHorizontalDragCancel: _close,
                      child: ExpenseTile(
                        expense: widget.expense,
                        currencySymbol: widget.currencySymbol,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeActions extends StatelessWidget {
  const _SwipeActions({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _SwipeActionButton(
            label: 'Edit',
            icon: Icons.edit_rounded,
            color: AppColors.highlight,
            onTap: onEdit,
          ),
          const SizedBox(width: 8),
          _SwipeActionButton(
            label: 'Delete',
            icon: Icons.delete_rounded,
            color: AppColors.borrowColorDark,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                height: 58,
                constraints: const BoxConstraints(minWidth: 70),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  color: AppColors.white.withValues(alpha: 0.84),
                  border: Border.all(
                    color: color.withValues(alpha: 0.34),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.14),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String currencySymbol;

  const ExpenseTile({
    super.key,
    required this.expense,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = _colorForType(expense.type);
    final icon = _iconForType(expense.type);
    final isPositive = TransactionType.isPositive(expense.type);
    final signedAmount =
        '${isPositive ? '+' : '-'}${formatCurrency(expense.amount, currencySymbol)}';
    final categoryInfo = parseCategoryAndReason(expense.reason);
    final displayCategory = expense.category ?? categoryInfo.category;
    final displayNote = categoryInfo.cleanReason;

    return Semantics(
      button: true,
      label:
          '${expense.type}, ${expense.contactName ?? expense.title}, $signedAmount, ${formatDate(expense.date)}',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.white.withValues(alpha: 0.88),
          border: Border.all(
            color: AppColors.primaryText.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryText.withValues(alpha: 0.045),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3,
              child: ColoredBox(color: tileColor.withValues(alpha: 0.85)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 13, 16, 13),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      color: tileColor.withValues(alpha: 0.12),
                    ),
                    child: Icon(icon, size: 18, color: tileColor),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.contactName ?? expense.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: AppColors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              formatDate(expense.date),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontSize: 12,
                                    color: AppColors.primaryText.withValues(
                                      alpha: 0.58,
                                    ),
                                  ),
                            ),
                            if (displayCategory != null && displayCategory.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: tileColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  displayCategory,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: _darkColorForType(expense.type),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (displayNote.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            displayNote,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: 12,
                                  color: AppColors.primaryText.withValues(
                                    alpha: 0.52,
                                  ),
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Flexible(
                    flex: 1,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            signedAmount,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _darkColorForType(expense.type),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            expense.type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.65,
                              color: tileColor,
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
    );
  }

  Color _colorForType(String type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.lendColor;
      case TransactionType.expense:
        return AppColors.borrowColor;
      case TransactionType.lent:
        return AppColors.highlight;
      case TransactionType.borrowed:
        return AppColors.borrowedColor;
      default:
        return AppColors.grey;
    }
  }

  Color _darkColorForType(String type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.lendColorDark;
      case TransactionType.expense:
        return AppColors.borrowColorDark;
      case TransactionType.lent:
        return AppColors.highlight;
      case TransactionType.borrowed:
        return AppColors.borrowedColorDark;
      default:
        return AppColors.primaryText;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case TransactionType.income:
        return Icons.trending_up_rounded;
      case TransactionType.expense:
        return Icons.trending_down_rounded;
      case TransactionType.lent:
        return Icons.north_east_rounded;
      case TransactionType.borrowed:
        return Icons.south_west_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}
