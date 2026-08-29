import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'tembs.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            category_id TEXT,
            name TEXT NOT NULL,
            description TEXT,
            price REAL NOT NULL,
            quantity INTEGER NOT NULL DEFAULT 1,
            image_url TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE customers (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            phone TEXT,
            address TEXT,
            notes TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE sales (
            id TEXT PRIMARY KEY,
            customer_id TEXT,
            customer_name TEXT,
            customer_phone TEXT,
            total REAL NOT NULL,
            payment_method TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sale_items (
            id TEXT PRIMARY KEY,
            sale_id TEXT NOT NULL,
            product_id TEXT NOT NULL,
            product_name TEXT NOT NULL,
            price REAL NOT NULL,
            quantity INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ─── SETTINGS / PROFILE ────────────────────────────────────────────────────

  static Future<void> _ensureSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  static Future<String> getSetting(String key, {String defaultValue = ''}) async {
    final db = await database;
    await _ensureSettingsTable(db);
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isNotEmpty) {
      return rows.first['value'] as String;
    }
    return defaultValue;
  }

  static Future<void> setSetting(String key, String value) async {
    final db = await database;
    await _ensureSettingsTable(db);
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, String>> getShopProfile() async {
    final name = await getSetting('shop_name', defaultValue: 'Tembs');
    final phone = await getSetting('shop_phone', defaultValue: '');
    return {'name': name, 'phone': phone};
  }

  static Future<void> saveShopProfile({required String name, required String phone}) async {
    await setSetting('shop_name', name.trim().isEmpty ? 'Tembs' : name.trim());
    await setSetting('shop_phone', phone.trim());
  }


  // ─── CATEGORIES ───────────────────────────────────────────────────────────

  static Future<List<Category>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map((r) => Category.fromJson(r)).toList();
  }

  static Future<Category> insertCategory(String name) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final cat = {'id': id, 'name': name};
    await db.insert('categories', cat);
    return Category.fromJson(cat);
  }

  static Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ─── PRODUCTS ─────────────────────────────────────────────────────────────

  static Future<List<Product>> getProducts() async {
    final db = await database;
    final rows = await db.query('products', orderBy: 'created_at DESC');
    return rows.map((r) => Product.fromJson(r)).toList();
  }

  static Future<Product> insertProduct(Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final row = {
      'id': id,
      'category_id': data['category_id'],
      'name': data['name'],
      'description': data['description'],
      'price': data['price'],
      'quantity': data['quantity'],
      'image_url': data['image_url'],
      'created_at': now,
    };
    await db.insert('products', row);
    return Product.fromJson(row);
  }

  static Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('products', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateProductQuantity(String id, int newQty) async {
    final db = await database;
    await db.update('products', {'quantity': newQty}, where: 'id = ?', whereArgs: [id]);
  }

  // ─── CUSTOMERS ────────────────────────────────────────────────────────────

  static Future<List<Customer>> getCustomers() async {
    final db = await database;
    final rows = await db.query('customers', orderBy: 'name ASC');
    return rows.map((r) => Customer.fromJson(r)).toList();
  }

  static Future<Customer> insertCustomer(Map<String, dynamic> data) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final row = {
      'id': id,
      'name': data['name'],
      'phone': data['phone'],
      'address': data['address'],
      'notes': data['notes'],
    };
    await db.insert('customers', row);
    return Customer.fromJson(row);
  }

  static Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('customers', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteCustomer(String id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // ─── SALES ────────────────────────────────────────────────────────────────

  static Future<List<Sale>> getSales() async {
    final db = await database;
    final rows = await db.query('sales', orderBy: 'created_at DESC');
    return rows.map((r) => Sale.fromJson(r)).toList();
  }

  static Future<Sale> insertSale({
    required String? customerId,
    required String? customerName,
    required String? customerPhone,
    required double total,
    required String paymentMethod,
    required List<CartLine> cartLines,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final saleId = DateTime.now().millisecondsSinceEpoch.toString();
    final saleRow = {
      'id': saleId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total': total,
      'payment_method': paymentMethod,
      'created_at': now,
    };
    await db.insert('sales', saleRow);

    for (final line in cartLines) {
      final itemId = '${saleId}_${line.product.id}';
      await db.insert('sale_items', {
        'id': itemId,
        'sale_id': saleId,
        'product_id': line.product.id,
        'product_name': line.product.name,
        'price': line.product.price,
        'quantity': line.quantity,
      });
      // Decrease stock
      final newQty = line.product.quantity - line.quantity;
      await updateProductQuantity(line.product.id, newQty < 0 ? 0 : newQty);
    }
    return Sale.fromJson(saleRow);
  }

  static Future<void> deleteSale(String id) async {
    final db = await database;
    await db.delete('sale_items', where: 'sale_id = ?', whereArgs: [id]);
    await db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }

  // ─── STATS ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

    final todayRows = await db.rawQuery(
        'SELECT SUM(total) as t FROM sales WHERE created_at >= ?', [startOfDay]);
    final monthRows = await db.rawQuery(
        'SELECT SUM(total) as t FROM sales WHERE created_at >= ?', [startOfMonth]);
    final productCountRow = await db.rawQuery('SELECT COUNT(*) as c FROM products');
    final lowStockRow = await db.rawQuery(
        'SELECT COUNT(*) as c FROM products WHERE quantity <= 3');
    final customerCountRow = await db.rawQuery('SELECT COUNT(*) as c FROM customers');
    final salesCountRow = await db.rawQuery('SELECT COUNT(*) as c FROM sales');

    return {
      'todayTotal': (todayRows.first['t'] as num?)?.toDouble() ?? 0.0,
      'monthTotal': (monthRows.first['t'] as num?)?.toDouble() ?? 0.0,
      'productCount': (productCountRow.first['c'] as int?) ?? 0,
      'lowStockCount': (lowStockRow.first['c'] as int?) ?? 0,
      'customerCount': (customerCountRow.first['c'] as int?) ?? 0,
      'salesCount': (salesCountRow.first['c'] as int?) ?? 0,
    };
  }
}
