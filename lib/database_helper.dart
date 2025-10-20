import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // Singleton setup
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  static const String _dbName = 'card_organizer.db';
  static const int _dbVersion = 1;

  // Table names
  static const String folderTable = 'folders';
  static const String cardTable = 'cards';

  // ------------------------------
  // Database Initialization
  // ------------------------------
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  // ------------------------------
  // Table Creation and Prepopulation
  // ------------------------------
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $folderTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        previewImage TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $cardTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        imageUrl TEXT,
        imageBytes TEXT,
        folderId INTEGER,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (folderId) REFERENCES $folderTable (id) ON DELETE CASCADE
      )
    ''');

    // Prepopulate the folders (suits)
    await _insertInitialFolders(db);

    // Prepopulate sample cards (demo version)
    await _insertInitialCards(db);
  }

  // ------------------------------
  // Prepopulate Folders
  // ------------------------------
  Future<void> _insertInitialFolders(Database db) async {
    final suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    final now = DateTime.now().toIso8601String();

    for (var suit in suits) {
      await db.insert(folderTable, {
        'name': suit,
        'previewImage': null,
        'createdAt': now,
      });
    }
  }

  // ------------------------------
  // Prepopulate Cards (Simplified)
  // ------------------------------
  Future<void> _insertInitialCards(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Using a few example URLs (replace with your own)
    const cardImages = [
      'https://upload.wikimedia.org/wikipedia/commons/5/57/Playing_card_heart_A.svg',
      'https://upload.wikimedia.org/wikipedia/commons/d/d3/Playing_card_spade_A.svg',
      'https://upload.wikimedia.org/wikipedia/commons/2/20/Playing_card_diamond_A.svg',
      'https://upload.wikimedia.org/wikipedia/commons/2/25/Playing_card_club_A.svg',
      'https://upload.wikimedia.org/wikipedia/commons/5/5d/Playing_card_heart_K.svg',
      'https://upload.wikimedia.org/wikipedia/commons/2/21/Playing_card_spade_K.svg',
      'https://upload.wikimedia.org/wikipedia/commons/7/78/Playing_card_diamond_K.svg',
      'https://upload.wikimedia.org/wikipedia/commons/3/3b/Playing_card_club_K.svg',
      'https://upload.wikimedia.org/wikipedia/commons/6/6b/Playing_card_heart_Q.svg',
      'https://upload.wikimedia.org/wikipedia/commons/5/51/Playing_card_spade_Q.svg',
      'https://upload.wikimedia.org/wikipedia/commons/3/34/Playing_card_diamond_Q.svg',
      'https://upload.wikimedia.org/wikipedia/commons/4/4b/Playing_card_club_Q.svg',
    ];

    // Folder IDs correspond to suit insertion order (1=Hearts, 2=Spades, 3=Diamonds, 4=Clubs)
    final suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];

    for (int i = 0; i < suits.length; i++) {
      final suit = suits[i];
      final folderId = i + 1;

      // Add three cards per suit (Ace, King, Queen)
      final subset = cardImages.skip(i * 3).take(3).toList();

      for (int j = 0; j < subset.length; j++) {
        final name = ['Ace', 'King', 'Queen'][j];
        await db.insert(cardTable, {
          'name': '$name of $suit',
          'suit': suit,
          'imageUrl': subset[j],
          'imageBytes': null,
          'folderId': folderId,
          'createdAt': now,
        });
      }
    }
  }

  // ------------------------------
  // Helper Functions
  // ------------------------------
  Future<void> clearDatabase() async {
    final db = await instance.database;
    await db.delete(cardTable);
    await db.delete(folderTable);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
