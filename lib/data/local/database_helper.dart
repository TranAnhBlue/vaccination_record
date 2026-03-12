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
      version: 6,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE members(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER,
          name TEXT,
          dob TEXT,
          gender TEXT,
          relationship TEXT,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
        )
        ''');

        await db.execute('''
        CREATE TABLE vaccination_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          vaccineName TEXT,
          dose INTEGER,
          date TEXT,
          reminderDate TEXT,
          imagePath TEXT,
          location TEXT,
          note TEXT,
          memberId INTEGER,
          FOREIGN KEY (memberId) REFERENCES members (id) ON DELETE CASCADE
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
        if (oldVersion < 6) {
          try {
            // 1. Create members table
            await db.execute('''
            CREATE TABLE IF NOT EXISTS members(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              userId INTEGER,
              name TEXT,
              dob TEXT,
              gender TEXT,
              relationship TEXT,
              FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
            )
            ''');

            // 2. Add memberId to vaccination_records
            await db.execute('ALTER TABLE vaccination_records ADD COLUMN memberId INTEGER');

            // 3. Migrate existing records to a "Default" member for each user
            // This is a simplified migration: it assumes existing records belong to the user account owner.
            final users = await db.query('users');
            for (var user in users) {
              final userId = user['id'] as int;
              final userName = user['name'] as String;
              
              // Create a default member for this user
              final memberId = await db.insert('members', {
                'userId': userId,
                'name': userName,
                'dob': user['dob'] ?? "",
                'gender': user['gender'] ?? "",
                'relationship': 'Chủ hộ',
              });

              // Assign existing records (where memberId is NULL) to this default member
              // Note: This logic assumes all records currently in DB belong to the primary users.
              await db.update(
                'vaccination_records',
                {'memberId': memberId},
                where: 'memberId IS NULL',
              );
            }
          } catch (e) {
            debugPrint("Migration to version 6 failed: $e");
          }
        }
      },
    );
  }
}