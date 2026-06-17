import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/local_order.dart';
import '../models/sumup_receipt_item.dart';

class LocalOrderDatabase {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sumup_ticket_splitter.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE orders (
            id TEXT PRIMARY KEY,
            transaction_code TEXT NOT NULL,
            date TEXT NOT NULL,
            status TEXT NOT NULL,
            amount REAL NOT NULL,
            currency TEXT NOT NULL,
            product_summary TEXT NOT NULL,
            items_json TEXT NOT NULL
          )
        ''');
      },
    );

    return _db!;
  }

  Future<void> upsertOrder(LocalOrder order) async {
    final db = await database;
    await db.insert(
      'orders',
      {
        'id': order.id,
        'transaction_code': order.transactionCode,
        'date': order.date.toIso8601String(),
        'status': order.status,
        'amount': order.amount,
        'currency': order.currency,
        'product_summary': order.productSummary,
        'items_json': jsonEncode(order.items.map((e) => e.toJson()).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> exists(String id) async {
    final db = await database;
    final rows = await db.query('orders', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isNotEmpty;
  }

  Future<List<LocalOrder>> getOrders() async {
    final db = await database;
    final rows = await db.query('orders', orderBy: 'date DESC');
    return rows.map(_fromRow).toList();
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete('orders');
  }

  LocalOrder _fromRow(Map<String, Object?> row) {
    final rawItems = jsonDecode(row['items_json'] as String) as List<dynamic>;
    return LocalOrder(
      id: row['id'] as String,
      transactionCode: row['transaction_code'] as String,
      date: DateTime.parse(row['date'] as String),
      status: row['status'] as String,
      amount: (row['amount'] as num).toDouble(),
      currency: row['currency'] as String,
      productSummary: row['product_summary'] as String,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(SumupReceiptItem.fromJson)
          .toList(),
    );
  }
}
