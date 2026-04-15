// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
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
                // Logo
                _buildLogo(),
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
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Text(
              'v1.0.0 · End-to-End Encrypted',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            )
                .animate()
                .fadeIn(delay: 1500.ms, duration: 600.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary
                    .withOpacity(0.3 + _glowController.value * 0.3),
                blurRadius: 30 + _glowController.value * 20,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: AppColors.accent
                    .withOpacity(0.1 + _glowController.value * 0.15),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_rounded,
            color: Colors.white,
            size: 48,
          ),
        );
      },
    )
        .animate()
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          duration: 800.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 600.ms);
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
