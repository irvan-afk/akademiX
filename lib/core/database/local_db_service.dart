import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDbService {
  static final LocalDbService instance = LocalDbService._init();
  static Database? _database;

  LocalDbService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('akademix_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );

    await _migrateBankSoalTables(db);
    return db;
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ujian_lokal (
        id INTEGER PRIMARY KEY,
        judul_ujian TEXT,
        mata_kuliah TEXT,
        durasi INTEGER,
        status_lokal TEXT,
        pin_mulai TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE soal_lokal (
        id INTEGER PRIMARY KEY,
        ujian_id INTEGER,
        teks_soal TEXT,
        tipe_soal TEXT,
        opsi_jawaban TEXT,
        bobot_nilai INTEGER,
        kunci_jawaban TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE jawaban_lokal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        soal_id INTEGER,
        sesi_pengerjaan_id INTEGER, -- Gunakan nama ini secara konsisten
        jawaban_teks TEXT,
        nilai INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await _createBankSoalTables(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // Hapus tabel lama agar skema baru yang benar bisa dibuat
      await db.execute("DROP TABLE IF EXISTS soal_lokal");
      await db.execute("DROP TABLE IF EXISTS jawaban_lokal");
      await db.execute("DROP TABLE IF EXISTS ujian_lokal");
      await _createDB(db, newVersion);
    }
  }

  Future<void> _createBankSoalTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bank_soal_lokal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dosen_id INTEGER,
        pengampu_id INTEGER,
        pengampu_label TEXT,
        remote_ujian_id INTEGER,
        kode_ujian TEXT,
        kode_pengawasan TEXT,
        mata_kuliah TEXT,
        judul_ujian TEXT,
        durasi_menit INTEGER,
        status TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS bank_soal_item_lokal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bank_soal_id INTEGER,
        urutan INTEGER,
        tipe_soal TEXT,
        teks_soal TEXT,
        opsi_jawaban TEXT,
        kunci_jawaban TEXT,
        poin INTEGER,
        catatan TEXT
      )
    ''');
  }

  Future<void> _migrateBankSoalTables(Database db) async {
    Future<void> addColumn(String sql) async {
      try {
        await db.execute(sql);
      } catch (_) {}
    }

    await addColumn(
      'ALTER TABLE bank_soal_lokal ADD COLUMN pengampu_id INTEGER',
    );
    await addColumn(
      'ALTER TABLE bank_soal_lokal ADD COLUMN pengampu_label TEXT',
    );
    await addColumn(
      'ALTER TABLE bank_soal_lokal ADD COLUMN remote_ujian_id INTEGER',
    );
    await addColumn('ALTER TABLE bank_soal_lokal ADD COLUMN kode_ujian TEXT');
    await addColumn(
      'ALTER TABLE bank_soal_lokal ADD COLUMN kode_pengawasan TEXT',
    );
  }

  Future<void> _ensureBankSoalTables() async {
    final db = await database;
    await _createBankSoalTables(db);
  }

  Future<void> saveSoalLokal(Map<String, dynamic> soal) async {
    await _ensureBankSoalTables();
    final db = await database;
    Map<String, dynamic> dataToSave = Map.from(soal);
    if (dataToSave['opsi_jawaban'] != null) {
      dataToSave['opsi_jawaban'] = jsonEncode(dataToSave['opsi_jawaban']);
    }
    await db.insert(
      'soal_lokal',
      dataToSave,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveUjianLokal(Map<String, dynamic> ujianData) async {
    final db = await database;
    await db.insert('ujian_lokal', {
      'id': ujianData['id'],
      'judul_ujian': ujianData['judul_ujian'],
      'durasi': ujianData['durasi_menit'],
      'pin_mulai': ujianData['pin_mulai'],
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUjianLokal(int ujianId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ujian_lokal',
      where: 'id = ?',
      whereArgs: [ujianId],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getSoalByUjian(int ujianId) async {
    await _ensureBankSoalTables();
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'soal_lokal',
      where: 'ujian_id = ?',
      whereArgs: [ujianId],
    );
    return List.generate(maps.length, (i) {
      Map<String, dynamic> soal = Map.from(maps[i]);
      if (soal['opsi_jawaban'] != null && soal['opsi_jawaban'] is String) {
        soal['opsi_jawaban'] = jsonDecode(soal['opsi_jawaban']);
      }
      return soal;
    });
  }

  Future<void> saveJawabanLokal(int soalId, int sesiId, String jawaban) async {
    await _ensureBankSoalTables();
    final db = await database;
    await db.insert('jawaban_lokal', {
      'soal_id': soalId,
      'sesi_pengerjaan_id': sesiId,
      'jawaban_teks': jawaban,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getJawabanBySesi(int sesiId) async {
    await _ensureBankSoalTables();
    final db = await database;
    return await db.query(
      'jawaban_lokal',
      where: 'sesi_pengerjaan_id = ?',
      whereArgs: [sesiId],
    );
  }
}
