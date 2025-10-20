import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DB {
  DB._();
  static final DB instance = DB._();

  static const _dbName = 'cards_v4.db'; // bump if you need a fresh seed
  static const _dbVersion = 1;
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // folders
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        previewImage TEXT,
        createdAt TEXT NOT NULL
      );
    ''');

    // cards
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        imageBytes TEXT,
        folderId INTEGER,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(folderId) REFERENCES folders(id) ON DELETE SET NULL
      );
    ''');

    final now = DateTime.now().toIso8601String();
    final suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    for (final s in suits) {
      await db.insert('folders', {
        'name': s,
        'createdAt': now,
        'previewImage': null,
      });
    }

    String codeFor(String rank, String suitLetter) => '${rank == '10' ? '0' : rank}$suitLetter';
    String imgUrl(String code) => 'https://deckofcardsapi.com/static/img/$code.png';

    final suitLetter = {
      'Hearts': 'H',
      'Spades': 'S',
      'Diamonds': 'D',
      'Clubs': 'C',
    };

    final rankNames = <String, String>{
      'A': 'Ace', '2': 'Two', '3': 'Three', '4': 'Four', '5': 'Five',
      '6': 'Six', '7': 'Seven', '8': 'Eight', '9': 'Nine', '10': 'Ten',
      'J': 'Jack', 'Q': 'Queen', 'K': 'King',
    };
    const ranks = ['A','2','3','4','5','6','7','8','9','10','J','Q','K'];

    for (final suit in suits) {
      for (final r in ranks) {
        final code = codeFor(r, suitLetter[suit]!);
        await db.insert('cards', {
          'name': '${rankNames[r]} of $suit',
          'suit': suit,
          'imageUrl': imgUrl(code),
          'imageBytes': null,
          'folderId': null, 
          'createdAt': now,
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> allFolders() async {
    final db = await database;
    return db.query(
      'folders',
      orderBy: """
        CASE name
          WHEN 'Hearts' THEN 1
          WHEN 'Spades' THEN 2
          WHEN 'Diamonds' THEN 3
          WHEN 'Clubs' THEN 4
          ELSE 5
        END
      """,
    );
  }

  Future<List<Map<String, dynamic>>> cardsInFolder(int folderId) async {
    final db = await database;
    return db.query('cards',
        where: 'folderId = ?', whereArgs: [folderId], orderBy: 'createdAt DESC');
  }

  Future<List<Map<String, dynamic>>> unassignedCards() async {
    final db = await database;
    return db.query('cards',
        where: 'folderId IS NULL', orderBy: 'createdAt DESC');
  }

  Future<int> countInFolder(int folderId) async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) FROM cards WHERE folderId = ?',
      [folderId],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

// made it 13 for testing
  Future<void> assignOneToFolder(int folderId) async {
    final db = await database;
    final n = await countInFolder(folderId);
    if (n >= 13) throw StateError('Folder already has 13 cards.');
    final free = await unassignedCards();
    if (free.isEmpty) return;
    final id = free.first['id'] as int;
    await db.update('cards', {'folderId': folderId},
        where: 'id = ?', whereArgs: [id]);
    await _updatePreviewFromFirstCard(folderId);
  }

  Future<void> removeOneFromFolder(int folderId) async {
    final db = await database;
    final rows = await cardsInFolder(folderId);
    if (rows.isEmpty) return;
    final id = rows.first['id'] as int;
    await db.update('cards', {'folderId': null},
        where: 'id = ?', whereArgs: [id]);
    await _updatePreviewFromFirstCard(folderId);
  }

  Future<void> _updatePreviewFromFirstCard(int folderId) async {
    final db = await database;
    final first = await db.query('cards',
        where: 'folderId = ?', whereArgs: [folderId], limit: 1);
    final url = first.isNotEmpty ? first.first['imageUrl'] as String? : null;
    await db.update('folders', {'previewImage': url},
        where: 'id = ?', whereArgs: [folderId]);
  }
}
