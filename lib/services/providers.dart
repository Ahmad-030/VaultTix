// lib/services/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';
import 'database_service.dart';
import 'encryption_service.dart';

// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) => ThemeNotifier());

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('isDarkMode') ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', state);
  }
}

// Vault mode provider (real vs fake)
final vaultModeProvider = StateProvider<bool>((ref) => false); // false = real vault

// Notes provider
final notesProvider = StateNotifierProvider<NotesNotifier, List<NoteModel>>((ref) {
  return NotesNotifier(ref);
});

class NotesNotifier extends StateNotifier<List<NoteModel>> {
  NotesNotifier(this._ref) : super([]) {
    loadNotes();
  }

  final Ref _ref;

  bool get _isFakeVault => _ref.read(vaultModeProvider);

  Future<void> loadNotes() async {
    final notes = await DatabaseService.getAllNotes(isFakeVault: _isFakeVault);
    state = notes;
  }

  Future<void> addNote(NoteModel note) async {
    await DatabaseService.insertNote(note, isFakeVault: _isFakeVault);
    await loadNotes();
  }

  Future<void> updateNote(NoteModel note) async {
    await DatabaseService.updateNote(note, isFakeVault: _isFakeVault);
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await DatabaseService.deleteNote(id);
    state = state.where((n) => n.id != id).toList();
  }

  Future<void> togglePin(String id) async {
    final note = state.firstWhere((n) => n.id == id);
    final updated = note.copyWith(isPinned: !note.isPinned, updatedAt: DateTime.now());
    await DatabaseService.updateNote(updated, isFakeVault: _isFakeVault);
    await loadNotes();
  }

  Future<List<NoteModel>> search(String query) async {
    return DatabaseService.searchNotes(query, isFakeVault: _isFakeVault);
  }
}

// Auto-lock provider
final autoLockProvider = StateNotifierProvider<AutoLockNotifier, int>((ref) => AutoLockNotifier());

class AutoLockNotifier extends StateNotifier<int> {
  AutoLockNotifier() : super(30) {
    _load();
  }

  Future<void> _load() async {
    state = await EncryptionService.getAutoLockDuration();
  }

  Future<void> setDuration(int seconds) async {
    state = seconds;
    await EncryptionService.saveAutoLockDuration(seconds);
  }
}

// Locked state
final isLockedProvider = StateProvider<bool>((ref) => true);

// View mode (grid vs list)
final isGridViewProvider = StateProvider<bool>((ref) => false);

// Search query
final searchQueryProvider = StateProvider<String>((ref) => '');
