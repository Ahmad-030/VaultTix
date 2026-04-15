// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/encryption_service.dart';
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
  int _autoLockDuration = 30;
  bool _hasFakePin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fake = await EncryptionService.hasFakePin();
    final lock = await EncryptionService.getAutoLockDuration();
    setState(() {
      _hasFakePin = fake;
      _autoLockDuration = lock;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final isDark = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(c),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    _buildSection(
                      context,
                      c,
                      'Security',
                      Icons.security,
                      AppColors.primary,
                      [
                        _buildNavItem(c, 'Change PIN', 'Update your real vault PIN',
                            Icons.pin_outlined, () => context.push('/change-pin')),
                        _buildNavItem(
                          c,
                          _hasFakePin ? 'Change Fake PIN' : 'Set Fake PIN',
                          'Decoy vault protection',
                          Icons.masks_outlined,
                              () => context.push('/change-fake-pin'),
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 16),

                    _buildSection(
                      context,
                      c,
                      'Auto-Lock',
                      Icons.timer_outlined,
                      AppColors.accent,
                      [_buildAutoLockOptions(c)],
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 16),

                    _buildSection(
                      context,
                      c,
                      'Appearance',
                      Icons.palette_outlined,
                      AppColors.accentGreen,
                      [
                        _buildToggleItem(
                          c,
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
                      context,
                      c,
                      'Data',
                      Icons.storage_outlined,
                      AppColors.accentOrange,
                      [
                        _buildNavItem(c, 'About', 'Developer info & version',
                            Icons.info_outline, () => context.push('/about')),
                        _buildNavItem(c, 'Privacy Policy', 'How we handle your data',
                            Icons.privacy_tip_outlined,
                                () => context.push('/privacy')),
                        _buildDangerItem(c, 'Clear All Data',
                            'Delete all notes & settings',
                            Icons.delete_forever_outlined, _confirmClearAll),
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

  Widget _buildHeader(AppColorsExtension c) {
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
                color: c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border),
              ),
              child: Icon(Icons.arrow_back, size: 18, color: c.textPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Settings',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildSection(
      BuildContext context,
      AppColorsExtension c,
      String title,
      IconData icon,
      Color color,
      List<Widget> children,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
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
                  style: TextStyle(
                    color: c.textSecondary,
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

  Widget _buildNavItem(AppColorsExtension c, String title, String subtitle,
      IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      leading: Icon(icon, color: c.textSecondary, size: 20),
      title: Text(title,
          style: TextStyle(
              color: c.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500)),
      subtitle:
      Text(subtitle, style: TextStyle(color: c.textMuted, fontSize: 12)),
      trailing:
      Icon(Icons.chevron_right, color: c.textMuted, size: 18),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildToggleItem(
      AppColorsExtension c,
      String title,
      String subtitle,
      IconData icon,
      bool value,
      Function(bool) onChanged,
      ) {
    return ListTile(
      leading: Icon(icon, color: c.textSecondary, size: 20),
      title: Text(title,
          style: TextStyle(
              color: c.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500)),
      subtitle:
      Text(subtitle, style: TextStyle(color: c.textMuted, fontSize: 12)),
      trailing: Switch(value: value, onChanged: onChanged),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _buildDangerItem(AppColorsExtension c, String title, String subtitle,
      IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: () {
        HapticFeedback.heavyImpact();
        onTap();
      },
      leading: Icon(icon, color: AppColors.error, size: 20),
      title: Text(title,
          style: const TextStyle(
              color: AppColors.error,
              fontSize: 15,
              fontWeight: FontWeight.w500)),
      subtitle:
      Text(subtitle, style: TextStyle(color: c.textMuted, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.error, size: 18),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildAutoLockOptions(AppColorsExtension c) {
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
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : c.cardElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : c.border,
                ),
              ),
              child: Text(
                opt.$2,
                style: TextStyle(
                  color: isSelected ? Colors.white : c.textSecondary,
                  fontSize: 13,
                  fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _confirmClearAll() {
    final c = context.appColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear All Data?',
            style: TextStyle(
                color: c.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'This will permanently delete all notes, PIN, and settings. This cannot be undone.',
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: c.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseService.clearAllNotes();
              await EncryptionService.clearAll();
              if (mounted) context.go('/create-pin');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Clear All',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}