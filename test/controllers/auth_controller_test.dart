import 'package:akademix/core/constants/app_enums.dart';
import 'package:akademix/core/models/user_model.dart';
import 'package:akademix/features/auth/controllers/auth_controller.dart';
import 'package:akademix/features/auth/model/auth_usecase.dart';
import 'package:akademix/features/auth/data/auth_repository_impl.dart';
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
  group('AuthController', () {
    test('login sukses mengisi currentUser dan userData', () async {
      final user = UserModel(
        id: 1,
        role: UserRole.mahasiswa,
        username: 'mhs1',
        deviceId: 'device-1',
      );

      final controller = AuthController(
        AuthUsecase(
          FakeAuthRepository(
            loginResult: user,
            detailResult: {'id': 10, 'nama': 'Mahasiswa A'},
          ),
        ),
        enableSessionTimer: false,
      );

      final result = await controller.loginProcess('mhs1', 'password');

      expect(result, isTrue);
      expect(controller.currentUser, user);
      expect(controller.userData?['nama'], 'Mahasiswa A');
      expect(controller.errorMessage, isNull);
    });

    test('login gagal mengembalikan errorMessage', () async {
      final controller = AuthController(
        AuthUsecase(FakeAuthRepository(loginResult: null)),
        enableSessionTimer: false,
      );

      final result = await controller.loginProcess('mhs1', 'salah');

      expect(result, isFalse);
      expect(controller.currentUser, isNull);
      expect(controller.errorMessage, 'Username atau password salah');
    });

    test(
      'multi-device login membuat sesi logout jika verifikasi gagal',
      () async {
        final user = UserModel(
          id: 1,
          role: UserRole.mahasiswa,
          username: 'mhs1',
          deviceId: 'device-1',
        );

        final controller = AuthController(
          AuthUsecase(
            FakeAuthRepository(
              loginResult: user,
              detailResult: {'id': 10, 'nama': 'Mahasiswa A'},
              verifySessionResult: false,
            ),
          ),
          enableSessionTimer: false,
        );

        await controller.loginProcess('mhs1', 'password');
        await controller.checkSessionOnce();

        expect(controller.currentUser, isNull);
        expect(controller.userData, isNull);
      },
    );
  });
}
