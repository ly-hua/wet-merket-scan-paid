// lib/db.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class AppDB {
  static Database? _db;
  static Future<Database> get db async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'wet_market.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (d, _) async {
        await d.execute(
          'CREATE TABLE stores(stallid TEXT PRIMARY KEY, name TEXT, owner TEXT, grp TEXT, defaultAmount INTEGER)',
        );
        await d.execute(
          'CREATE TABLE collectors(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
        );
        await d.execute(
          'CREATE TABLE payments(id INTEGER PRIMARY KEY AUTOINCREMENT, sdate TEXT, store_id TEXT, status TEXT, amount INTEGER, ts TEXT, note TEXT, collector TEXT)',
        );
        // Seed 8 stalls + 1 collector
        await d.insert('collectors', {'name': 'Collector A'});
        final stalls = [
          ['A1', 'Fresh Fish A', 'Mr. Sopheak', 'A', 1000],
          ['A2', 'Fresh Fish B', 'Ms. Dara', 'A', 1000],
          ['B1', 'Veggie Corner', 'Mrs. Chenda', 'B', 800],
          ['C1', 'Meat Shop', 'Mr. Vannak', 'C', 1500],
          ['B2', 'Fruit House', 'Ms. Kanika', 'B', 700],
          ['D1', 'Spice & Herbs', 'Mr. Rathana', 'D', 500],
          ['D2', 'Rice Seller', 'Mrs. Sochea', 'D', 600],
          ['E1', 'Noodle Shop', 'Mr. Kimsan', 'E', 900],
        ];
        for (final s in stalls) {
          await d.insert('stores', {
            'stallid': s[0],
            'name': s[1],
            'owner': s[2],
            'grp': s[3],
            'defaultAmount': s[4],
          });
        }
      },
    );
    return _db!;
  }
}
