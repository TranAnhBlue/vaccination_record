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
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE vaccination_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          vaccineName TEXT,
          dose INTEGER,
          date TEXT,
          reminderDate TEXT,
          imagePath TEXT,
          location TEXT,
          note TEXT
        )
        ''');

        await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          phone TEXT UNIQUE,
          password TEXT
        )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
          CREATE TABLE IF NOT EXISTS users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phone TEXT UNIQUE,
            password TEXT
          )
          ''');
        }
        if (oldVersion < 3) {
          try {
            await db.execute('ALTER TABLE vaccination_records ADD COLUMN reminderDate TEXT DEFAULT ""');
          } catch (e) {
            debugPrint("Column reminderDate might already exist: $e");
          }
        }
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE vaccination_records ADD COLUMN imagePath TEXT DEFAULT ""');
          } catch (e) {
            debugPrint("Column imagePath might already exist: $e");
          }
        }
      },
    );
  }
}