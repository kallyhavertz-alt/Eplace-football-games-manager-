import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalChatDb {
  static final LocalChatDb instance = LocalChatDb._init();
  static Database? _database;

  LocalChatDb._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('eplace_chat.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL,
            sender_id INTEGER NOT NULL,
            content TEXT NOT NULL,
            type TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> saveMessage(Map<String, dynamic> msg) async {
    final db = await database;
    await db.insert(
      'messages',
      {
        'id': msg['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'conversation_id': msg['conversationId']?.toString() ?? msg['conversation_id']?.toString() ?? '',
        'sender_id': msg['senderId'] ?? msg['sender_id'] ?? 0,
        'content': msg['content']?.toString() ?? '',
        'type': msg['type']?.toString() ?? 'TEXT',
        'status': msg['status']?.toString() ?? 'SENT',
        'created_at': msg['createdAt']?.toString() ?? msg['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCachedMessages(String conversationId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at DESC',
    );
  }
}
