// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../models/note_model.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  List<NoteModel> _results = [];
  bool _isSearching = false;
  String _filter = 'all'; // all, pinned, recent, secure

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadAll() {
    final notes = ref.read(notesProvider);
    setState(() => _results = notes);
  }

  Future<void> _onSearch() async {
    final query = _searchController.text.trim();
    setState(() => _isSearching = query.isNotEmpty);

    if (query.isEmpty) {
      _applyFilter();
      return;
    }

    final results = await ref.read(notesProvider.notifier).search(query);
    setState(() => _results = _applyFilterToList(results));
  }

  void _applyFilter() {
    final notes = ref.read(notesProvider);
    setState(() => _results = _applyFilterToList(notes));
  }

  List<NoteModel> _applyFilterToList(List<NoteModel> notes) {
    switch (_filter) {
      case 'pinned':
        return notes.where((n) => n.isPinned).toList();
      case 'secure':
        return notes.where((n) => n.isSecure).toList();
      case 'recent':
        final sorted = List<NoteModel>.from(notes)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return sorted.take(10).toList();
      default:
        return notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildFilters(),
            Expanded(
              child: _results.isEmpty
                  ? _buildEmptyState()
                  : AnimationLimiter(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: _results.length,
                        itemBuilder: (ctx, i) => AnimationConfiguration.staggeredList(
                          position: i,
                          duration: const Duration(milliseconds: 350),
                          child: SlideAnimation(
                            verticalOffset: 20,
                            child: FadeInAnimation(
                              child: NoteCard(
                                note: _results[i],
                                onTap: () => context.push('/note/${_results[i].id}'),
                                onDelete: () => ref.read(notesProvider.notifier).deleteNote(_results[i].id),
                                onPin: () => ref.read(notesProvider.notifier).togglePin(_results[i].id),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search notes, tags...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _applyFilter();
                        },
                        child: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.darkCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildFilters() {
    final filters = [
      ('all', 'All', Icons.notes),
      ('pinned', 'Pinned', Icons.push_pin_outlined),
      ('recent', 'Recent', Icons.schedule_outlined),
      ('secure', 'Secure', Icons.shield_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isActive = _filter == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _filter = f.$1);
                  _onSearch();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.darkCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppColors.primary : AppColors.darkBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(f.$3,
                          size: 14,
                          color: isActive ? Colors.white : AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(f.$2,
                          style: TextStyle(
                            color: isActive ? Colors.white : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            _isSearching ? 'No results found' : 'No notes yet',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}
