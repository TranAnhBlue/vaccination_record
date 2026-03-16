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
      version: 7,
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
          isCompleted INTEGER DEFAULT 0,
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
            // 1. Create members table if not exists
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
            final columns = await db.rawQuery('PRAGMA table_info(vaccination_records)');
            final hasMemberId = columns.any((column) => column['name'] == 'memberId');
            if (!hasMemberId) {
              await db.execute('ALTER TABLE vaccination_records ADD COLUMN memberId INTEGER');
            }

            // 3. Migrate existing records to a "Default" member for each user
            final users = await db.query('users');
            if (users.isNotEmpty) {
              for (var user in users) {
                final userId = user['id'] as int;
                final userName = user['name'] as String;
                
                final existingMembers = await db.query(
                  'members',
                  where: 'userId = ? AND relationship = ?',
                  whereArgs: [userId, 'Chủ hộ'],
                );

                int memberId;
                if (existingMembers.isEmpty) {
                  memberId = await db.insert('members', {
                    'userId': userId,
                    'name': userName,
                    'dob': user['dob'] ?? "",
                    'gender': user['gender'] ?? "",
                    'relationship': 'Chủ hộ',
                  });
                } else {
                  memberId = existingMembers.first['id'] as int;
                }

                if (users.length == 1) {
                  await db.update(
                    'vaccination_records',
                    {'memberId': memberId},
                    where: 'memberId IS NULL',
                  );
                }
                else if (user == users.first) {
                  await db.update(
                    'vaccination_records',
                    {'memberId': memberId},
                    where: 'memberId IS NULL',
                  );
                }
              }
            }
          } catch (e) {
            debugPrint("Migration to version 6 failed: $e");
          }
        }
        if (oldVersion < 7) {
          try {
            await db.execute('ALTER TABLE vaccination_records ADD COLUMN isCompleted INTEGER DEFAULT 0');
          } catch (e) {
            debugPrint("Column isCompleted might already exist: $e");
          }
        }
      },
    );
  }
}