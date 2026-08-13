import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../data/security_repository.dart';
import '../data/settings_repository.dart';
import '../utils/app_colors.dart';
import '../utils/app_transitions.dart';
import '../utils/app_snackbar.dart';
import '../utils/app_motion.dart';
import '../widget/glass_widgets.dart';
import 'forgot_pin_screen.dart';
import 'home_screen.dart';
import 'recovery_questions_screen.dart';

class LockScreen extends StatefulWidget {
  final bool isChangePin;
  final SecurityRepository securityRepository;
  final SettingsRepository settingsRepository;

  const LockScreen({
    super.key,
    this.isChangePin = false,
    this.securityRepository = const SecurityRepository(),
    this.settingsRepository = const SettingsRepository(),
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _localAuth = LocalAuthentication();
  final ValueNotifier<String> _enteredPin = ValueNotifier('');
  bool _isSetupMode = false;
  bool _canCheckBiometrics = false;
  bool _isWrongPin = false;
  bool _isVerifyingPin = false;
  bool _hasAutoPromptedBiometrics = false;
  PinAttemptState? _pinAttemptState;
  Timer? _lockoutTimer;

  // Separate animation controllers for better control
  late final AnimationController _entryController;
  late final AnimationController _shakeController;

  // Entry animations
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;
  late final Animation<Offset> _slideUp;

  // Shake animation
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _setupEntryAnimations();
    _setupShakeAnimation();
    unawaited(_checkSetupAndBiometrics());
    unawaited(_entryController.forward());
  }

  void _setupEntryAnimations() {
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _scaleIn = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryController,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
          ),
        );
  }

  void _setupShakeAnimation() {
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _shakeController.dispose();
    _enteredPin.dispose();
    _lockoutTimer?.cancel();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _checkSetupAndBiometrics() async {
    final hasPin = await widget.securityRepository.hasPin();
    final attemptState = !hasPin
        ? null
        : await widget.securityRepository.readPinAttemptState();

    bool canBio = false;
    if (hasPin) {
      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        canBio = canCheck && availableBiometrics.isNotEmpty;
      } on LocalAuthException {
        canBio = false;
      } catch (_) {
        canBio = false;
      }
    }

    if (!mounted) return;
    setState(() {
      _isSetupMode = !hasPin;
      _pinAttemptState = attemptState;
      _canCheckBiometrics = canBio;
    });
    _updateLockoutTimer();

    // Scenario 2: Smart Auto-Biometric Prompt on Launch
    if (!_isSetupMode &&
        _canCheckBiometrics &&
        widget.settingsRepository.isBiometricEnabled &&
        !widget.settingsRepository.preferPinOverBiometric &&
        !_isPinLocked &&
        !_hasAutoPromptedBiometrics) {
      _hasAutoPromptedBiometrics = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_authenticateWithBiometrics());
        }
      });
    }
  }

  Future<void> _savePin(String pin) async {
    await widget.securityRepository.savePin(pin);
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isPinLocked) return;
    unawaited(HapticFeedback.lightImpact());
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Use biometrics to unlock LenDen',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (authenticated && mounted) {
        await widget.securityRepository.recordSuccessfulPin();
        if (!mounted) return;
        _navigateToHome();
      }
    } on LocalAuthException catch (e) {
      if (e.code == LocalAuthExceptionCode.userCanceled ||
          e.code == LocalAuthExceptionCode.systemCanceled) {
        return;
      }

      if (mounted) {
        final message = switch (e.code) {
          LocalAuthExceptionCode.noBiometricsEnrolled =>
            'No biometrics are enrolled. Set up fingerprint or face unlock in device settings.',
          LocalAuthExceptionCode.temporaryLockout ||
          LocalAuthExceptionCode.biometricLockout =>
            'Biometrics are locked. Unlock your device and try again, or use your app PIN.',
          LocalAuthExceptionCode.noBiometricHardware ||
          LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
            'Biometric authentication is not available on this device.',
          _ =>
            'Biometric authentication could not be completed. Use your app PIN.',
        };
        AppSnackbar.showError(context: context, message: message);
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context: context,
          message:
              'Biometric authentication could not be completed. Use your app PIN.',
        );
      }
    }
  }

  void _onPinDigit(String digit) {
    if (_isVerifyingPin || _isPinLocked) return;
    if (_enteredPin.value.length < 4) {
      _enteredPin.value += digit;
      if (_enteredPin.value.length == 4) unawaited(_verifyPin());
    }
  }

  void _onPinDelete() {
    if (_isVerifyingPin || _isPinLocked) return;
    if (_enteredPin.value.isNotEmpty) {
      final pin = _enteredPin.value;
      _enteredPin.value = pin.substring(0, pin.length - 1);
    }
  }

  Future<void> _verifyPin() async {
    if (_isVerifyingPin || _isPinLocked) return;
    setState(() => _isVerifyingPin = true);

    final pin = _enteredPin.value;
    final verified = await widget.securityRepository.verifyPin(pin);
    if (verified) {
      _enteredPin.value = '';
      unawaited(HapticFeedback.mediumImpact());
      await widget.securityRepository.recordSuccessfulPin();

      // Remember User Preference:
      // If user unlocks using PIN when biometrics is available & enabled, save preference
      if (_canCheckBiometrics && widget.settingsRepository.isBiometricEnabled) {
        await widget.settingsRepository.setPreferPinOverBiometric(true);
      }

      if (!mounted) return;
      _navigateToHome();
    } else {
      unawaited(HapticFeedback.heavyImpact());
      final attemptState = await widget.securityRepository
          .recordFailedPinAttempt();
      if (!mounted) return;
      setState(() {
        _isWrongPin = true;
        _isVerifyingPin = false;
        _enteredPin.value = '';
        _pinAttemptState = attemptState;
      });
      _updateLockoutTimer();
      _shakeController.reset();
      unawaited(
        _shakeController.forward().then((_) {
          if (mounted) {
            setState(() => _isWrongPin = false);
          }
        }),
      );
      final message = attemptState.isDailyLocked
          ? 'Daily PIN limit reached. Try again tomorrow.'
          : attemptState.isLockedAt(DateTime.now())
          ? 'Too many wrong attempts. Wait 30 seconds.'
          : 'Wrong PIN. ${attemptState.attemptsRemainingToday} attempts remaining today.';
      AppSnackbar.showError(context: context, message: message);
    }
  }

  bool get _isPinLocked =>
      _pinAttemptState?.isLockedAt(DateTime.now()) ?? false;

  String get _pinStatusMessage {
    final state = _pinAttemptState;
    if (state == null) return 'Enter your PIN to continue';
    if (state.isDailyLocked) {
      return 'Daily attempt limit reached. Try again tomorrow.';
    }
    if (state.isLockedAt(DateTime.now())) {
      final remaining = state
          .lockedUntil(DateTime.now())
          .difference(DateTime.now())
          .inSeconds;
      return 'Try again in ${remaining < 1 ? 1 : remaining} seconds';
    }
    if (state.failedToday > 0) {
      return '${state.attemptsRemainingToday} PIN attempts remaining today';
    }
    return 'Enter your PIN to continue';
  }

  void _updateLockoutTimer() {
    _lockoutTimer?.cancel();
    if (!_isPinLocked) return;
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_isPinLocked) {
        timer.cancel();
        unawaited(_reloadPinAttemptState());
        return;
      }
      setState(() {});
    });
  }

  Future<void> _reloadPinAttemptState() async {
    final state = await widget.securityRepository.readPinAttemptState();
    if (!mounted) return;
    setState(() => _pinAttemptState = state);
    _updateLockoutTimer();
  }

  Future<void> _setNewPin() async {
    final pin = _newPinController.text;
    final confirm = _confirmPinController.text;
    if (pin.length != 4 || confirm.length != 4) {
      AppSnackbar.showError(context: context, message: 'PIN must be 4 digits.');
      return;
    }
    if (pin != confirm) {
      AppSnackbar.showError(context: context, message: 'PINs do not match.');
      return;
    }
    try {
      if (widget.isChangePin) {
        await _savePin(pin);
      } else {
        final saved = await Navigator.push<bool>(
          context,
          AppTransitions.slideUp<bool>(
            page: RecoveryQuestionsScreen(
              pinToSave: pin,
              securityRepository: widget.securityRepository,
            ),
          ),
        );
        if (saved != true) return;
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(
          context: context,
          message: 'Failed to save PIN. Please try again.',
        );
      }
      return;
    }
    if (!mounted) return;
    await widget.settingsRepository.setHasCompletedOnboarding(true);
    _newPinController.clear();
    _confirmPinController.clear();
    setState(() {
      _isSetupMode = false;
    });
    unawaited(HapticFeedback.mediumImpact());
    if (!mounted) return;
    AppSnackbar.showSuccess(context: context, message: 'PIN set successfully!');
    if (widget.isChangePin && mounted) {
      unawaited(Navigator.maybePop(context, true));
    } else if (mounted) {
      _navigateToHome();
    }
  }

  Future<void> _forgotPin() async {
    final newPin = await Navigator.push<String>(
      context,
      AppTransitions.slideUp<String>(
        page: ForgotPinScreen(securityRepository: widget.securityRepository),
      ),
    );
    if (newPin == null || !mounted) return;
    final attemptState = await widget.securityRepository.readPinAttemptState();
    if (!mounted) return;
    setState(() {
      _enteredPin.value = '';
      _pinAttemptState = attemptState;
    });
    unawaited(HapticFeedback.mediumImpact());
    _navigateToHome();
  }

  void _navigateToHome() {
    unawaited(
      Navigator.pushReplacement(
        context,
        AppTransitions.fadeThrough<void>(page: const HomeScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.isChangePin,
      child: (_isSetupMode || widget.isChangePin)
          ? _buildSetupScreen()
          : _buildUnlockScreen(),
    );
  }

  Widget _buildSetupScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.primary.withValues(alpha: 0.09),
              AppColors.softPeach.withValues(alpha: 0.10),
            ],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: AnimatedBuilder(
                      animation: _entryController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeIn.value,
                          child: Transform.scale(
                            scale: _scaleIn.value,
                            child: child,
                          ),
                        );
                      },
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 32,
                        ),
                        radius: 20,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!widget.isChangePin) ...[
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppColors.highlight,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryText.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 7),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.shield_rounded,
                                    size: 44,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            Text(
                              widget.isChangePin
                                  ? 'Change PIN'
                                  : 'Secure Your App',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.black,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.isChangePin
                                  ? 'Enter your new PIN'
                                  : 'Create a 4-digit PIN to protect your data',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _modernPinField(
                              controller: _newPinController,
                              label: 'Enter PIN',
                            ),
                            const SizedBox(height: 16),
                            _modernPinField(
                              controller: _confirmPinController,
                              label: 'Confirm PIN',
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: _buildPrimaryButton(
                                text: widget.isChangePin
                                    ? 'Update PIN'
                                    : 'Set PIN',
                                icon: Icons.lock_outline_rounded,
                                onPressed: _setNewPin,
                              ),
                            ),
                            if (widget.isChangePin) ...[
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 14,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockScreen() {
    final keySize = ((MediaQuery.sizeOf(context).width - 68) / 3).clamp(
      54.0,
      76.0,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 24).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      // Main content
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),

                              // Lock icon with glow
                              AnimatedBuilder(
                                animation: _entryController,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _fadeIn.value,
                                    child: Transform.scale(
                                      scale: _scaleIn.value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: _buildLockIcon(),
                              ),

                              const SizedBox(height: 20),

                              // Title
                              AnimatedBuilder(
                                animation: _slideUp,
                                builder: (context, child) {
                                  return SlideTransition(
                                    position: _slideUp,
                                    child: child,
                                  );
                                },
                                child: Column(
                                  children: [
                                    const Text(
                                      'Welcome Back',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w300,
                                        color: AppColors.black,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _pinStatusMessage,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _isPinLocked
                                            ? AppColors.snackbarError
                                            : AppColors.primaryText,
                                        fontWeight: _isPinLocked
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 36),

                              // PIN dots with shake animation
                              AnimatedBuilder(
                                animation: _shakeController,
                                builder: (context, child) {
                                  final shakeOffset = _isWrongPin
                                      ? sin(_shakeAnimation.value * 4 * pi) * 12
                                      : 0.0;
                                  return Transform.translate(
                                    offset: Offset(shakeOffset, 0),
                                    child: child,
                                  );
                                },
                                child: ValueListenableBuilder<String>(
                                  valueListenable: _enteredPin,
                                  builder: (context, pin, _) => Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(4, (index) {
                                      final isFilled = index < pin.length;
                                      return AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 160,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isFilled
                                              ? AppColors.highlight
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isFilled
                                                ? AppColors.highlight
                                                : AppColors.primaryText
                                                      .withValues(alpha: 0.4),
                                            width: 2,
                                          ),
                                          boxShadow: isFilled
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.highlight
                                                        .withValues(alpha: 0.4),
                                                    blurRadius: 7,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 36),

                              // Biometric option
                              if (_canCheckBiometrics &&
                                  widget.settingsRepository.isBiometricEnabled &&
                                  !_isPinLocked)
                                AnimatedBuilder(
                                  animation: _entryController,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: (_entryController.value - 0.5)
                                          .clamp(0.0, 1.0),
                                      child: child,
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      Text(
                                        'Quick Unlock',
                                        style: TextStyle(
                                          color: AppColors.primaryText
                                              .withValues(alpha: 0.8),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      PressScale(
                                        pressedScale: 0.92,
                                        hoverScale: 1.025,
                                        child: Semantics(
                                          button: true,
                                          label: 'Unlock with biometrics',
                                          child: Material(
                                            color: Colors.transparent,
                                            shape: const CircleBorder(),
                                            child: InkWell(
                                              customBorder:
                                                  const CircleBorder(),
                                              onTap:
                                                  _authenticateWithBiometrics,
                                              child: Container(
                                                width: 58,
                                                height: 58,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: AppColors.highlight,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors
                                                          .primaryText
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                      blurRadius: 14,
                                                      offset: const Offset(
                                                        0,
                                                        6,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.fingerprint,
                                                  size: 28,
                                                  color: AppColors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 20),

                              // Number pad
                              AnimatedBuilder(
                                animation: _entryController,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: (_entryController.value - 0.3)
                                        .clamp(0.0, 1.0),
                                    child: child,
                                  );
                                },
                                child: IgnorePointer(
                                  ignoring: _isPinLocked || _isVerifyingPin,
                                  child: RepaintBoundary(
                                    child: AnimatedOpacity(
                                      opacity: _isPinLocked ? 0.38 : 1,
                                      duration: const Duration(milliseconds: 200),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildNumberRow([
                                              '1',
                                              '2',
                                              '3',
                                            ], keySize),
                                            const SizedBox(height: 6),
                                            _buildNumberRow([
                                              '4',
                                              '5',
                                              '6',
                                            ], keySize),
                                            const SizedBox(height: 6),
                                            _buildNumberRow([
                                              '7',
                                              '8',
                                              '9',
                                            ], keySize),
                                            const SizedBox(height: 6),
                                            _buildNumberRow([
                                              '',
                                              '0',
                                              'delete',
                                            ], keySize),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              TextButton(
                                onPressed: _isVerifyingPin ? null : _forgotPin,
                                child: const Text('Forgot PIN?'),
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLockIcon() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColors.highlight,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryText.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.lock_outline_rounded,
          size: 40,
          color: AppColors.white,
        ),
      ),
    );
  }

  Widget _buildNumberRow(List<String> keys, double keySize) {
    return Row(
      children: keys
          .map(
            (key) => Expanded(
              child: Center(
                child: key == 'delete'
                    ? _buildKeyButton(
                        size: keySize,
                        semanticLabel: 'Delete digit',
                        child: const Icon(
                          Icons.backspace_outlined,
                          color: AppColors.black,
                          size: 26,
                        ),
                        onTap: _onPinDelete,
                      )
                    : key.isEmpty
                    ? SizedBox(width: keySize, height: keySize)
                    : _buildKeyButton(
                        size: keySize,
                        semanticLabel: 'Digit $key',
                        child: Text(
                          key,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                        onTap: () => _onPinDigit(key),
                      ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildKeyButton({
    required double size,
    required String semanticLabel,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return PressScale(
      pressedScale: 0.92,
      hoverScale: 1.02,
      child: Semantics(
        button: true,
        label: semanticLabel,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modernPinField({
    required TextEditingController controller,
    required String label,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassInputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorder, width: 1),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            obscureText: true,
            style: const TextStyle(color: AppColors.black, fontSize: 18),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: AppColors.black.withValues(alpha: 0.7),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GlassButton(
      onPressed: onPressed,
      radius: 16,
      color: AppColors.highlight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
