import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_service.dart';

class BackupService {
  /// Exporte toutes les données dans un fichier JSON → dossier Downloads.
  static Future<String> exportData() async {
    final db = await DatabaseService.database;

    final categories = await db.query('categories');
    final products = await db.query('products');
    final customers = await db.query('customers');
    final sales = await db.query('sales');
    final saleItems = await db.query('sale_items');
    final settings = await db.query('settings');

    final backup = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'categories': categories,
      'products': products,
      'customers': customers,
      'sales': sales,
      'sale_items': saleItems,
      'settings': settings,
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);
    final now = DateTime.now();
    final fileName =
        'tembs_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.json';

    Directory? targetDir;
    if (Platform.isAndroid) {
      final androidDownloadDir = Directory('/storage/emulated/0/Download');
      if (await androidDownloadDir.exists()) {
        targetDir = androidDownloadDir;
      }
    }
    targetDir ??=
        await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();

    final file = File('${targetDir.path}/$fileName');
    await file.writeAsString(jsonStr, flush: true);
    return file.path;
  }

  /// Partage le fichier de sauvegarde via les applications disponibles (WhatsApp, etc.)
  static Future<void> shareBackup(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Sauvegarde Tembs — données boutique',
    );
  }

  static Map<String, dynamic> _sanitizeRow(Map<dynamic, dynamic> row) {
    final result = <String, dynamic>{};
    row.forEach((key, value) {
      if (value is Map) {
        result[key.toString()] = _sanitizeRow(value);
      } else if (value is List) {
        result[key.toString()] = value;
      } else {
        result[key.toString()] = value;
      }
    });
    return result;
  }

  /// Importe les données depuis un contenu JSON de sauvegarde.
  /// Remplace toutes les données existantes (sauf la licence).
  static Future<ImportResult> importData(String jsonContent) async {
    try {
      final Map<String, dynamic> backup = jsonDecode(jsonContent);

      final version = backup['version'];
      final versionInt = version is int ? version : int.tryParse(version.toString()) ?? 0;
      if (versionInt < 1) {
        return const ImportResult(
            success: false, message: 'Format de sauvegarde non reconnu.');
      }

      final db = await DatabaseService.database;

      await db.transaction((txn) async {
        await txn.delete('sale_items');
        await txn.delete('sales');
        await txn.delete('products');
        await txn.delete('categories');
        await txn.delete('customers');

        for (final row in (backup['categories'] as List<dynamic>? ?? [])) {
          await txn.insert('categories', _sanitizeRow(row as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (final row in (backup['products'] as List<dynamic>? ?? [])) {
          await txn.insert('products', _sanitizeRow(row as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (final row in (backup['customers'] as List<dynamic>? ?? [])) {
          await txn.insert('customers', _sanitizeRow(row as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (final row in (backup['sales'] as List<dynamic>? ?? [])) {
          await txn.insert('sales', _sanitizeRow(row as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (final row in (backup['sale_items'] as List<dynamic>? ?? [])) {
          await txn.insert('sale_items', _sanitizeRow(row as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        // Paramètres boutique seulement (pas la licence)
        for (final row in (backup['settings'] as List<dynamic>? ?? [])) {
          final map = _sanitizeRow(row as Map);
          final key = map['key'] as String? ?? '';
          if (key == 'subscription_expiry' ||
              key == 'last_opened_timestamp' ||
              key == 'onboarding_completed') {
            continue;
          }
          if (key.isEmpty) continue;
          await txn.insert('settings', map,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

      final catCount = (backup['categories'] as List? ?? []).length;
      final prodCount = (backup['products'] as List? ?? []).length;
      final custCount = (backup['customers'] as List? ?? []).length;
      final salesCount = (backup['sales'] as List? ?? []).length;

      return ImportResult(
        success: true,
        message:
            '✅ Import réussi !\n$catCount catégories · $prodCount produits · $custCount clients · $salesCount ventes restaurés.',
      );
    } catch (e) {
      return ImportResult(
          success: false, message: 'Erreur lors de l\'import : $e');
    }
  }

}

class ImportResult {
  final bool success;
  final String message;
  const ImportResult({required this.success, required this.message});
}
