import 'package:flutter/material.dart';

class AppTheme {
  // --- Konfigurasi Warna (Palet Soft Blue & Minimalist) ---
  static const Color primaryColor = Color(
    0xFF2962FF,
  ); // Biru seperti di gambar referensi
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color accentColor = Color(
    0xFFFFAB00,
  ); // Oranye untuk status 'Ragu-ragu'
  static const Color successColor = Color(
    0xFF4CAF50,
  ); // Hijau untuk tombol 'Selesai'
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFF44336);
  static const Color backgroundColor = Color(0xFFF8FAFF);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color borderColor = Color(0xFFE0E0E0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,

      // Konfigurasi AppBar (Putih, Bersih, Tanpa Shadow)
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      // FIX ERROR: Menggunakan CardThemeData, bukan CardTheme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0, // Datar untuk kesan minimalist
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: borderColor),
        ),
      ),

      // Konfigurasi Tombol Utama (Elegan & Rounded)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          elevation: 0,
        ),
      ),

      // Konfigurasi Tombol Outlined (Untuk 'Ragu-ragu' atau 'Kembali')
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textSecondary,
          side: const BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Konfigurasi Input Field (Untuk Essay & Login)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFAFAFA), // Pengganti Colors.grey[50]
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),

      // Konfigurasi List Tile (Untuk Opsi Pilihan Ganda)
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  // Utility untuk radius yang konsisten
  static BorderRadius get radiusSmall => BorderRadius.circular(8);
  static BorderRadius get radiusMedium => BorderRadius.circular(12);
  static BorderRadius get radiusLarge => BorderRadius.circular(20);
}
