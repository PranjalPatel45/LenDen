import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/security_repository.dart';
import '../utils/app_colors.dart';
import '../utils/app_design.dart';
import '../utils/app_snackbar.dart';
import '../widget/glass_widgets.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({
    super.key,
    this.securityRepository = const SecurityRepository(),
  });

  final SecurityRepository securityRepository;

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final _firstAnswerController = TextEditingController();
  final _secondAnswerController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  RecoveryQuestionSetup? _setup;
  RecoveryAttemptState? _attemptState;
  Timer? _timer;
  bool _isLoading = true;
  bool _isBusy = false;
  bool _answersVerified = false;
  bool _hideAnswers = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _firstAnswerController.dispose();
    _secondAnswerController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final setup = await widget.securityRepository.readRecoveryQuestions();
    final attempts = setup == null
        ? null
        : await widget.securityRepository.readRecoveryAttemptState();
    if (!mounted) return;
    setState(() {
      _setup = setup;
      _attemptState = attempts;
      _isLoading = false;
    });
    _updateTimer();
  }

  bool get _isLocked => _attemptState?.isLockedAt(DateTime.now()) ?? false;

  String get _attemptMessage {
    final state = _attemptState;
    if (state == null) return '';
    if (state.isDailyLocked) {
      return 'Recovery is locked until tomorrow.';
    }
    if (state.isLockedAt(DateTime.now())) {
      final seconds = state
          .lockedUntil(DateTime.now())
          .difference(DateTime.now())
          .inSeconds;
      return 'Too many wrong answers. Try again in ${seconds < 1 ? 1 : seconds} seconds.';
    }
    if (state.failedToday > 0) {
      return '${state.attemptsRemainingToday} recovery attempts remaining today.';
    }
    return '';
  }

  void _updateTimer() {
    _timer?.cancel();
    if (!_isLocked) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_isLocked) {
        timer.cancel();
        unawaited(_reloadAttempts());
        return;
      }
      setState(() {});
    });
  }

  Future<void> _reloadAttempts() async {
    final state = await widget.securityRepository.readRecoveryAttemptState();
    if (!mounted) return;
    setState(() => _attemptState = state);
    _updateTimer();
  }

  Future<void> _verifyAnswers() async {
    if (_isBusy || _isLocked) return;
    if (_firstAnswerController.text.trim().isEmpty ||
        _secondAnswerController.text.trim().isEmpty) {
      _showError('Enter both recovery answers.');
      return;
    }
    setState(() => _isBusy = true);
    final verified = await widget.securityRepository.verifyRecoveryAnswers(
      answerOne: _firstAnswerController.text,
      answerTwo: _secondAnswerController.text,
    );
    if (!mounted) return;
    if (verified) {
      await widget.securityRepository.resetRecoveryAttempts();
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _answersVerified = true;
        _attemptState = RecoveryAttemptState.fresh(DateTime.now());
      });
      return;
    }

    final state = await widget.securityRepository.recordFailedRecoveryAttempt();
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _attemptState = state;
      _firstAnswerController.clear();
      _secondAnswerController.clear();
    });
    _updateTimer();
    _showError(
      state.isDailyLocked
          ? 'Recovery attempt limit reached. Try again tomorrow.'
          : state.isLockedAt(DateTime.now())
          ? 'Too many wrong answers. Wait 30 seconds.'
          : 'The recovery answers did not match.',
    );
  }

  Future<void> _saveNewPin() async {
    final pin = _newPinController.text;
    if (pin.length != 4) {
      _showError('PIN must be 4 digits.');
      return;
    }
    if (pin != _confirmPinController.text) {
      _showError('PINs do not match.');
      return;
    }
    setState(() => _isBusy = true);
    try {
      await widget.securityRepository.savePin(pin);
      await widget.securityRepository.resetRecoveryAttempts();
      if (!mounted) return;
      _newPinController.clear();
      _confirmPinController.clear();
      Navigator.pop(context, pin);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      _showError('Could not reset the PIN. Try again.');
    }
  }

  void _showError(String message) {
    AppSnackbar.showError(
      context: context,
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot PIN')),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const GlassLoadingState();
    if (_setup == null) {
      return GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        radius: 18,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_encryption_outlined, size: 56, color: AppColors.highlight),
            SizedBox(height: 16),
            Text(
              'Recovery questions were not set for this PIN.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryText),
            ),
            SizedBox(height: 8),
            Text(
              'Unlock using your PIN or biometrics, then add recovery questions from Settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.primaryText),
            ),
          ],
        ),
      );
    }
    if (_answersVerified) return _buildNewPinForm();
    return _buildAnswerForm();
  }

  Widget _buildAnswerForm() {
    final setup = _setup!;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.quiz_outlined, size: 56, color: AppColors.highlight),
          const SizedBox(height: 16),
          Text(
            'Answer both recovery questions',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _firstAnswerController,
            obscureText: _hideAnswers,
            enabled: !_isLocked && !_isBusy,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: setup.questionOne),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _secondAnswerController,
            obscureText: _hideAnswers,
            enabled: !_isLocked && !_isBusy,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _verifyAnswers(),
            decoration: InputDecoration(
              labelText: setup.questionTwo,
              suffixIcon: IconButton(
                tooltip: _hideAnswers ? 'Show answers' : 'Hide answers',
                onPressed: () => setState(() => _hideAnswers = !_hideAnswers),
                icon: Icon(
                  _hideAnswers ? Icons.visibility_outlined : Icons.visibility_off,
                ),
              ),
            ),
          ),
          if (_attemptMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _attemptMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isLocked
                    ? AppColors.snackbarError
                    : AppColors.secondaryText,
                fontWeight: _isLocked ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
          const SizedBox(height: 24),
          GlassButton(
            onPressed: _isBusy || _isLocked ? null : _verifyAnswers,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, size: 20, color: AppColors.white),
                SizedBox(width: 8),
                Text('Verify Answers'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPinForm() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.lock_reset_rounded,
            size: 56,
            color: AppColors.highlight,
          ),
          const SizedBox(height: 16),
          Text(
            'Create a new PIN',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          _pinField(_newPinController, 'New 4-digit PIN'),
          const SizedBox(height: 16),
          _pinField(_confirmPinController, 'Confirm new PIN'),
          const SizedBox(height: 24),
          GlassButton(
            onPressed: _isBusy ? null : _saveNewPin,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_open_rounded, size: 20, color: AppColors.white),
                SizedBox(width: 8),
                Text('Reset PIN'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pinField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      decoration: InputDecoration(labelText: label),
    );
  }
}
