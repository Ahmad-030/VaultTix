// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/encryption_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  int _autoLockDuration = 30;
  bool _hasFakePin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bio = await EncryptionService.isBiometricEnabled();
    final bioAvail = await AuthService.isBiometricAvailable();
    final fake = await EncryptionService.hasFakePin();
    final lock = await EncryptionService.getAutoLockDuration();
    setState(() {
      _biometricEnabled = bio;
      _biometricAvailable = bioAvail;
      _hasFakePin = fake;
      _autoLockDuration = lock;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildSection(
                      'Security',
                      Icons.security,
                      AppColors.primary,
                      [
                        _buildNavItem(
                          'Change PIN',
                          'Update your real vault PIN',
                          Icons.pin_outlined,
                          () => context.push('/change-pin'),
                        ),
                        _buildNavItem(
                          _hasFakePin ? 'Change Fake PIN' : 'Set Fake PIN',
                          'Decoy vault protection',
                          Icons.masks_outlined,
                          () => context.push('/change-fake-pin'),
                        ),
                        if (_biometricAvailable)
                          _buildToggleItem(
                            'Biometric Unlock',
                            'Fingerprint / Face ID',
                            Icons.fingerprint,
                            _biometricEnabled,
                            (v) async {
                              await EncryptionService.setBiometricEnabled(v);
                              setState(() => _biometricEnabled = v);
                            },
                          ),
                      ],
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 16),

                    _buildSection(
                      'Auto-Lock',
                      Icons.timer_outlined,
                      AppColors.accent,
                      [
                        _buildAutoLockOptions(),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 16),

                    _buildSection(
                      'Appearance',
                      Icons.palette_outlined,
                      AppColors.accentGreen,
                      [
                        _buildToggleItem(
                          'Dark Mode',
                          'Toggle light/dark theme',
                          Icons.dark_mode_outlined,
                          isDark,
                          (_) => ref.read(themeProvider.notifier).toggle(),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 16),

                    _buildSection(
                      'Data',
                      Icons.storage_outlined,
                      AppColors.accentOrange,
                      [
                        _buildNavItem(
                          'About',
                          'Developer info & version',
                          Icons.info_outline,
                          () => context.push('/about'),
                        ),
                        _buildNavItem(
                          'Privacy Policy',
                          'How we handle your data',
                          Icons.privacy_tip_outlined,
                          () => context.push('/privacy'),
                        ),
                        _buildDangerItem(
                          'Clear All Data',
                          'Delete all notes & settings',
                          Icons.delete_forever_outlined,
                          _confirmClearAll,
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
              child: const Icon(Icons.arrow_back, size: 18, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Settings',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(title,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildToggleItem(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(title,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      trailing: Switch(value: value, onChanged: onChanged),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _buildDangerItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: () {
        HapticFeedback.heavyImpact();
        onTap();
      },
      leading: Icon(icon, color: AppColors.error, size: 20),
      title: Text(title,
          style: const TextStyle(color: AppColors.error, fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.error, size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildAutoLockOptions() {
    final options = [
      (0, 'Instant'),
      (30, '30 seconds'),
      (60, '1 minute'),
      (300, '5 minutes'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((opt) {
          final isSelected = _autoLockDuration == opt.$1;
          return GestureDetector(
            onTap: () async {
              setState(() => _autoLockDuration = opt.$1);
              await ref.read(autoLockProvider.notifier).setDuration(opt.$1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.darkCardElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.darkBorder,
                ),
              ),
              child: Text(
                opt.$2,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All Data?',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text(
          'This will permanently delete all notes, PIN, and settings. This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseService.clearAllNotes();
              await EncryptionService.clearAll();
              if (mounted) context.go('/create-pin');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
