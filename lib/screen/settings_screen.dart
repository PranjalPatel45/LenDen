import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../data/expense_repository.dart';
import '../data/security_repository.dart';
import '../data/settings_repository.dart';
import '../utils/app_colors.dart';
import '../utils/app_snackbar.dart';
import '../utils/currency_helper.dart';
import '../utils/app_design.dart';
import '../utils/app_transitions.dart';
import '../utils/report_helper.dart';
import '../widget/glass_widgets.dart';
import 'lock_screen.dart';
import 'manage_categories_screen.dart';
import 'recovery_questions_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.securityRepository = const SecurityRepository(),
    this.settingsRepository = const SettingsRepository(),
  });

  final SecurityRepository securityRepository;
  final SettingsRepository settingsRepository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasPin = false;
  bool _hasRecoveryQuestions = false;
  bool _canCheckBiometrics = false;
  String _currencySymbol = '\$';
  String _currencyCode = 'USD';

  @override
  void initState() {
    super.initState();
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    final hasPin = await widget.securityRepository.hasPin();
    final recovery = await widget.securityRepository.readRecoveryQuestions();
    final localAuth = LocalAuthentication();
    bool canBio = false;
    try {
      final canCheck = await localAuth.canCheckBiometrics;
      final enrolledBiometrics = await localAuth.getAvailableBiometrics();
      canBio = canCheck && enrolledBiometrics.isNotEmpty;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _hasRecoveryQuestions = recovery != null;
      _canCheckBiometrics = canBio;
      _currencySymbol = widget.settingsRepository.currencySymbol;
      _currencyCode = widget.settingsRepository.currencyCode;
    });
  }

  Future<void> _changePin() async {
    final result = await Navigator.push(
      context,
      AppTransitions.slideRight(
        page: LockScreen(
          isChangePin: true,
          securityRepository: widget.securityRepository,
        ),
      ),
    );
    if (result == true) {
      await _loadSettings();
    }
  }

  Future<void> _manageRecoveryQuestions() async {
    final saved = await Navigator.push<bool>(
      context,
      AppTransitions.slideRight<bool>(
        page: RecoveryQuestionsScreen(
          securityRepository: widget.securityRepository,
        ),
      ),
    );
    if (saved == true) {
      await _loadSettings();
      if (mounted) {
        AppSnackbar.showSuccess(
          context: context,
          message: 'Recovery questions saved',
        );
      }
    }
  }

  Future<void> _removePin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable App Lock?'),
        content: const Text(
          'Your financial data will no longer be protected by a PIN or biometric authentication.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Disable',
              style: TextStyle(color: AppColors.snackbarError),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final verified = await _verifyPinBeforeRemoval();
      if (!verified || !mounted) return;
      try {
        await widget.securityRepository.removePin();
      } catch (_) {
        if (mounted) {
          AppSnackbar.showError(
            context: context,
            message: 'Failed to remove PIN. Please try again.',
          );
        }
        return;
      }
      if (!mounted) return;
      setState(() {
        _hasPin = false;
      });
      if (mounted) {
        AppSnackbar.showSuccess(
          context: context,
          message: 'App Lock disabled',
        );
      }
    }
  }

  Future<void> _exportCsv() async {
    final repository = const ExpenseRepository();
    final expenses = repository.getAll();
    if (expenses.isEmpty) {
      AppSnackbar.showError(
        context: context,
        message: 'No transactions to export.',
      );
      return;
    }
    final csv = ReportHelper.generateCsvReport(expenses);
    await Clipboard.setData(ClipboardData(text: csv));
    if (mounted) {
      AppSnackbar.showSuccess(
        context: context,
        message: 'CSV report copied to clipboard!',
      );
    }
  }

  Future<void> _backupJson() async {
    final repository = const ExpenseRepository();
    final expenses = repository.getAll();
    if (expenses.isEmpty) {
      AppSnackbar.showError(
        context: context,
        message: 'No transactions to backup.',
      );
      return;
    }
    final jsonStr = ReportHelper.generateJsonBackup(expenses);
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (mounted) {
      AppSnackbar.showSuccess(
        context: context,
        message: 'JSON backup copied to clipboard!',
      );
    }
  }

  Future<void> _restoreJson() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste your JSON backup below:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '[\n  {\n    "title": ...\n  }\n]',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Restore',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      try {
        final restored = ReportHelper.parseJsonBackup(controller.text.trim());
        if (restored.isEmpty) {
          if (mounted) {
            AppSnackbar.showError(
              context: context,
              message: 'Invalid or empty backup.',
            );
          }
          return;
        }
        final repository = const ExpenseRepository();
        for (final expense in restored) {
          await repository.add(expense);
        }
        if (mounted) {
          AppSnackbar.showSuccess(
            context: context,
            message: 'Restored ${restored.length} transactions!',
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.showError(
            context: context,
            message: 'Failed to parse JSON backup.',
          );
        }
      }
    }
  }

  void _navigateToManageCategories() {
    unawaited(
      Navigator.push(
        context,
        AppTransitions.slideRight(
          page: ManageCategoriesScreen(
            settingsRepository: widget.settingsRepository,
          ),
        ),
      ),
    );
  }

  Future<bool> _verifyPinBeforeRemoval() async {
    final hasPin = await widget.securityRepository.hasPin();
    if (!mounted) return false;
    if (!hasPin) {
      await _loadSettings();
      return false;
    }

    final controller = TextEditingController();
    try {
      return await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) {
              String? errorText;
              bool isVerifying = false;
              return StatefulBuilder(
                builder: (context, setDialogState) {
                  Future<void> verify() async {
                    if (isVerifying) return;
                    setDialogState(() => isVerifying = true);
                    final verified = await widget.securityRepository.verifyPin(
                      controller.text,
                    );
                    if (!dialogContext.mounted) return;
                    if (verified) {
                      Navigator.pop(dialogContext, true);
                      return;
                    }
                    setDialogState(() {
                      isVerifying = false;
                      errorText = 'Incorrect PIN. App Lock was not disabled.';
                      controller.clear();
                    });
                  }

                  return AlertDialog(
                    title: const Text('Verify your PIN'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter your current PIN to disable App Lock and biometric unlock.',
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: controller,
                          autofocus: true,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onSubmitted: (_) => unawaited(verify()),
                          decoration: InputDecoration(
                            hintText: 'Current 4-digit PIN',
                            errorText: errorText,
                            counterText: '',
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: isVerifying
                            ? null
                            : () => unawaited(verify()),
                        child: const Text('Verify and Disable'),
                      ),
                    ],
                  );
                },
              );
            },
          ) ??
          false;
    } finally {
      controller.clear();
      controller.dispose();
    }
  }

  void _showCurrencyPicker() {
    unawaited(
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.cardSurface,
        clipBehavior: Clip.antiAlias,
        builder: (context) {
          return SafeArea(
            child: ResponsiveContent(
              maxWidth: 620,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const GlassIcon(icon: Icons.payments_rounded),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Select Currency',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ...supportedCurrencies.map((currency) {
                    final isSelected = currency.code == _currencyCode;
                    return ListTile(
                      leading: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                        child: Text(
                          currency.symbol,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text('${currency.name} (${currency.code})'),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.lendColorDark,
                            )
                          : null,
                      onTap: () async {
                        try {
                          await widget.settingsRepository.setCurrency(
                            currency.symbol,
                            currency.code,
                          );
                        } catch (_) {
                          if (context.mounted) {
                            AppSnackbar.showError(
                              context: context,
                              message: 'Failed to change currency. Please try again.',
                            );
                          }
                          return;
                        }
                        if (!mounted) return;
                        setState(() {
                          _currencySymbol = currency.symbol;
                          _currencyCode = currency.code;
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settingsRepository.listenable,
      builder: (context, _) {
        _currencySymbol = widget.settingsRepository.currencySymbol;
        _currencyCode = widget.settingsRepository.currencyCode;

        return ResponsiveContent(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
        children: [
          const SectionLabel(label: 'Security', icon: Icons.shield_rounded),
          const SizedBox(height: 8),
          GlassCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('App Lock (PIN)'),
                  subtitle: Text(_hasPin ? 'PIN is set' : 'No PIN set'),
                  value: _hasPin,
                  onChanged: (value) {
                    if (value) {
                      unawaited(_changePin());
                    } else {
                      unawaited(_removePin());
                    }
                  },
                ),
                if (_hasPin)
                  ListTile(
                    leading: const GlassIcon(icon: Icons.quiz_outlined),
                    title: const Text('Recovery Questions'),
                    subtitle: Text(
                      _hasRecoveryQuestions
                          ? 'Configured — tap to update'
                          : 'Not configured',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _manageRecoveryQuestions,
                  ),
                if (_canCheckBiometrics)
                  SwitchListTile(
                    secondary: const GlassIcon(icon: Icons.fingerprint_rounded),
                    title: const Text('Biometric Unlock'),
                    subtitle: Text(
                      !_hasPin
                          ? 'Set a PIN to enable biometric unlock'
                          : (widget.settingsRepository.isBiometricEnabled
                              ? 'Unlock app with biometrics'
                              : 'Biometric unlock disabled'),
                    ),
                    value: _hasPin && widget.settingsRepository.isBiometricEnabled,
                    onChanged: !_hasPin
                        ? null
                        : (value) async {
                            await widget.settingsRepository.setBiometricEnabled(value);
                            if (mounted) setState(() {});
                          },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const SectionLabel(label: 'Categories', icon: Icons.category_rounded),
          const SizedBox(height: 8),
          GlassCard(
            radius: 16,
            child: ListTile(
              leading: const GlassIcon(
                icon: Icons.edit_note_rounded,
                color: AppColors.highlight,
              ),
              title: const Text('Manage Categories'),
              subtitle: Text(
                '${widget.settingsRepository.categories.length} categories — tap to add, edit, or delete',
                style: TextStyle(
                  color: AppColors.primaryText.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.grey,
              ),
              onTap: _navigateToManageCategories,
            ),
          ),
          const SizedBox(height: 30),
          const SectionLabel(label: 'Currency', icon: Icons.payments_rounded),
          const SizedBox(height: 8),
          GlassCard(
            radius: 16,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.highlight.withValues(alpha: 0.12),
                ),
                child: Text(
                  _currencySymbol,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(
                '$_currencyName ($_currencyCode)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Tap to change currency',
                style: TextStyle(
                  color: AppColors.primaryText.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.grey,
              ),
              onTap: _showCurrencyPicker,
            ),
          ),
          const SizedBox(height: 30),
          const SectionLabel(label: 'Data & Export', icon: Icons.ios_share_rounded),
          const SizedBox(height: 8),
          GlassCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                ListTile(
                  leading: const GlassIcon(
                    icon: Icons.table_chart_outlined,
                    color: AppColors.highlight,
                  ),
                  title: const Text('Export Report (CSV)'),
                  subtitle: const Text('Copy CSV statement to clipboard'),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.grey,
                  ),
                  onTap: _exportCsv,
                ),
                ListTile(
                  leading: const GlassIcon(
                    icon: Icons.cloud_upload_outlined,
                    color: AppColors.lendColorDark,
                  ),
                  title: const Text('Backup Data (JSON)'),
                  subtitle: const Text('Copy database backup to clipboard'),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.grey,
                  ),
                  onTap: _backupJson,
                ),
                ListTile(
                  leading: const GlassIcon(
                    icon: Icons.cloud_download_outlined,
                    color: AppColors.borrowedColorDark,
                  ),
                  title: const Text('Restore Data'),
                  subtitle: const Text('Import transactions from JSON backup'),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.grey,
                  ),
                  onTap: _restoreJson,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const SectionLabel(label: 'About', icon: Icons.info_rounded),
          const SizedBox(height: 8),
          GlassCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                ListTile(
                  leading: const GlassIcon(icon: Icons.info_outline_rounded),
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
                ListTile(
                  leading: const GlassIcon(
                    icon: Icons.code_rounded,
                    color: AppColors.accent,
                  ),
                  title: const Text('Developer'),
                  subtitle: const Text('Flutter Developer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  },
);
}

  String get _currencyName {
    for (var c in supportedCurrencies) {
      if (c.code == _currencyCode) return c.name;
    }
    return 'US Dollar';
  }
}
