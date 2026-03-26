import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vaccination_record/data/local/dao/user_dao.dart';
import 'package:vaccination_record/data/local/database_helper.dart';
import 'package:vaccination_record/data/repositories/auth_repository_impl.dart';
import 'package:vaccination_record/domain/entities/user.dart';

/// Luồng nghiệp vụ auth cục bộ: đăng ký → kiểm tra SĐT → đăng nhập, trùng SĐT, chuẩn hóa +84.
///
/// Chạy: `flutter test doctest/`
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await DatabaseHelper.resetForTesting();
  });

  group('AuthRepositoryImpl — luồng đăng ký & đăng nhập', () {
    test('đăng ký mới rồi đăng nhập thành công', () async {
      final repo = AuthRepositoryImpl(UserDao());
      const phone = '0968118025';
      const password = 'secret12';

      await repo.register(
        User(
          name: 'Nguyễn Thị Test',
          phone: phone,
          password: password,
          dob: '1990-01-17',
          gender: 'Nữ',
        ),
      );

      expect(await repo.isPhoneRegistered(phone), isTrue);

      final loggedIn = await repo.login(phone, password);
      expect(loggedIn, isNotNull);
      expect(loggedIn!.phone, phone);
      expect(loggedIn.name, 'Nguyễn Thị Test');
    });

    test('đăng ký trùng số điện thoại → SQLite UNIQUE', () async {
      final repo = AuthRepositoryImpl(UserDao());
      final u = User(
        name: 'A',
        phone: '0900000001',
        password: 'pass123',
        dob: '2000-01-01',
        gender: 'Nam',
      );

      await repo.register(u);

      expect(
        () => repo.register(
          User(
            name: 'B',
            phone: '0900000001',
            password: 'other',
            dob: '2000-01-02',
            gender: 'Nữ',
          ),
        ),
        throwsA(
          isA<DatabaseException>().having(
            (DatabaseException e) => e.isUniqueConstraintError(),
            'isUniqueConstraintError',
            isTrue,
          ),
        ),
      );
    });

    test('chuẩn hóa +84: đăng ký một dạng, đăng nhập dạng 0…', () async {
      final repo = AuthRepositoryImpl(UserDao());
      const canonical = '0968118025';
      const password = 'pw123456';

      await repo.register(
        User(
          name: 'Chuẩn hóa',
          phone: '+84 968 118 025',
          password: password,
          dob: '1995-06-15',
          gender: 'Khác',
        ),
      );

      expect(await repo.isPhoneRegistered(canonical), isTrue);
      final session = await repo.login(canonical, password);
      expect(session, isNotNull);
      expect(session!.phone, canonical);
    });
  });
}
