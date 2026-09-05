import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance =
  DatabaseHelper._internal();

  static Database? _database;

  // =========================================================
  // DATABASE GETTER
  // =========================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  // =========================================================
  // INIT DATABASE
  // =========================================================

  Future<Database> _initDatabase() async {
    final appDirectory =
    await getApplicationSupportDirectory();

    final databaseDirectory = Directory(
      join(
        appDirectory.path,
        'databases',
      ),
    );

    if (!await databaseDirectory.exists()) {
      await databaseDirectory.create(
        recursive: true,
      );
    }

    final path = join(
      databaseDirectory.path,
      'lucknowi_fashion.db',
    );

    print(
      'PERMANENT DATABASE PATH: $path',
    );

    return await openDatabase(
      path,
      version: 9,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // =========================================================
  // CONFIGURE
  // =========================================================

  Future<void> _onConfigure(
      Database db,
      ) async {
    await db.execute(
      'PRAGMA foreign_keys = ON',
    );
  }

  // =========================================================
  // CREATE DATABASE
  // =========================================================

  Future<void> _onCreate(
      Database db,
      int version,
      ) async {
    await _createCategoriesTable(db);
    await _createBrandsTable(db);
    await _createColorsTable(db);
    await _createSizesTable(db);
    await _createSuppliersTable(db);
    await _createCustomersTable(db);
    await _createStaffTable(db);

    await _createProductsTable(db);
    await _createProductVariantsTable(db);

    await _createSalesTable(db);
    await _createSaleItemsTable(db);

    // SALES RETURN
    await _createSalesReturnsTable(db);
    await _createSalesReturnItemsTable(db);

    await _createPurchasesTable(db);
    await _createPurchaseItemsTable(db);
  }

  // =========================================================
  // DATABASE UPGRADE
  // =========================================================

  Future<void> _onUpgrade(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {

    // =======================================================
    // VERSION 5
    // SALES
    // =======================================================

    if (oldVersion < 5) {
      await _createSalesTable(db);
      await _createSaleItemsTable(db);
    }

    // =======================================================
    // VERSION 6
    // PURCHASE
    // =======================================================

    if (oldVersion < 6) {
      await _createPurchasesTable(db);
      await _createPurchaseItemsTable(db);
    }

    // =======================================================
    // VERSION 7
    // STAFF-WISE SALES
    // =======================================================

    if (oldVersion < 7) {
      final columns = await db.rawQuery(
        'PRAGMA table_info(sales)',
      );

      final hasStaffId = columns.any(
            (column) =>
        column['name']?.toString() == 'staffId',
      );

      if (!hasStaffId) {
        await db.execute('''
          ALTER TABLE sales
          ADD COLUMN staffId INTEGER
        ''');
      }
    }

    // =======================================================
    // VERSION 8
    // ENSURE STAFF ID EXISTS
    // =======================================================

    if (oldVersion < 8) {
      final columns = await db.rawQuery(
        'PRAGMA table_info(sales)',
      );

      final hasStaffId = columns.any(
            (column) =>
        column['name']?.toString() == 'staffId',
      );

      if (!hasStaffId) {
        await db.execute('''
          ALTER TABLE sales
          ADD COLUMN staffId INTEGER
        ''');
      }
    }

    // =======================================================
    // VERSION 9
    // SALES RETURN
    // =======================================================

    if (oldVersion < 9) {
      await _createSalesReturnsTable(db);
      await _createSalesReturnItemsTable(db);
    }
  }

  // =========================================================
  // CATEGORY
  // =========================================================

  Future<void> _createCategoriesTable(
      Database db,
      ) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        image TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // =========================================================
  // BRAND
  // =========================================================

  Future<void> _createBrandsTable(
      Database db,
      ) async {
    await db.execute('''
      CREATE TABLE brands(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // =========================================================
  // COLOR
  // =========================================================

  Future<void> _createColorsTable(
      Database db,
      ) async {
    await db.execute('''
      CREATE TABLE colors(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        code TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // =========================================================
  // SIZE
  // =========================================================

  Future<void> _createSizesTable(
      Database db,
      ) async {
    await db.execute('''
      CREATE TABLE sizes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // =========================================================
  // SUPPLIER
  // =========================================================

  Future<void> _createSuppliersTable(
      Database db,
      ) async {
    await db.execute('''
      CREATE TABLE suppliers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // =========================================================
  // CUSTOMER
  // =========================================================

  Future<void> _createCustomersTable(
      Database db,
      ) async {
    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // =========================================================
  // STAFF
  // =========================================================

  Future<void> _createStaffTable(
      Database db,
      ) async {
    await db.execute('''
      CREATE TABLE staff(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'Staff',
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // =========================================================
  // PRODUCTS
  // =========================================================

  Future<void> _createProductsTable(
      Database db,
      ) async {
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

        FOREIGN KEY(categoryId)
          REFERENCES categories(id),

        FOREIGN KEY(brandId)
          REFERENCES brands(id)
      )
    ''');
  }

  // =========================================================
  // PRODUCT VARIANTS
  // =========================================================

  Future<void> _createProductVariantsTable(
      Database db,
      ) async {
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

        FOREIGN KEY(productId)
          REFERENCES products(id)
          ON DELETE CASCADE
      )
    ''');
  }

  // =========================================================
  // SALES
  // =========================================================

  Future<void> _createSalesTable(
      Database db,
      ) async {
    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        billNumber TEXT NOT NULL UNIQUE,

        customerId INTEGER,

        staffId INTEGER,

        subtotal REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        gst REAL NOT NULL DEFAULT 0,
        grandTotal REAL NOT NULL DEFAULT 0,

        paymentMethod TEXT NOT NULL,
        paymentStatus TEXT NOT NULL DEFAULT 'Paid',

        createdAt TEXT NOT NULL,

        FOREIGN KEY(customerId)
          REFERENCES customers(id)
          ON DELETE SET NULL,

        FOREIGN KEY(staffId)
          REFERENCES staff(id)
          ON DELETE SET NULL
      )
    ''');
  }

  // =========================================================
  // SALE ITEMS
  // =========================================================

  Future<void> _createSaleItemsTable(
      Database db,
      ) async {
    await db.execute('''
      CREATE TABLE sale_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        variantId INTEGER NOT NULL,

        productName TEXT NOT NULL,
        color TEXT,
        size TEXT,
        sku TEXT,
        barcode TEXT,

        quantity INTEGER NOT NULL,

        purchasePrice REAL NOT NULL DEFAULT 0,
        sellingPrice REAL NOT NULL DEFAULT 0,

        gst REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,

        FOREIGN KEY(saleId)
          REFERENCES sales(id)
          ON DELETE CASCADE,

        FOREIGN KEY(variantId)
          REFERENCES product_variants(id)
      )
    ''');
  }

  // =========================================================
  // SALES RETURNS
  // =========================================================

  Future<void> _createSalesReturnsTable(
      Database db,
      ) async {
    await db.execute('''
      CREATE TABLE sales_returns(
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        returnNumber TEXT NOT NULL UNIQUE,

        saleId INTEGER NOT NULL,

        customerId INTEGER,

        staffId INTEGER,

        totalAmount REAL NOT NULL DEFAULT 0,

        refundMethod TEXT NOT NULL DEFAULT 'Cash',

        reason TEXT,

        createdAt TEXT NOT NULL,

        FOREIGN KEY(saleId)
          REFERENCES sales(id)
          ON DELETE CASCADE,

        FOREIGN KEY(customerId)
          REFERENCES customers(id)
          ON DELETE SET NULL,

        FOREIGN KEY(staffId)
          REFERENCES staff(id)
          ON DELETE SET NULL
      )
    ''');
  }

  // =========================================================
  // SALES RETURN ITEMS
  // =========================================================

  Future<void> _createSalesReturnItemsTable(
      Database db,
      ) async {
    await db.execute('''
      CREATE TABLE sales_return_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        returnId INTEGER NOT NULL,

        saleItemId INTEGER NOT NULL,

        variantId INTEGER NOT NULL,

        productName TEXT NOT NULL,

        color TEXT,
        size TEXT,
        sku TEXT,
        barcode TEXT,

        quantity INTEGER NOT NULL,

        sellingPrice REAL NOT NULL DEFAULT 0,

        gst REAL NOT NULL DEFAULT 0,

        discount REAL NOT NULL DEFAULT 0,

        total REAL NOT NULL DEFAULT 0,

        FOREIGN KEY(returnId)
          REFERENCES sales_returns(id)
          ON DELETE CASCADE,

        FOREIGN KEY(saleItemId)
          REFERENCES sale_items(id),

        FOREIGN KEY(variantId)
          REFERENCES product_variants(id)
      )
    ''');
  }

  // =========================================================
  // PURCHASE
  // =========================================================

  Future<void> _createPurchasesTable(
      Database db,
      ) async {
    await db.execute('''
      CREATE TABLE purchases(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceNumber TEXT NOT NULL UNIQUE,

        supplierId INTEGER,

        subtotal REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        gst REAL NOT NULL DEFAULT 0,
        grandTotal REAL NOT NULL DEFAULT 0,

        paymentMethod TEXT NOT NULL DEFAULT 'Cash',
        paymentStatus TEXT NOT NULL DEFAULT 'Paid',

        createdAt TEXT NOT NULL,

        FOREIGN KEY(supplierId)
          REFERENCES suppliers(id)
          ON DELETE SET NULL
      )
    ''');
  }

  // =========================================================
  // PURCHASE ITEMS
  // =========================================================

  Future<void> _createPurchaseItemsTable(
      Database db,
      ) async {
    await db.execute('''
      CREATE TABLE purchase_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchaseId INTEGER NOT NULL,
        variantId INTEGER NOT NULL,

        productName TEXT NOT NULL,
        color TEXT,
        size TEXT,
        sku TEXT,
        barcode TEXT,

        quantity INTEGER NOT NULL,

        purchasePrice REAL NOT NULL DEFAULT 0,

        gst REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,

        FOREIGN KEY(purchaseId)
          REFERENCES purchases(id)
          ON DELETE CASCADE,

        FOREIGN KEY(variantId)
          REFERENCES product_variants(id)
      )
    ''');
  }
}