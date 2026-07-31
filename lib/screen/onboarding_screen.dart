import 'dart:async';

import 'package:flutter/material.dart';
import '../data/security_repository.dart';
import '../data/settings_repository.dart';
import '../utils/app_colors.dart';
import '../utils/app_design.dart';
import '../utils/app_motion.dart';
import '../widget/glass_widgets.dart';
import 'lock_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.securityRepository = const SecurityRepository(),
    this.settingsRepository = const SettingsRepository(),
  });

  final SecurityRepository securityRepository;
  final SettingsRepository settingsRepository;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Personal Money',
      subtitle: 'Effortlessly track your Income and Expenses in one place with zero clutter.',
      accentColor: AppColors.lendColorDark,
    ),
    _OnboardingItem(
      icon: Icons.people_alt_rounded,
      title: 'Money Between People',
      subtitle: 'Manage Lent and Borrow amounts directly linked with your contacts.',
      accentColor: AppColors.borrowColorDark,
    ),
    _OnboardingItem(
      icon: Icons.shield_rounded,
      title: '100% Offline & Private',
      subtitle: 'Your financial data stays on your device, encrypted with AES-256 security.',
      accentColor: AppColors.highlight,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      unawaited(
        _pageController.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        ),
      );
    } else {
      _promptUserName();
    }
  }

  void _promptUserName() {
    unawaited(
      showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.highlight.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.person_rounded, color: AppColors.highlight, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Welcome to LenDen!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What should we call you?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 14),
            GlassInput(
              controller: _nameController,
              labelText: 'Your First Name',
              prefixIcon: const Icon(Icons.badge_rounded),
            ),
          ],
        ),
        actions: [
          GlassButton(
            onPressed: () {
              final name = _nameController.text.trim();
              unawaited(widget.settingsRepository.setUserName(name.isNotEmpty ? name : 'Friend'));
              Navigator.pop(context);
              _finishOnboardingAndGoToPin();
            },
            color: AppColors.highlight,
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.white),
            ),
          ),
        ],
      ),
    ),);
  }

  void _finishOnboardingAndGoToPin() async {
    await widget.settingsRepository.setHasCompletedOnboarding(true);
    if (!mounted) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LockScreen(
          securityRepository: widget.securityRepository,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar / Skip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.highlight.withValues(alpha: 0.15),
                          ),
                          child: const Icon(
                            Icons.swap_horizontal_circle_rounded,
                            color: AppColors.highlight,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'LenDen',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ),
                    if (_currentPage < _items.length - 1)
                      TextButton(
                        onPressed: _promptUserName,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          EntranceMotion(
                            key: ValueKey('icon_$index'),
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: item.accentColor.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: item.accentColor.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: item.accentColor.withValues(alpha: 0.15),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                item.icon,
                                size: 52,
                                color: item.accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          EntranceMotion(
                            key: ValueKey('title_$index'),
                            order: 1,
                            child: Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryText,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          EntranceMotion(
                            key: ValueKey('sub_$index'),
                            order: 2,
                            child: Text(
                              item.subtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.secondaryText,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Pagination & Button
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_items.length, (index) {
                        final isSelected = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isSelected ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isSelected
                                ? AppColors.highlight
                                : AppColors.secondaryText.withValues(alpha: 0.3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: GlassButton(
                        onPressed: _nextPage,
                        color: AppColors.highlight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _items.length - 1
                                  ? 'Get Started'
                                  : 'Continue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                              color: AppColors.white,
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
    );
  }
}

class _OnboardingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;

  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });
}
