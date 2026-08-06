import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'lucknowi_fashion.db');

    return await openDatabase(
      path,
      version: 2,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createCategoriesTable(db);
    await _createBrandsTable(db);
    await _createProductsTable(db);
    await _createProductVariantsTable(db);
  }

  Future<void> _onUpgrade(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    // Future database migrations yahan likhenge.
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        image TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createBrandsTable(Database db) async {
    await db.execute('''
      CREATE TABLE brands(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createProductsTable(Database db) async {
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        categoryId INTEGER NOT NULL,
        brandId INTEGER,
        department TEXT,
        hsn TEXT,
        gst REAL DEFAULT 0,
        description TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY(categoryId) REFERENCES categories(id),
        FOREIGN KEY(brandId) REFERENCES brands(id)
      )
    ''');
  }

  Future<void> _createProductVariantsTable(Database db) async {
    await db.execute('''
      CREATE TABLE product_variants(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        sku TEXT NOT NULL UNIQUE,
        barcode TEXT NOT NULL UNIQUE,
        color TEXT NOT NULL,
        size TEXT NOT NULL,
        purchasePrice REAL NOT NULL,
        sellingPrice REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        image TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(productId) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');
  }
}