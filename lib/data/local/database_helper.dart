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

  /// Đóng singleton và xóa file DB — dùng trong `doctest/` để mỗi test độc lập.
  @visibleForTesting
  static Future<void> resetForTesting() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    if (kIsWeb) return;
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      final path = join(await getDatabasesPath(), 'vaccination.db');
      await deleteDatabase(path);
    } catch (_) {}
  }

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
      version: 10,
      // Enforce FOREIGN KEY constraints so ON DELETE CASCADE works correctly.
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        // Android: sqlite native từ chối execute() với PRAGMA busy_timeout
        // ("Queries can be performed using ... query or rawQuery methods only").
        if (Platform.isAndroid) {
          try {
            await db.rawQuery('PRAGMA busy_timeout = 5000');
          } catch (_) {}
        } else {
          await db.execute('PRAGMA busy_timeout = 5000');
        }
      },
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

        // Performance indexes for common queries.
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_members_userId ON members(userId)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_members_relationship ON members(relationship)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_vaccination_records_memberId ON vaccination_records(memberId)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_vaccination_records_date ON vaccination_records(date)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_vaccination_records_reminderDate ON vaccination_records(reminderDate)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_appointments_memberId ON appointments(memberId)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_appointments_date_time ON appointments(appointmentDate, appointmentTime)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status)',
        );
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

        if (oldVersion < 9) {
          // Create indexes only (no schema-breaking changes).
          try {
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_members_userId ON members(userId)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_members_relationship ON members(relationship)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_vaccination_records_memberId ON vaccination_records(memberId)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_vaccination_records_date ON vaccination_records(date)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_vaccination_records_reminderDate ON vaccination_records(reminderDate)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_appointments_memberId ON appointments(memberId)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_appointments_date_time ON appointments(appointmentDate, appointmentTime)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status)',
            );
          } catch (e) {
            debugPrint('Migration v9 indexes failed: $e');
          }
        }

        // v10: bỏ cột `dose`, vaccineName đã mang thông tin "Mũi 1/2/3..."
        if (oldVersion < 10) {
          try {
            // 1) Tạo bảng mới không có cột dose.
            await db.execute('''
              CREATE TABLE vaccination_records_new(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                vaccineName TEXT NOT NULL,
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

            // 2) Copy dữ liệu cũ sang bảng mới.
            final rows = await db.query('vaccination_records');
            for (final row in rows) {
              final id = row['id'] as int?;
              final oldName = (row['vaccineName'] ?? '') as String;
              final oldDose = row['dose'] as int? ?? 1;

              // Nếu tên đã có "mũi" (hoặc "mui") thì giữ nguyên.
              final hasDoseInName = RegExp(
                r'(mũi|mui)\s*\d+',
                caseSensitive: false,
              ).hasMatch(oldName);
              final newName = hasDoseInName
                  ? oldName
                  : '$oldName - Mũi $oldDose';

              await db.insert('vaccination_records_new', {
                if (id != null) 'id': id,
                'vaccineName': newName,
                'date': row['date'],
                'reminderDate': row['reminderDate'] ?? '',
                'imagePath': row['imagePath'] ?? '',
                'location': row['location'] ?? '',
                'note': row['note'] ?? '',
                'memberId': row['memberId'],
                'isCompleted': row['isCompleted'] ?? 0,
              });
            }

            // 3) Thay bảng cũ.
            await db.execute('DROP TABLE vaccination_records');
            await db.execute('ALTER TABLE vaccination_records_new RENAME TO vaccination_records');

            // 4) Tạo lại indexes (vì bảng cũ đã bị DROP).
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_vaccination_records_memberId ON vaccination_records(memberId)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_vaccination_records_date ON vaccination_records(date)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_vaccination_records_reminderDate ON vaccination_records(reminderDate)',
            );
          } catch (e) {
            debugPrint('Migration v10 failed: $e');
          }
        }
      },
    );
  }
}
