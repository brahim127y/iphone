import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    String dbDir;
    try {
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        final docDir = await getApplicationSupportDirectory();
        dbDir = docDir.path;
      } else {
        dbDir = await getDatabasesPath();
      }
    } catch (_) {
      try {
        final docDir = await getApplicationDocumentsDirectory();
        dbDir = docDir.path;
      } catch (_) {
        dbDir = '.';
      }
    }

    final dbPath = join(dbDir, 'tembs.db');
    try {
      await Directory(dbDir).create(recursive: true);
    } catch (_) {}

    return await openDatabase(
      dbPath,
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
    final name = await getSetting('shop_name', defaultValue: '');
    final phone = await getSetting('shop_phone', defaultValue: '');
    final address = await getSetting('shop_address', defaultValue: '');
    return {'name': name, 'phone': phone, 'address': address};
  }

  static Future<void> saveShopProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    await setSetting('shop_name', name.trim());
    await setSetting('shop_phone', phone.trim());
    await setSetting('shop_address', address.trim());
  }

  static Future<bool> isOnboardingCompleted() async {
    final value = await getSetting('onboarding_completed', defaultValue: 'false');
    return value == 'true';
  }

  static Future<void> setOnboardingCompleted(bool completed) async {
    await setSetting('onboarding_completed', completed ? 'true' : 'false');
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

  static Future<List<SaleItem>> getSaleItems(String saleId) async {
    final db = await database;
    final rows = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return rows.map(SaleItem.fromJson).toList();
  }

  static Future<List<Sale>> getRecentSales({int limit = 5}) async {
    final db = await database;
    final rows = await db.query(
      'sales',
      orderBy: 'created_at DESC',
      limit: limit,
    );
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
    return db.transaction((txn) async {
      for (final line in cartLines) {
        if (line.quantity <= 0) {
          throw Exception('La quantité pour ${line.product.name} doit être supérieure à 0.');
        }
        final rows = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [line.product.id],
        );
        if (rows.isEmpty) {
          throw Exception('Produit introuvable : ${line.product.name}');
        }
        final stock = (rows.first['quantity'] as num).toInt();
        if (stock <= 0) {
          throw Exception('Vente refusée : ${line.product.name} est en rupture de stock (0 disponible).');
        }
        if (line.quantity > stock) {
          throw Exception(
            'Vente refusée : Stock insuffisant pour ${line.product.name} (demandé : ${line.quantity}, disponible : $stock).',
          );
        }
      }

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
      await txn.insert('sales', saleRow);

      for (final line in cartLines) {
        final itemId = '${saleId}_${line.product.id}';
        await txn.insert('sale_items', {
          'id': itemId,
          'sale_id': saleId,
          'product_id': line.product.id,
          'product_name': line.product.name,
          'price': line.product.price,
          'quantity': line.quantity,
        });
        final rows = await txn.query(
          'products',
          columns: ['quantity'],
          where: 'id = ?',
          whereArgs: [line.product.id],
        );
        final stock = (rows.first['quantity'] as num).toInt();
        final remaining = (stock - line.quantity).clamp(0, 999999);
        await txn.update(
          'products',
          {'quantity': remaining},
          where: 'id = ?',
          whereArgs: [line.product.id],
        );
      }
      return Sale.fromJson(saleRow);
    });
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

    final startOfYesterday =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final startOfYesterdayIso = startOfYesterday.toIso8601String();

    final startOfWeekDate = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek =
        DateTime(startOfWeekDate.year, startOfWeekDate.month, startOfWeekDate.day)
            .toIso8601String();

    final todayRows = await db.rawQuery(
        'SELECT SUM(total) as t, COUNT(*) as c FROM sales WHERE created_at >= ?', [startOfDay]);
    final yesterdayRows = await db.rawQuery(
        'SELECT SUM(total) as t FROM sales WHERE created_at >= ? AND created_at < ?',
        [startOfYesterdayIso, startOfDay]);
    final weekRows = await db.rawQuery(
        'SELECT SUM(total) as t, COUNT(*) as c FROM sales WHERE created_at >= ?', [startOfWeek]);
    final monthRows = await db.rawQuery(
        'SELECT SUM(total) as t, COUNT(*) as c FROM sales WHERE created_at >= ?', [startOfMonth]);
    final productCountRow = await db.rawQuery('SELECT COUNT(*) as c FROM products');
    final lowStockRow = await db.rawQuery(
        'SELECT COUNT(*) as c FROM products WHERE quantity > 0 AND quantity <= 3');
    final outOfStockRow = await db.rawQuery(
        'SELECT COUNT(*) as c FROM products WHERE quantity <= 0');
    final customerCountRow = await db.rawQuery('SELECT COUNT(*) as c FROM customers');

    return {
      'todayTotal': (todayRows.first['t'] as num?)?.toDouble() ?? 0.0,
      'todayCount': (todayRows.first['c'] as int?) ?? 0,
      'yesterdayTotal': (yesterdayRows.first['t'] as num?)?.toDouble() ?? 0.0,
      'weekTotal': (weekRows.first['t'] as num?)?.toDouble() ?? 0.0,
      'weekCount': (weekRows.first['c'] as int?) ?? 0,
      'monthTotal': (monthRows.first['t'] as num?)?.toDouble() ?? 0.0,
      'monthSalesCount': (monthRows.first['c'] as int?) ?? 0,
      'productCount': (productCountRow.first['c'] as int?) ?? 0,
      'lowStockCount': (lowStockRow.first['c'] as int?) ?? 0,
      'outOfStockCount': (outOfStockRow.first['c'] as int?) ?? 0,
      'customerCount': (customerCountRow.first['c'] as int?) ?? 0,
      'salesCount': (monthRows.first['c'] as int?) ?? 0,
    };
  }

  static Future<List<Map<String, dynamic>>> getTopProducts({int limit = 3}) async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    return db.rawQuery('''
      SELECT si.product_name as name,
             SUM(si.quantity) as qty,
             SUM(si.price * si.quantity) as revenue
      FROM sale_items si
      INNER JOIN sales s ON s.id = si.sale_id
      WHERE s.created_at >= ?
      GROUP BY si.product_name
      ORDER BY qty DESC
      LIMIT ?
    ''', [startOfMonth, limit]);
  }

  // ─── ABONNEMENT & LICENCE ──────────────────────────────────────────────────

  static Future<int?> activateLicenseCode(String code) async {
    final cleanCode = code.trim();
    int days = 0;
    if (cleanCode == '453216') {
      days = 1;
    } else if (cleanCode == '562365') {
      days = 30;
    } else if (cleanCode == '214563') {
      days = 90;
    } else {
      return null;
    }

    final now = DateTime.now();

    final currentExpiryStr = await getSetting('subscription_expiry');
    DateTime baseDate = now;
    if (currentExpiryStr.isNotEmpty) {
      final parsed = DateTime.tryParse(currentExpiryStr);
      if (parsed != null && parsed.isAfter(now)) {
        baseDate = parsed;
      }
    }

    final newExpiry = baseDate.add(Duration(days: days));
    await setSetting('subscription_expiry', newExpiry.toIso8601String());
    await setSetting('last_opened_timestamp', now.toIso8601String());
    return days;
  }

  static Future<SubscriptionInfo> getSubscriptionStatus() async {
    final now = DateTime.now();

    final expiryStr = await getSetting('subscription_expiry');
    final lastOpenedStr = await getSetting('last_opened_timestamp');

    final DateTime? expiry = expiryStr.isNotEmpty ? DateTime.tryParse(expiryStr) : null;
    final DateTime? lastOpened = lastOpenedStr.isNotEmpty ? DateTime.tryParse(lastOpenedStr) : null;

    bool isTampered = false;
    if (lastOpened != null && now.isBefore(lastOpened.subtract(const Duration(minutes: 5)))) {
      isTampered = true;
    } else {
      await setSetting('last_opened_timestamp', now.toIso8601String());
    }

    bool isExpired = false;
    int remainingHours = 0;
    int remainingDays = 0;

    if (expiry == null) {
      isExpired = true;
    } else if (now.isAfter(expiry)) {
      isExpired = true;
    } else {
      final diff = expiry.difference(now);
      remainingHours = diff.inHours;
      remainingDays = diff.inDays;
    }

    return SubscriptionInfo(
      expiryDate: expiry,
      remainingDays: remainingDays,
      remainingHours: remainingHours,
      isExpired: isExpired,
      isDateTampered: isTampered,
    );
  }
}

class SubscriptionInfo {
  final DateTime? expiryDate;
  final int remainingDays;
  final int remainingHours;
  final bool isExpired;
  final bool isDateTampered;

  SubscriptionInfo({
    required this.expiryDate,
    required this.remainingDays,
    required this.remainingHours,
    required this.isExpired,
    required this.isDateTampered,
  });
}
