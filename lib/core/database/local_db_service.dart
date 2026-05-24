import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

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
        pin_mulai TEXT,
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
    await addColumn('ALTER TABLE bank_soal_lokal ADD COLUMN pin_mulai TEXT');
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

  Future<Map<String, dynamic>?> getLatestBankSoalDraft({
    required int? dosenId,
  }) async {
    await _ensureBankSoalTables();
    if (dosenId == null) return null;
    final db = await database;

    final List<Map<String, dynamic>> drafts = await db.query(
      'bank_soal_lokal',
      where: 'dosen_id = ?',
      whereArgs: [dosenId],
      orderBy: 'updated_at DESC',
      limit: 1,
    );

    if (drafts.isEmpty) {
      return null;
    }

    final draftMap = drafts.first;
    final bankSoalId = draftMap['id'];

    final List<Map<String, dynamic>> soalItems = await db.query(
      'bank_soal_item_lokal',
      where: 'bank_soal_id = ?',
      whereArgs: [bankSoalId],
      orderBy: 'urutan ASC',
    );

    return {'bank_soal': draftMap, 'soal': soalItems};
  }

  Future<Map<String, dynamic>?> getBankSoalDraftByRemoteUjianId(
    int remoteUjianId,
  ) async {
    await _ensureBankSoalTables();
    final db = await database;

    final List<Map<String, dynamic>> drafts = await db.query(
      'bank_soal_lokal',
      where: 'remote_ujian_id = ?',
      whereArgs: [remoteUjianId],
    );

    if (drafts.isEmpty) {
      return null;
    }

    final draftMap = drafts.first;
    final bankSoalId = draftMap['id'];

    final List<Map<String, dynamic>> soalItems = await db.query(
      'bank_soal_item_lokal',
      where: 'bank_soal_id = ?',
      whereArgs: [bankSoalId],
      orderBy: 'urutan ASC',
    );

    return {'bank_soal': draftMap, 'soal': soalItems};
  }

  Future<int> saveBankSoalDraft({
    required int? id,
    required int? dosenId,
    required int? pengampuId,
    required String? pengampuLabel,
    required int? remoteUjianId,
    required String? kodeUjian,
    required String? kodePengawasan,
    required String? pinMulai,
    required String mataKuliah,
    required String judulUjian,
    required int? durasiMenit,
    required String status,
    required List<Map<String, dynamic>> soalList,
  }) async {
    await _ensureBankSoalTables();
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final bankSoalData = {
      'dosen_id': dosenId,
      'pengampu_id': pengampuId,
      'pengampu_label': pengampuLabel,
      'remote_ujian_id': remoteUjianId,
      'kode_ujian': kodeUjian,
      'kode_pengawasan': kodePengawasan,
      'pin_mulai': pinMulai,
      'mata_kuliah': mataKuliah,
      'judul_ujian': judulUjian,
      'durasi_menit': durasiMenit,
      'status': status,
      'updated_at': now,
      if (id == null) 'created_at': now,
    };

    late int bankSoalId;
    if (id != null) {
      await db.update(
        'bank_soal_lokal',
        bankSoalData,
        where: 'id = ?',
        whereArgs: [id],
      );
      bankSoalId = id;
    } else {
      bankSoalId = await db.insert('bank_soal_lokal', bankSoalData);
    }

    // Delete old soal items
    await db.delete(
      'bank_soal_item_lokal',
      where: 'bank_soal_id = ?',
      whereArgs: [bankSoalId],
    );

    // Insert new soal items
    for (int i = 0; i < soalList.length; i++) {
      final soal = soalList[i];
      await db.insert('bank_soal_item_lokal', {
        'bank_soal_id': bankSoalId,
        'urutan': i + 1,
        'tipe_soal': soal['tipe_soal'],
        'teks_soal': soal['teks_soal'],
        'opsi_jawaban': soal['opsi_jawaban'] is String
            ? soal['opsi_jawaban']
            : jsonEncode(soal['opsi_jawaban']),
        'kunci_jawaban': soal['kunci_jawaban'],
        'poin': soal['poin'],
        'catatan': soal['catatan'],
      });
    }

    return bankSoalId;
  }

  Future<bool> updateBankSoalStatus(int id, String status) async {
    await _ensureBankSoalTables();
    final db = await database;

    try {
      await db.update(
        'bank_soal_lokal',
        {'status': status, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      debugPrint('LocalDbService.updateBankSoalStatus error: $e');
      return false;
    }
  }

  Future<void> clearAllLokalData() async {
    final db = await database;
    await db.delete('jawaban_lokal');
    await db.delete('soal_lokal');
    await db.delete('ujian_lokal');
    await db.delete('bank_soal_item_lokal');
    await db.delete('bank_soal_lokal');
  }
}
