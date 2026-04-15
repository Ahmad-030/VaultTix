// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _scrollController.addListener(() {
      final show = _scrollController.offset > 60;
      if (show != _showTitle) setState(() => _showTitle = show);
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _lock() {
    HapticFeedback.mediumImpact();
    ref.read(isLockedProvider.notifier).state = true;
    context.go('/lock');
  }

  void _createNote() {
    HapticFeedback.lightImpact();
    context.push('/note/new');
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final isGrid = ref.watch(isGridViewProvider);
    final isFakeVault = ref.watch(vaultModeProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          _buildBackground(),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(isFakeVault, isGrid),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildStatsBar(notes)),
              if (notes.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                _buildNotesList(notes, isGrid),
            ],
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack),
        child: FloatingActionButton(
          onPressed: _createNote,
          backgroundColor: AppColors.primary,
          elevation: 8,
          child: const Icon(Icons.add, size: 28, color: Colors.white),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(duration: 3.seconds, color: Colors.white.withOpacity(0.2)),
      ),
    );
  }

  Widget _buildAppBar(bool isFakeVault, bool isGrid) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.darkBg,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: AppColors.primaryGradient,
                          ).createShader(bounds),
                          child: const Text(
                            'VaultTix',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        if (isFakeVault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentOrange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.accentOrange.withOpacity(0.3)),
                            ),
                            child: const Text(
                              'DECOY',
                              style: TextStyle(
                                color: AppColors.accentOrange,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Text(
                      'Your private vault',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),
              ),
              Row(
                children: [
                  _buildIconButton(
                    icon: isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                    onTap: () => ref.read(isGridViewProvider.notifier).state = !isGrid,
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    icon: Icons.settings_outlined,
                    onTap: () => context.push('/settings'),
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    icon: Icons.lock_rounded,
                    onTap: _lock,
                    color: AppColors.primary,
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () => context.push('/search'),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: AppColors.textMuted, size: 20),
              SizedBox(width: 10),
              Text('Search notes...', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildStatsBar(List<NoteModel> notes) {
    final pinned = notes.where((n) => n.isPinned).length;
    final secure = notes.where((n) => n.isSecure).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          _buildStat('${notes.length}', 'Notes', Icons.note_alt_outlined),
          const SizedBox(width: 12),
          _buildStat('$pinned', 'Pinned', Icons.push_pin_outlined),
          const SizedBox(width: 12),
          _buildStat('$secure', 'Secure', Icons.shield_outlined),
        ],
      ).animate().fadeIn(delay: 400.ms),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
                Text(label,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesList(List<NoteModel> notes, bool isGrid) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      sliver: isGrid
          ? SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => AnimationConfiguration.staggeredGrid(
                  position: i,
                  duration: const Duration(milliseconds: 400),
                  columnCount: 2,
                  child: FadeInAnimation(
                    child: ScaleAnimation(
                      child: _buildNoteItem(notes[i], isGrid: true),
                    ),
                  ),
                ),
                childCount: notes.length,
              ),
            )
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => AnimationConfiguration.staggeredList(
                  position: i,
                  duration: const Duration(milliseconds: 400),
                  child: SlideAnimation(
                    verticalOffset: 30,
                    child: FadeInAnimation(
                      child: _buildNoteItem(notes[i], isGrid: false),
                    ),
                  ),
                ),
                childCount: notes.length,
              ),
            ),
    );
  }

  Widget _buildNoteItem(NoteModel note, {required bool isGrid}) {
    return NoteCard(
      note: note,
      isGrid: isGrid,
      onTap: () => context.push('/note/${note.id}'),
      onDelete: () => _confirmDelete(note),
      onPin: () => ref.read(notesProvider.notifier).togglePin(note.id),
    );
  }

  void _confirmDelete(NoteModel note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.delete_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            const Text('Delete Note?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            const Text('This action cannot be undone.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.darkBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ref.read(notesProvider.notifier).deleteNote(note.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.note_add_outlined, size: 44, color: AppColors.primary),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1.05, 1.05),
            duration: 2.seconds,
            curve: Curves.easeInOut,
          ),
          const SizedBox(height: 24),
          const Text('Your vault is empty',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          const Text('Tap + to add your first secure note',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildBackground() {
    return Positioned(
      top: -200,
      right: -100,
      child: Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [AppColors.primary.withOpacity(0.04), Colors.transparent],
          ),
        ),
      ),
    );
  }
}
