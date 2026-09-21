import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
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

  Future<void> _exportPdf() async {
    final repository = const ExpenseRepository();
    final expenses = repository.getAll();
    if (expenses.isEmpty) {
      AppSnackbar.showError(
        context: context,
        message: 'No transactions to export.',
      );
      return;
    }

    try {
      AppSnackbar.show(
        context: context,
        message: 'Generating PDF statement...',
      );
      final pdfBytes = await ReportHelper.generatePdfReport(
        expenses,
        currencySymbol: _currencySymbol,
        currencyCode: _currencyCode,
      );

      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'LenDen_Statement_$dateStr.pdf',
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context: context,
          message: 'Failed to generate PDF statement: $e',
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

    try {
      final csv = ReportHelper.generateCsvReport(expenses);
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${tempDir.path}/LenDen_Statement_$dateStr.csv');
      await file.writeAsString(csv);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          text: 'LenDen Financial Statement (CSV)',
          subject: 'LenDen Statement',
        ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context: context,
          message: 'Failed to export CSV: $e',
        );
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
                        onPressed: isVerifying ? null : () => unawaited(verify()),
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
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
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
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                        child: Text(
                          currency.symbol,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        '${currency.name} (${currency.code})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.lendColorDark,
                              size: 22,
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
                              message:
                                  'Failed to change currency. Please try again.',
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
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              const SectionLabel(label: 'Security', icon: Icons.shield_rounded),
              const SizedBox(height: 8),
              GlassCard(
                radius: 20,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'App Lock (PIN)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
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
                        leading:
                            const GlassIcon(icon: Icons.quiz_outlined),
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
                        secondary: const GlassIcon(
                            icon: Icons.fingerprint_rounded),
                        title: const Text(
                          'Biometric Unlock',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          !_hasPin
                              ? 'Set a PIN to enable biometric unlock'
                              : (widget.settingsRepository.isBiometricEnabled
                                  ? 'Unlock app with biometrics'
                                  : 'Biometric unlock disabled'),
                        ),
                        value: _hasPin &&
                            widget.settingsRepository.isBiometricEnabled,
                        onChanged: !_hasPin
                            ? null
                            : (value) async {
                                await widget.settingsRepository
                                    .setBiometricEnabled(value);
                                if (mounted) setState(() {});
                              },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SectionLabel(
                  label: 'Categories', icon: Icons.category_rounded),
              const SizedBox(height: 8),
              GlassCard(
                radius: 20,
                child: ListTile(
                  leading: const GlassIcon(
                    icon: Icons.edit_note_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Manage Categories',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${widget.settingsRepository.categories.length} categories — tap to manage',
                    style: TextStyle(
                      color: AppColors.secondaryText,
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
              const SizedBox(height: 28),
              const SectionLabel(
                  label: 'Currency', icon: Icons.payments_rounded),
              const SizedBox(height: 8),
              GlassCard(
                radius: 20,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    child: Text(
                      _currencySymbol,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    '$_currencyName ($_currencyCode)',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Tap to change app currency'),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.grey,
                  ),
                  onTap: _showCurrencyPicker,
                ),
              ),
              const SizedBox(height: 28),
              const SectionLabel(
                  label: 'Statements & Export', icon: Icons.ios_share_rounded),
              const SizedBox(height: 8),
              GlassCard(
                radius: 20,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    ListTile(
                      leading: const GlassIcon(
                        icon: Icons.picture_as_pdf_rounded,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Export Statement (PDF)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle:
                          const Text('Generate formatted PDF report & share'),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.grey,
                      ),
                      onTap: _exportPdf,
                    ),
                    ListTile(
                      leading: const GlassIcon(
                        icon: Icons.table_chart_rounded,
                        color: AppColors.lendColorDark,
                      ),
                      title: const Text(
                        'Export Statement (CSV)',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle:
                          const Text('Export spreadsheet file (Excel/Sheets)'),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.grey,
                      ),
                      onTap: _exportCsv,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SectionLabel(label: 'About', icon: Icons.info_rounded),
              const SizedBox(height: 8),
              GlassCard(
                radius: 20,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    ListTile(
                      leading:
                          const GlassIcon(icon: Icons.info_outline_rounded),
                      title: const Text(
                        'Version',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('1.0.0'),
                    ),
                    ListTile(
                      leading: const GlassIcon(
                        icon: Icons.code_rounded,
                        color: AppColors.accent,
                      ),
                      title: const Text(
                        'LenDen Personal Finance',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('Flutter Mobile App'),
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
