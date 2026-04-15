// lib/screens/privacy_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled) // no JS needed — more secure
      ..setBackgroundColor(AppColors.darkBg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() => _loadingProgress = progress / 100);
          },
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            // Block all external navigation — policy doc is local only
            if (request.url.startsWith('file://')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadFlutterAsset('assets/privacy_policy.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar().animate().fadeIn(duration: 300.ms),

            // Slim loading progress indicator
            AnimatedOpacity(
              opacity: _isLoading ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: LinearProgressIndicator(
                value: _loadingProgress == 0 ? null : _loadingProgress,
                backgroundColor: AppColors.darkBorder,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 2,
              ),
            ),

            // WebView fills remaining space
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),

                  // Loading overlay — fades out when page is ready
                  if (_isLoading)
                    Container(
                      color: AppColors.darkBg,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.privacy_tip_outlined,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            )
                                .animate(
                                    onPlay: (c) => c.repeat(reverse: true))
                                .scale(
                                  begin: const Offset(0.88, 0.88),
                                  end: const Offset(1.12, 1.12),
                                  duration: 900.ms,
                                  curve: Curves.easeInOut,
                                ),
                            const SizedBox(height: 18),
                            const Text(
                              'Loading Privacy Policy...',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 200.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.darkBg,
        border: Border(
          bottom: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
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
          const SizedBox(width: 12),

          // Icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.privacy_tip_outlined,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),

          // Title + subtitle
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'VaultTix · Local document',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Reload button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _controller.reload();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: const Icon(Icons.refresh_rounded,
                  size: 16, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
