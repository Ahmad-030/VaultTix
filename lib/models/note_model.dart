// lib/models/note_model.dart
import 'dart:convert';

class NoteModel {
  final String id;
  String title;
  String content;
  List<String> tags;
  bool isPinned;
  bool isSecure;
  DateTime createdAt;
  DateTime updatedAt;
  String? color;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.tags = const [],
    this.isPinned = false,
    this.isSecure = false,
    required this.createdAt,
    required this.updatedAt,
    this.color,
  });

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    bool? isPinned,
    bool? isSecure,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      isSecure: isSecure ?? this.isSecure,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'tags': jsonEncode(tags),
      'isPinned': isPinned ? 1 : 0,
      'isSecure': isSecure ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'color': color,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      tags: List<String>.from(jsonDecode(map['tags'] ?? '[]')),
      isPinned: (map['isPinned'] ?? 0) == 1,
      isSecure: (map['isSecure'] ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      color: map['color'],
    );
  }
}

// Note color options
class NoteColors {
  static const List<String> colors = [
    'default',
    'purple',
    'blue',
    'green',
    'orange',
    'pink',
    'red',
  ];

  static Map<String, List<int>> colorMap = {
    'default': [0xFF141B2D, 0xFF1A2237],
    'purple': [0xFF1A0F2E, 0xFF251540],
    'blue': [0xFF0F1E35, 0xFF152847],
    'green': [0xFF0F2620, 0xFF15332A],
    'orange': [0xFF2A1810, 0xFF37201A],
    'pink': [0xFF2A0F1E, 0xFF371528],
    'red': [0xFF2A0F0F, 0xFF371515],
  };
}
