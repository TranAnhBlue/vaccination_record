import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final String path;
    if (kIsWeb) {
      path = 'vaccination.db';
    } else {
      path = join(await getDatabasesPath(), 'vaccination.db');
    }

    return openDatabase(
      path,
      version: 8,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          dob TEXT DEFAULT "",
          gender TEXT DEFAULT ""
        )
        ''');

        await db.execute('''
        CREATE TABLE members(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          name TEXT NOT NULL,
          dob TEXT DEFAULT "",
          gender TEXT DEFAULT "",
          relationship TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
        )
        ''');

        await db.execute('''
        CREATE TABLE vaccination_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          vaccineName TEXT NOT NULL,
          dose INTEGER DEFAULT 1,
          date TEXT NOT NULL,
          reminderDate TEXT DEFAULT "",
          imagePath TEXT DEFAULT "",
          location TEXT DEFAULT "",
          note TEXT DEFAULT "",
          memberId INTEGER,
          isCompleted INTEGER DEFAULT 0,
          FOREIGN KEY (memberId) REFERENCES members (id) ON DELETE CASCADE
        )
        ''');

        await db.execute('''
        CREATE TABLE appointments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          memberId INTEGER NOT NULL,
          vaccineName TEXT NOT NULL,
          center TEXT NOT NULL,
          appointmentDate TEXT NOT NULL,
          appointmentTime TEXT NOT NULL,
          note TEXT DEFAULT "",
          status TEXT DEFAULT "pending",
          createdAt TEXT NOT NULL,
          FOREIGN KEY (memberId) REFERENCES members (id) ON DELETE CASCADE
        )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
          CREATE TABLE IF NOT EXISTS users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT, phone TEXT UNIQUE, password TEXT
          )
          ''');
        }
        if (oldVersion < 3) {
          try { await db.execute('ALTER TABLE vaccination_records ADD COLUMN reminderDate TEXT DEFAULT ""'); } catch (_) {}
        }
        if (oldVersion < 4) {
          try { await db.execute('ALTER TABLE vaccination_records ADD COLUMN imagePath TEXT DEFAULT ""'); } catch (_) {}
        }
        if (oldVersion < 5) {
          try { await db.execute('ALTER TABLE users ADD COLUMN dob TEXT DEFAULT ""'); } catch (_) {}
          try { await db.execute('ALTER TABLE users ADD COLUMN gender TEXT DEFAULT ""'); } catch (_) {}
        }
        if (oldVersion < 6) {
          try {
            await db.execute('''
            CREATE TABLE IF NOT EXISTS members(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              userId INTEGER, name TEXT, dob TEXT, gender TEXT, relationship TEXT,
              FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
            )
            ''');
            final columns = await db.rawQuery('PRAGMA table_info(vaccination_records)');
            if (!columns.any((c) => c['name'] == 'memberId')) {
              await db.execute('ALTER TABLE vaccination_records ADD COLUMN memberId INTEGER');
            }
            final users = await db.query('users');
            for (var user in users) {
              final userId = user['id'] as int;
              final existing = await db.query('members', where: 'userId=? AND relationship=?', whereArgs: [userId, 'Chủ hộ']);
              final int memberId;
              if (existing.isEmpty) {
                memberId = await db.insert('members', {
                  'userId': userId, 'name': user['name'], 'dob': user['dob'] ?? '',
                  'gender': user['gender'] ?? '', 'relationship': 'Chủ hộ',
                });
              } else {
                memberId = existing.first['id'] as int;
              }
              if (user == users.first) {
                await db.update('vaccination_records', {'memberId': memberId}, where: 'memberId IS NULL');
              }
            }
          } catch (e) { debugPrint('Migration v6 failed: $e'); }
        }
        if (oldVersion < 7) {
          try { await db.execute('ALTER TABLE vaccination_records ADD COLUMN isCompleted INTEGER DEFAULT 0'); } catch (_) {}
        }
        if (oldVersion < 8) {
          try {
            await db.execute('''
            CREATE TABLE IF NOT EXISTS appointments(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              memberId INTEGER NOT NULL,
              vaccineName TEXT NOT NULL,
              center TEXT NOT NULL,
              appointmentDate TEXT NOT NULL,
              appointmentTime TEXT NOT NULL,
              note TEXT DEFAULT "",
              status TEXT DEFAULT "pending",
              createdAt TEXT NOT NULL,
              FOREIGN KEY (memberId) REFERENCES members (id) ON DELETE CASCADE
            )
            ''');
          } catch (e) { debugPrint('Migration v8 failed: $e'); }
        }
      },
    );
  }
}
