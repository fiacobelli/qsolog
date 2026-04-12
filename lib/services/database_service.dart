// lib/services/database_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/models.dart';

class DatabaseService {
  static Database? _db;

  static Future<void> initialize() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    String path;
    if (kIsWeb) {
      path = 'qsolog.db';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      path = join(dir.path, 'qsolog.db');
    }

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE qsos RENAME COLUMN extraFields TO adifFields');
          } catch (_) {
            try { await db.execute('ALTER TABLE qsos ADD COLUMN adifFields TEXT'); } catch (_) {}
          }
        }
        if (oldVersion < 3) {
          // Add my station columns
          for (final col in [
            'ALTER TABLE qsos ADD COLUMN myCallsign TEXT',
            'ALTER TABLE qsos ADD COLUMN myQth TEXT',
            'ALTER TABLE qsos ADD COLUMN myGrid TEXT',
            'ALTER TABLE qsos ADD COLUMN myRig TEXT',
            'ALTER TABLE qsos ADD COLUMN myPower REAL',
          ]) {
            try { await db.execute(col); } catch (_) {}
          }
        }
      },
    );
  }

  static Future<void> _createTable(Database db) async {
    await db.execute('''
      CREATE TABLE qsos (
        id TEXT PRIMARY KEY,
        callsign TEXT NOT NULL,
        band TEXT NOT NULL,
        frequency REAL NOT NULL,
        mode TEXT,
        rstSent TEXT,
        rstReceived TEXT,
        comments TEXT,
        dateTime TEXT NOT NULL,
        contactName TEXT,
        contactQth TEXT,
        contactGrid TEXT,
        contactCountry TEXT,
        contactState TEXT,
        contactLat REAL,
        contactLon REAL,
        myCallsign TEXT,
        myQth TEXT,
        myGrid TEXT,
        myRig TEXT,
        myPower REAL,
        tags TEXT,
        adifFields TEXT,
        distanceKm REAL
      )
    ''');
  }

  static Future<void> insertQso(QsoEntry qso) async {
    final db = await database;
    await db.insert('qsos', qso.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateQso(QsoEntry qso) async {
    final db = await database;
    await db.update('qsos', qso.toMap(), where: 'id = ?', whereArgs: [qso.id]);
  }

  static Future<void> deleteQso(String id) async {
    final db = await database;
    await db.delete('qsos', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<QsoEntry>> getAllQsos() async {
    final db = await database;
    final maps = await db.query('qsos', orderBy: 'dateTime DESC');
    return maps.map((m) => QsoEntry.fromMap(m)).toList();
  }

  /// Returns true if a duplicate exists: same callsign + band, within 30 min UTC
  static Future<bool> isDuplicate(QsoEntry qso) async {
    final db = await database;
    final dt = qso.dateTime.toUtc();
    final windowStart = dt.subtract(const Duration(minutes: 30)).toIso8601String();
    final windowEnd   = dt.add(const Duration(minutes: 30)).toIso8601String();

    final result = await db.query(
      'qsos',
      where: 'callsign = ? AND band = ? AND dateTime >= ? AND dateTime <= ? AND id != ?',
      whereArgs: [
        qso.callsign.toUpperCase(),
        qso.band,
        windowStart,
        windowEnd,
        qso.id,
      ],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
