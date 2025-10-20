import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/folder.dart';

class FolderRepository {
  final dbHelper = DatabaseHelper.instance;

  // Get all folders
  Future<List<Folder>> getAllFolders() async {
    final db = await dbHelper.database;
    final result = await db.query(DatabaseHelper.folderTable);
    return result.map((map) => Folder.fromMap(map)).toList();
  }

  // Get a single folder by ID
  Future<Folder?> getFolder(int id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      DatabaseHelper.folderTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Folder.fromMap(result.first);
    }
    return null;
  }

  // Insert a new folder
  Future<int> insertFolder(Folder folder) async {
    final db = await dbHelper.database;
    return await db.insert(DatabaseHelper.folderTable, folder.toMap());
  }

  // Update folder info (name or preview image)
  Future<int> updateFolder(Folder folder) async {
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.folderTable,
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  // Delete folder by ID
  Future<int> deleteFolder(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      DatabaseHelper.folderTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Count number of cards in a folder
  Future<int> countCardsInFolder(int folderId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.cardTable} WHERE folderId = ?',
      [folderId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Update folder preview image (set to first card's image)
  Future<void> updateFolderPreview(int folderId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      DatabaseHelper.cardTable,
      columns: ['imageUrl'],
      where: 'folderId = ?',
      whereArgs: [folderId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      await db.update(
        DatabaseHelper.folderTable,
        {'previewImage': result.first['imageUrl']},
        where: 'id = ?',
        whereArgs: [folderId],
      );
    }
  }
}
