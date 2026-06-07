import 'package:akademix/core/constants/app_enums.dart';
import 'package:akademix/core/models/user_model.dart';
import 'package:akademix/features/auth/data/auth_repository_impl.dart';
import 'package:akademix/features/auth/model/auth_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository extends AuthRepositoryImpl {
  FakeAuthRepository({
    this.loginResult,
    this.detailResult,
    this.verifySessionResult = true,
  });

  final UserModel? loginResult;
  final Map<String, dynamic>? detailResult;
  final bool verifySessionResult;

  @override
  Future<UserModel?> login(String username, String password) async {
    return loginResult;
  }

  @override
  Future<Map<String, dynamic>?> getUserDetail(UserModel user) async {
    return detailResult;
  }

  @override
  Future<bool> verifySession(int userId, String currentDeviceId) async {
    return verifySessionResult;
  }
}

void main() {
  group('AuthUsecase', () {
    test('returns error when username or password is empty', () async {
      final usecase = AuthUsecase(FakeAuthRepository());

      final result = await usecase.login('', '');

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'Username dan password wajib diisi');
    });

    test('returns success when repository login succeeds', () async {
      final user = UserModel(
        id: 1,
        role: UserRole.mahasiswa,
        username: 'mahasiswa1',
        deviceId: 'device-1',
      );

      final usecase = AuthUsecase(
        FakeAuthRepository(
          loginResult: user,
          detailResult: {'id': 10, 'nama': 'Mahasiswa A'},
        ),
      );

      final result = await usecase.login('mahasiswa1', 'password');

      expect(result.isSuccess, isTrue);
      expect(result.user, user);
      expect(result.detail?['nama'], 'Mahasiswa A');
    });

    test('returns error when repository login fails', () async {
      final usecase = AuthUsecase(FakeAuthRepository(loginResult: null));

      final result = await usecase.login('mahasiswa1', 'wrong');

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'Username atau password salah');
    });

    test('verifySession forwards repository result', () async {
      final usecase = AuthUsecase(
        FakeAuthRepository(verifySessionResult: false),
      );

      final result = await usecase.verifySession(1, 'device-1');

      expect(result, isFalse);
    });
  });
}
