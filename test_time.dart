import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final now = DateTime.now();
  final waktuMulai = DateTime.parse("2026-05-24T17:10:00.000Z");
  
  print("Sekarang: $now");
  print("Sekarang (UTC): ${now.toUtc()}");
  print("Waktu Mulai: $waktuMulai");
  print("Waktu Mulai (Local): ${waktuMulai.toLocal()}");
  print("now.isBefore(waktuMulai): ${now.isBefore(waktuMulai)}");
}
