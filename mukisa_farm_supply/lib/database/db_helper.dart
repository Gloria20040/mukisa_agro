import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mukisa.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 3, // bumped for added_date in products
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
        onOpen: (db) async {
          // Ensure users table exists and seed defaults if empty
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT UNIQUE,
              password_hash TEXT,
              role TEXT
            )
          ''');

          final countRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM users');
          final cnt = countRes.isNotEmpty ? (countRes.first['cnt'] as int) : 0;
          if (cnt == 0) {
            // seed default users: admin/admin123 and sales/sales123 (hashed)
            String hash(String s) => sha256.convert(utf8.encode(s)).toString();
            await db.insert('users', {
              'username': 'admin',
              'password_hash': hash('admin123'),
              'role': 'admin'
            });
            await db.insert('users', {
              'username': 'sales',
              'password_hash': hash('sales123'),
              'role': 'sales'
            });
          }
          // Ensure sales table exists for older DBs that may not have been upgraded
          await db.execute('''
            CREATE TABLE IF NOT EXISTS sales (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              product_id INTEGER,
              quantity_pieces INTEGER,
              sell_price REAL,
              total_amount REAL,
              role TEXT,
              date TEXT,
              archived INTEGER DEFAULT 0
            )
          ''');
          // Ensure products table has added_date column on older DBs
          final columns = await db.rawQuery("PRAGMA table_info(products);");
          final hasAddedDate = columns.any((c) => c['name'] == 'added_date');
          if (!hasAddedDate) {
            try {
              await db.execute('ALTER TABLE products ADD COLUMN added_date TEXT');
            } catch (_) {}
          }
          // Ensure sales table has archived column
          final salesColumns = await db.rawQuery("PRAGMA table_info(sales);");
          final hasArchived = salesColumns.any((c) => c['name'] == 'archived');
          if (!hasArchived) {
            try {
              await db.execute('ALTER TABLE sales ADD COLUMN archived INTEGER DEFAULT 0');
            } catch (_) {}
          }
        },
      );
  }

  // Called only when database is first created
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category TEXT,
        cost_price REAL,
        sell_price REAL,
        quantity INTEGER,
        unit TEXT,
        reorder_level INTEGER,
        added_date TEXT
      )
    ''');
  }

  // Called automatically if version is increased
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE sales (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER,
          quantity_pieces INTEGER,
          sell_price REAL,
          total_amount REAL,
          role TEXT,
          date TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      // add added_date column to products
      try {
        await db.execute('ALTER TABLE products ADD COLUMN added_date TEXT');
      } catch (_) {}
    }
  }
}
