import 'package:akademix/core/constants/app_enums.dart';
import 'package:akademix/core/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel', () {
    test('parses role from JSON and falls back to mahasiswa', () {
      final dosen = UserModel.fromJson({
        'id': 1,
        'role': 'DOSEN',
        'username': 'dosen1',
        'device_id': 'dev-1',
      });

      final fallback = UserModel.fromJson({
        'id': 2,
        'role': 'unknown',
        'username': 'user2',
      });

      expect(dosen.role, UserRole.dosen);
      expect(dosen.deviceId, 'dev-1');
      expect(fallback.role, UserRole.mahasiswa);
      expect(fallback.username, 'user2');
    });
  });
}
