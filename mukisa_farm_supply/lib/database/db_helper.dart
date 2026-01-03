import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
  version: 2, // ⬅️ increment version
  onCreate: _createDB,
  onUpgrade: _upgradeDB,
);

  }

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
        reorder_level INTEGER
      )
    ''');
  }
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
}
}
