import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  sqfliteFfiInit();

  const dbPath =
      '.dart_tool/sqflite_common_ffi/databases/lucknowi_fashion.db';

  final db = await databaseFactoryFfi.openDatabase(dbPath);

  print('');
  print('================ DATABASE CHECK ================');
  print('');

  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master "
        "WHERE type='table' AND name NOT LIKE 'sqlite_%' "
        "ORDER BY name",
  );

  if (tables.isEmpty) {
    print('No tables found.');
  } else {
    for (final table in tables) {
      final name = table['name'] as String;

      final result = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM "$name"',
      );

      print('$name : ${result.first['count']} records');
    }
  }

  print('');
  print('================================================');
  print('');

  await db.close();
}