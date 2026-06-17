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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE orders (
            id TEXT PRIMARY KEY,
            transaction_code TEXT NOT NULL,
            receipt_no TEXT NOT NULL DEFAULT '',
            date TEXT NOT NULL,
            status TEXT NOT NULL,
            payment_type TEXT NOT NULL DEFAULT '',
            amount REAL NOT NULL,
            currency TEXT NOT NULL,
            items_json TEXT NOT NULL,
            user TEXT NOT NULL,
            printer_index INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _safeAlter(db,
              "ALTER TABLE orders ADD COLUMN receipt_no TEXT NOT NULL DEFAULT ''");
          await _safeAlter(db,
              "ALTER TABLE orders ADD COLUMN payment_type TEXT NOT NULL DEFAULT ''");
          await _safeAlter(db,
              "ALTER TABLE orders ADD COLUMN user TEXT NOT NULL DEFAULT ''");
        }
        if (oldVersion < 3) {
          await _safeAlter(db,
              'ALTER TABLE orders ADD COLUMN printer_index INTEGER NOT NULL DEFAULT 0');
        }
      },
    );

    return _db!;
  }

  static Future<void> _safeAlter(Database db, String sql) async {
    try {
      await db.execute(sql);
    } catch (_) {
      // Colonne déjà présente ou ancienne base différente: on ignore.
    }
  }

  Future<void> upsertOrder(LocalOrder order) async {
    final db = await database;
    await db.insert(
      'orders',
      {
        'id': order.id,
        'transaction_code': order.transactionCode,
        'receipt_no': order.receiptNo,
        'date': order.date.toIso8601String(),
        'status': order.status,
        'payment_type': order.paymentType,
        'amount': order.amount,
        'currency': order.currency,
        'items_json': jsonEncode(order.items.map((e) => e.toJson()).toList()),
        'user': order.user,
        'printer_index': order.printerIndex,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> exists(String id) async {
    final db = await database;
    final rows =
        await db.query('orders', where: 'id = ?', whereArgs: [id], limit: 1);
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
        receiptNo: row['receipt_no']?.toString() ?? '',
        date: DateTime.parse(row['date'] as String),
        status: row['status'] as String,
        paymentType: row['payment_type']?.toString() ?? '',
        amount: (row['amount'] as num).toDouble(),
        currency: row['currency'] as String,
        items: rawItems
            .whereType<Map<String, dynamic>>()
            .map(SumupReceiptItem.fromJson)
            .toList(),
        user: row['user']?.toString() ?? '',
        printerIndex: row['printer_index'] as int? ?? 0);
  }
}
