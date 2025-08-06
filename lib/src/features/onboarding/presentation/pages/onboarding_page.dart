import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/theme/app_spacing.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding step data without gradients (gradients will be created dynamically with theme)
  final List<OnboardingStepData> _stepData = [
    OnboardingStepData(
      title: 'Track Your Expenses',
      description:
          'Monitor your spending habits with detailed categorization and real-time tracking. Get insights into where your money goes.',
      icon: Icons.account_balance_wallet_outlined,
      gradientType: OnboardingGradientType.primary,
    ),
    OnboardingStepData(
      title: 'Split Bills Easily',
      description:
          'Share expenses with friends and family effortlessly. Keep track of who owes what and settle up quickly.',
      icon: Icons.people_outline,
      gradientType: OnboardingGradientType.success,
    ),
    OnboardingStepData(
      title: 'Smart Insights',
      description:
          'Get personalized financial insights and recommendations to help you make better spending decisions.',
      icon: Icons.analytics_outlined,
      gradientType: OnboardingGradientType.warning,
    ),
    OnboardingStepData(
      title: 'Bank-Level Security',
      description:
          'Your financial data is protected with industry-leading security measures. Your privacy is our priority.',
      icon: Icons.security_outlined,
      gradientType: OnboardingGradientType.secondary,
    ),
  ];

  // Create theme-based gradient for onboarding step
  LinearGradient _createGradient(
    BuildContext context,
    OnboardingGradientType type,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (type) {
      case OnboardingGradientType.primary:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primaryContainer],
        );
      case OnboardingGradientType.success:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.tertiary, colorScheme.tertiaryContainer],
        );
      case OnboardingGradientType.warning:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.secondary, colorScheme.secondaryContainer],
        );
      case OnboardingGradientType.secondary:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.8),
            colorScheme.primary,
          ],
        );
    }
  }

  void _nextPage() {
    if (_currentPage < _stepData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      GoRouter.of(context).go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: _stepData.length,
        itemBuilder: (context, index) {
          final stepData = _stepData[index];
          final gradient = _createGradient(context, stepData.gradientType);
          return _buildOnboardingStep(stepData, gradient, index);
        },
      ),
    );
  }

  Widget _buildOnboardingStep(
    OnboardingStepData stepData,
    LinearGradient gradient,
    int index,
  ) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Skip button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withValues(alpha: 0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 2),

              // Icon with circles background effect
              Container(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer circle
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withValues(alpha: 0.1),
                      ),
                    ),
                    // Middle circle
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withValues(alpha: 0.2),
                      ),
                    ),
                    // Inner circle with icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: Icon(
                        stepData.icon,
                        size: 40,
                        color: gradient.colors.first,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Title
              Text(
                stepData.title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  stepData.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.9),
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 2),

              // Progress indicator
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (index + 1) / _stepData.length,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Page indicator and progress text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${index + 1}/${_stepData.length}',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: List.generate(_stepData.length, (dotIndex) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.radiusXs / 2,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              dotIndex == index
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onPrimary
                                      .withValues(alpha: 0.3),
                        ),
                      );
                    }),
                  ),
                  Text(
                    '${((index + 1) / _stepData.length * 100).toInt()}%',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Navigation buttons
              Row(
                children: [
                  if (index > 0) ...[
                    Expanded(
                      child: _buildButton(
                        onPressed: _previousPage,
                        text: 'Previous',
                        isSecondary: true,
                        currentGradient: gradient,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                  ],
                  Expanded(
                    child: _buildButton(
                      onPressed: _nextPage,
                      text:
                          index == _stepData.length - 1
                              ? 'Get Started'
                              : 'Next',
                      isSecondary: false,
                      currentGradient: gradient,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required String text,
    required bool isSecondary,
    required LinearGradient currentGradient,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color:
            isSecondary
                ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border:
            isSecondary
                ? Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withValues(alpha: 0.3),
                )
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSecondary && text == 'Previous') ...[
                  Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        isSecondary
                            ? Theme.of(context).colorScheme.onPrimary
                            : currentGradient.colors.first,
                  ),
                ),
                if (!isSecondary && text != 'Get Started') ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    text == 'Get Started'
                        ? Icons.rocket_launch
                        : Icons.arrow_forward,
                    color: currentGradient.colors.first,
                    size: 20,
                  ),
                ],
                if (text == 'Get Started') ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.rocket_launch,
                    color: currentGradient.colors.first,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

/// Enum for different gradient types used in onboarding
enum OnboardingGradientType { primary, success, warning, secondary }

/// Data class for onboarding step information
class OnboardingStepData {
  final String title;
  final String description;
  final IconData icon;
  final OnboardingGradientType gradientType;

  OnboardingStepData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientType,
  });
}
