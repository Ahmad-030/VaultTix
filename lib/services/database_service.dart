// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';
import 'encryption_service.dart';

class DatabaseService {
  static Database? _database;
  static const _dbName = 'vaulttix.db';
  static const _version = 1;

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        tags TEXT DEFAULT '[]',
        isPinned INTEGER DEFAULT 0,
        isSecure INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        color TEXT DEFAULT 'default',
        isFakeVault INTEGER DEFAULT 0
      )
    ''');
  }

  // Notes CRUD
  static Future<void> insertNote(NoteModel note, {bool isFakeVault = false}) async {
    final db = await database;
    final map = note.toMap();
    map['isFakeVault'] = isFakeVault ? 1 : 0;

    // Encrypt sensitive content
    map['title'] = await EncryptionService.encrypt(note.title);
    map['content'] = await EncryptionService.encrypt(note.content);

    await db.insert('notes', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<NoteModel>> getAllNotes({bool isFakeVault = false}) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'isFakeVault = ?',
      whereArgs: [isFakeVault ? 1 : 0],
      orderBy: 'isPinned DESC, updatedAt DESC',
    );

    final notes = <NoteModel>[];
    for (final map in maps) {
      final decryptedMap = Map<String, dynamic>.from(map);
      decryptedMap['title'] = await EncryptionService.decrypt(map['title'] as String);
      decryptedMap['content'] = await EncryptionService.decrypt(map['content'] as String);
      notes.add(NoteModel.fromMap(decryptedMap));
    }
    return notes;
  }

  static Future<void> updateNote(NoteModel note, {bool isFakeVault = false}) async {
    final db = await database;
    final map = note.toMap();
    map['isFakeVault'] = isFakeVault ? 1 : 0;
    map['title'] = await EncryptionService.encrypt(note.title);
    map['content'] = await EncryptionService.encrypt(note.content);

    await db.update('notes', map, where: 'id = ?', whereArgs: [note.id]);
  }

  static Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<NoteModel>> searchNotes(String query, {bool isFakeVault = false}) async {
    final allNotes = await getAllNotes(isFakeVault: isFakeVault);
    return allNotes.where((note) {
      final q = query.toLowerCase();
      return note.title.toLowerCase().contains(q) ||
          note.content.toLowerCase().contains(q) ||
          note.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  static Future<void> clearAllNotes() async {
    final db = await database;
    await db.delete('notes');
  }
}
