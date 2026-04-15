// lib/screens/change_pin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../services/encryption_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ChangePinScreen extends StatefulWidget {
  final bool isFakePin;

  const ChangePinScreen({super.key, this.isFakePin = false});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _firstPin = '';
  bool _isConfirming = false;
  bool _isError = false;
  late AnimationController _shakeController;

  // FIX: 4-digit PIN only
  static const int _maxLength = 4;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
      Future.delayed(const Duration(milliseconds: 100), _process);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _process() async {
    if (!_isConfirming) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _isConfirming = true;
      });
    } else {
      if (_pin == _firstPin) {
        if (widget.isFakePin) {
          await EncryptionService.saveFakePin(_pin);
        } else {
          await EncryptionService.savePin(_pin);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isFakePin
                  ? 'Fake PIN updated!'
                  : 'PIN updated successfully!'),
              backgroundColor: AppColors.accentGreen,
            ),
          );
          context.pop();
        }
      } else {
        HapticFeedback.vibrate();
        setState(() {
          _isError = true;
          _pin = '';
          _isConfirming = false;
          _firstPin = '';
        });
        _shakeController.forward(from: 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Icon(Icons.arrow_back,
                          size: 18, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.isFakePin ? 'Change Fake PIN' : 'Change PIN',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ).animate().fadeIn(),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isFakePin
                                ? [AppColors.accentOrange, AppColors.accentPink]
                                : AppColors.primaryGradient,
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
                          widget.isFakePin
                              ? Icons.masks_outlined
                              : Icons.pin_outlined,
                          color: Colors.white,
                          size: 34,
                        ),
                      ).animate().scale(
                        begin: const Offset(0.8, 0.8),
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      ),

                      const SizedBox(height: 24),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _isConfirming
                              ? 'Confirm new PIN'
                              : widget.isFakePin
                              ? 'Enter new Fake PIN'
                              : 'Enter new PIN',
                          key: ValueKey(_isConfirming),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        _isError
                            ? 'PINs don\'t match. Try again.'
                            : 'Enter a 4-digit PIN',
                        style: TextStyle(
                          color:
                          _isError ? AppColors.error : AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ).animate(target: _isError ? 1 : 0).shake(),

                      const SizedBox(height: 40),

                      // FIX: 4 dots instead of 6
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_maxLength, (i) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: PinDot(
                                filled: i < _pin.length, isError: _isError),
                          );
                        }),
                      ),

                      const SizedBox(height: 40),

                      NumberPad(
                        onDigitPressed: _onDigit,
                        onDelete: _onDelete,
                      ).animate().fadeIn(delay: 300.ms),
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