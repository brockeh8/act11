import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/card.dart';

class CardRepository {
  final dbHelper = DatabaseHelper.instance;

  // Get all cards
  Future<List<Card>> getAllCards() async {
    final db = await dbHelper.database;
    final result = await db.query(DatabaseHelper.cardTable);
    return result.map((map) => Card.fromMap(map)).toList();
  }

  // Get cards by folder ID
  Future<List<Card>> getCardsByFolder(int folderId) async {
    final db = await dbHelper.database;
    final result = await db.query(
      DatabaseHelper.cardTable,
      where: 'folderId = ?',
      whereArgs: [folderId],
    );
    return result.map((map) => Card.fromMap(map)).toList();
  }

  // Get cards not assigned to any folder (for adding new ones)
  Future<List<Card>> getUnassignedCards() async {
    final db = await dbHelper.database;
    final result = await db.query(
      DatabaseHelper.cardTable,
      where: 'folderId IS NULL',
    );
    return result.map((map) => Card.fromMap(map)).toList();
  }

  // Insert new card
  Future<int> insertCard(Card card) async {
    final db = await dbHelper.database;
    return await db.insert(DatabaseHelper.cardTable, card.toMap());
  }

  // Update existing card
  Future<int> updateCard(Card card) async {
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.cardTable,
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  // Delete card by ID
  Future<int> deleteCard(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      DatabaseHelper.cardTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Count how many cards are in a folder
  Future<int> countCardsInFolder(int folderId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.cardTable} WHERE folderId = ?',
      [folderId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
