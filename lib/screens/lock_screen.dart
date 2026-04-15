// lib/screens/lock_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with TickerProviderStateMixin {
  String _pin = '';
  bool _isError = false;
  int _wrongAttempts = 0;
  bool _isLocked = false;
  late AnimationController _shakeController;
  late AnimationController _glowController;

  // FIX: 4-digit PIN only
  static const int _maxLength = 4;
  static const int _maxAttempts = 5;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_isLocked || _pin.length >= _maxLength) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += digit;
      _isError = false;
    });
    if (_pin.length >= _maxLength) {
      Future.delayed(const Duration(milliseconds: 100), _verifyPin);
    }
  }

  void _onDelete() {
    if (_isLocked || _pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verifyPin() async {
    final result = await AuthService.verifyPinAndGetVaultMode(_pin);

    if (result != null) {
      final isFake = result == 'fake';
      ref.read(vaultModeProvider.notifier).state = isFake;
      ref.read(isLockedProvider.notifier).state = false;
      await ref.read(notesProvider.notifier).loadNotes();
      if (mounted) {
        HapticFeedback.mediumImpact();
        context.go('/home');
      }
    } else {
      _wrongAttempts++;
      _showError();
    }
  }

  void _showError() {
    HapticFeedback.vibrate();
    setState(() {
      _isError = true;
      _pin = '';
    });
    _shakeController.forward(from: 0);

    if (_wrongAttempts >= _maxAttempts) {
      setState(() => _isLocked = true);
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted) {
          setState(() {
            _isLocked = false;
            _wrongAttempts = 0;
          });
        }
      });
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isError = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Lottie Lock Animation with glow
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (_, child) => Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withOpacity(0.3 + _glowController.value * 0.3),
                              blurRadius: 30 + _glowController.value * 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: Lottie.asset(
                        'assets/lock.json',
                        width: 130,
                        height: 130,
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                    )
                        .animate()
                        .scale(begin: const Offset(0.5, 0.5), duration: 800.ms, curve: Curves.easeOutBack)
                        .fadeIn(duration: 600.ms),

                    const SizedBox(height: 32),

                    const Text(
                      'VaultTix',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 6),

                    Text(
                      _isLocked
                          ? 'Too many attempts. Wait 30s.'
                          : _wrongAttempts > 0
                          ? 'Wrong PIN (${_maxAttempts - _wrongAttempts} left)'
                          : 'Enter your PIN to unlock',
                      style: TextStyle(
                        color: _isLocked || _wrongAttempts > 0
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 48),

                    _buildPinDots(),

                    const SizedBox(height: 48),

                    if (!_isLocked)
                      NumberPad(
                        onDigitPressed: _onDigit,
                        onDelete: _onDelete,
                      ).animate().fadeIn(delay: 400.ms),

                    if (_isLocked) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined,
                                color: AppColors.error, size: 20),
                            SizedBox(width: 8),
                            Text('Vault locked for 30 seconds',
                                style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ).animate().fadeIn().scale(),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinDots() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: _isError ? 1 : 0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticIn,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(_isError ? 8 * (0.5 - value).abs() * 10 : 0, 0),
          child: child,
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_maxLength, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: PinDot(
                filled: i < _pin.length,
                isError: _isError,
              )
                  .animate(target: i < _pin.length ? 1 : 0)
                  .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 200.ms,
                curve: Curves.easeOutBack,
              ),
            );
          }),
        ),
      ),
    );
  }


  Widget _buildBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (_, __) => Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 300,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1,
                    colors: [
                      AppColors.primary
                          .withOpacity(0.04 + _glowController.value * 0.03),
                      Colors.transparent,
                    ],
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