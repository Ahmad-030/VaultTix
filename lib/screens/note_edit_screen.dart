// lib/screens/note_edit_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';

class NoteEditScreen extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteEditScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends ConsumerState<NoteEditScreen>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  late AnimationController _saveIndicatorController;

  NoteModel? _existingNote;
  List<String> _tags = [];
  bool _isPinned = false;
  bool _isSecure = false;
  String _selectedColor = 'default';
  bool _hasChanges = false;
  bool _isSaving = false;
  Timer? _autoSaveTimer;

  bool get isNew => widget.noteId == null || widget.noteId == 'new';

  @override
  void initState() {
    super.initState();
    _saveIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadNote();
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _saveIndicatorController.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _onChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _autoSave);
  }

  Future<void> _loadNote() async {
    if (!isNew) {
      final notes = ref.read(notesProvider);
      final note = notes.firstWhere((n) => n.id == widget.noteId,
          orElse: () => NoteModel(
                id: '',
                title: '',
                content: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ));
      if (note.id.isNotEmpty) {
        setState(() {
          _existingNote = note;
          _titleController.text = note.title;
          _contentController.text = note.content;
          _tags = List.from(note.tags);
          _isPinned = note.isPinned;
          _isSecure = note.isSecure;
          _selectedColor = note.color ?? 'default';
        });
      }
    }
  }

  Future<void> _autoSave() async {
    if (!_hasChanges) return;
    setState(() => _isSaving = true);
    await _save(showFeedback: false);
    setState(() => _isSaving = false);
    _saveIndicatorController.forward(from: 0);
  }

  Future<void> _save({bool showFeedback = true}) async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      if (showFeedback && mounted) context.pop();
      return;
    }

    final now = DateTime.now();
    final note = NoteModel(
      id: _existingNote?.id ?? const Uuid().v4(),
      title: title.isEmpty ? 'Untitled' : title,
      content: content,
      tags: _tags,
      isPinned: _isPinned,
      isSecure: _isSecure,
      createdAt: _existingNote?.createdAt ?? now,
      updatedAt: now,
      color: _selectedColor,
    );

    if (isNew || _existingNote == null) {
      await ref.read(notesProvider.notifier).addNote(note);
    } else {
      await ref.read(notesProvider.notifier).updateNote(note);
    }

    setState(() {
      _hasChanges = false;
      _existingNote = note;
    });

    if (showFeedback && mounted) {
      HapticFeedback.mediumImpact();
      context.pop();
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = NoteColors.colorMap[_selectedColor] ?? NoteColors.colorMap['default']!;

    return Scaffold(
      backgroundColor: Color(colors[0]),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Title field
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                        filled: false,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 4),

                    // Date
                    Text(
                      _formatDate(DateTime.now()),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 16),

                    // Divider
                    Container(height: 1, color: AppColors.darkBorder.withOpacity(0.5)),
                    const SizedBox(height: 16),

                    // Content field
                    TextField(
                      controller: _contentController,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        height: 1.7,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Write your note here...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 16),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                        filled: false,
                      ),
                      maxLines: null,
                      minLines: 10,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 20),

                    // Tags
                    _buildTagsSection().animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 80),
                  ],
                ),
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
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: AppColors.darkBorder.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _save(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.darkCardElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textPrimary),
            ),
          ),

          // Auto-save indicator
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _saveIndicatorController,
            builder: (_, __) => Opacity(
              opacity: 1 - _saveIndicatorController.value,
              child: Row(
                children: [
                  if (_isSaving) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Saving...',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ] else if (!_hasChanges && _existingNote != null) ...[
                    const Icon(Icons.check_circle_outline,
                        size: 14, color: AppColors.accentGreen),
                    const SizedBox(width: 6),
                    const Text('Saved',
                        style: TextStyle(color: AppColors.accentGreen, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),

          const Spacer(),

          // Options
          GestureDetector(
            onTap: () => setState(() => _isPinned = !_isPinned),
            child: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => setState(() => _isSecure = !_isSecure),
            child: Icon(
              _isSecure ? Icons.shield : Icons.shield_outlined,
              color: _isSecure ? AppColors.accentOrange : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _showColorPicker,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.primaryGradient),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.palette_outlined, size: 14, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _save(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.primaryGradient),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Save',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return GestureDetector(
                onTap: () => setState(() => _tags.remove(tag)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('#$tag',
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(width: 4),
                      const Icon(Icons.close, size: 12, color: AppColors.primaryLight),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Add tag...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixText: '# ',
                  prefixStyle: const TextStyle(color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.darkBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.darkBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: AppColors.darkCard,
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addTag,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showColorPicker() {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Note Color',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: NoteColors.colors.map((colorName) {
                final colorMap = NoteColors.colorMap[colorName]!;
                final isSelected = colorName == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = colorName);
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(colorMap[0]), Color(colorMap[1])],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.darkBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: AppColors.primary, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
