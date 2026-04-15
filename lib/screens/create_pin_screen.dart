// lib/screens/create_pin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../services/encryption_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

enum CreatePinStep { setPin, confirmPin, setFakePin, confirmFakePin, done }

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _firstPin = '';
  CreatePinStep _step = CreatePinStep.setPin;
  bool _isError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  // FIX: 4-digit PIN only — no min/max range
  static const int _maxLength = 4;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_pin.length >= _maxLength) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += digit;
      _isError = false;
    });
    if (_pin.length == _maxLength) {
      Future.delayed(const Duration(milliseconds: 100), _processPin);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _processPin() async {
    if (_pin.length < _maxLength) return;

    switch (_step) {
      case CreatePinStep.setPin:
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _step = CreatePinStep.confirmPin;
        });
        break;

      case CreatePinStep.confirmPin:
        if (_pin == _firstPin) {
          await EncryptionService.savePin(_pin);
          setState(() {
            _pin = '';
            _firstPin = '';
            _step = CreatePinStep.setFakePin;
          });
        } else {
          _showError();
        }
        break;

      case CreatePinStep.setFakePin:
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _step = CreatePinStep.confirmFakePin;
        });
        break;

      case CreatePinStep.confirmFakePin:
        if (_pin == _firstPin) {
          await EncryptionService.saveFakePin(_pin);
          if (mounted) context.go('/lock');
        } else {
          _showError();
        }
        break;

      case CreatePinStep.done:
        break;
    }
  }

  void _showError() {
    HapticFeedback.vibrate();
    setState(() {
      _isError = true;
      _pin = '';
    });
    _shakeController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isError = false);
    });
  }

  String get _title {
    switch (_step) {
      case CreatePinStep.setPin:
        return 'Create Your PIN';
      case CreatePinStep.confirmPin:
        return 'Confirm Your PIN';
      case CreatePinStep.setFakePin:
        return 'Set Fake PIN';
      case CreatePinStep.confirmFakePin:
        return 'Confirm Fake PIN';
      case CreatePinStep.done:
        return 'All Set!';
    }
  }

  String get _subtitle {
    switch (_step) {
      case CreatePinStep.setPin:
        return 'Choose a 4-digit PIN to secure your vault';
      case CreatePinStep.confirmPin:
        return 'Enter your PIN again to confirm';
      case CreatePinStep.setFakePin:
        return 'Set a decoy PIN that opens an empty vault';
      case CreatePinStep.confirmFakePin:
        return 'Confirm your fake PIN';
      case CreatePinStep.done:
        return 'Your vault is ready!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackground(),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    _buildStepIndicator().animate().fadeIn(duration: 500.ms),

                    const SizedBox(height: 40),

                    _buildIcon(),

                    const SizedBox(height: 32),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        key: ValueKey(_step),
                        children: [
                          Text(
                            _title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _subtitle,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),
                    ),

                    const SizedBox(height: 40),

                    // PIN dots with shake
                    AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            _isError
                                ? 12 * (0.5 - _shakeAnim.value).abs() * 8
                                : 0,
                            0,
                          ),
                          child: child,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_maxLength, (i) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: PinDot(
                              filled: i < _pin.length,
                              isError: _isError,
                            ),
                          );
                        }),
                      ),
                    ),

                    if (_isError) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'PINs don\'t match. Try again.',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ).animate().fadeIn(duration: 200.ms).shake(),
                    ],

                    const SizedBox(height: 40),

                    NumberPad(
                      onDigitPressed: _onDigit,
                      onDelete: _onDelete,
                    ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                    // Skip fake PIN
                    if (_step == CreatePinStep.setFakePin) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          if (mounted) context.go('/lock');
                        },
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.03),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        _step == CreatePinStep.setFakePin ||
            _step == CreatePinStep.confirmFakePin
            ? Icons.masks_outlined
            : Icons.lock_rounded,
        color: Colors.white,
        size: 34,
      ),
    ).animate(key: ValueKey(_step)).scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1, 1),
      duration: 400.ms,
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      CreatePinStep.setPin,
      CreatePinStep.confirmPin,
      CreatePinStep.setFakePin,
      CreatePinStep.confirmFakePin,
    ];
    final currentIndex = steps.indexOf(_step);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length, (i) {
        final isActive = i <= currentIndex;
        final isCurrent = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isCurrent ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.darkBorder,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}