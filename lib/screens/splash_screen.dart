// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../services/encryption_service.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    final hasPin = await EncryptionService.hasPin();
    if (hasPin) {
      context.go('/lock');
    } else {
      context.go('/create-pin');
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Color(0xFF0D1128),
                  AppColors.darkBg,
                ],
              ),
            ),
          ),

          // Glow orbs
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) {
              return Stack(
                children: [
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.2,
                    left: -80,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary
                            .withOpacity(0.05 + _glowController.value * 0.05),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withOpacity(0.1 + _glowController.value * 0.1),
                            blurRadius: 80,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.15,
                    right: -60,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent
                            .withOpacity(0.03 + _glowController.value * 0.04),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent
                                .withOpacity(0.08 + _glowController.value * 0.08),
                            blurRadius: 80,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                const SizedBox(height: 28),

                // App name
                Text(
                  'VaultTix',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 800.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 10),

                // Tagline
                Text(
                  'Smart security for your private world',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 900.ms, duration: 800.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 60),

                // Loading indicator
                _buildLoadingBar()
                    .animate()
                    .fadeIn(delay: 1200.ms, duration: 600.ms),
              ],
            ),
          ),

          // Bottom version

        ],
      ),
    );
  }


  Widget _buildLoadingBar() {
    return SizedBox(
      width: 120,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 2000),
        builder: (context, value, _) {
          return Column(
            children: [
              LinearProgressIndicator(
                value: value,
                backgroundColor: AppColors.darkBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                borderRadius: BorderRadius.circular(4),
                minHeight: 3,
              ),
            ],
          );
        },
      ),
    );
  }
}
