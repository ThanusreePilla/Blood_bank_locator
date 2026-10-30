import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/app_data.dart';
import 'password_hasher.dart';

class DatabaseService {
  DatabaseService._();

  static final instance = DatabaseService._();
  Database? _database;
  static const _referenceLatitude = 40.7128;
  static const _referenceLongitude = -74.0060;

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
    final databasePath = kIsWeb
        ? 'blood_bank_locator.db'
        : join(await getDatabasesPath(), 'blood_bank_locator.db');
    _database = await openDatabase(
      databasePath,
      version: 6,
      onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute(
            'ALTER TABLE users ADD COLUMN phone TEXT NOT NULL DEFAULT \'\'',
          );
        }
        if (oldVersion < 3) {
          await database.execute('''
            CREATE TABLE blood_requests_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              seeker_id INTEGER NOT NULL,
              bank_id INTEGER NOT NULL,
              blood_group TEXT NOT NULL,
              quantity INTEGER NOT NULL,
              status TEXT NOT NULL CHECK (status IN ('Pending', 'Approved', 'Rejected')),
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (seeker_id) REFERENCES users(id) ON DELETE CASCADE,
              FOREIGN KEY (bank_id) REFERENCES blood_banks(id) ON DELETE CASCADE
            )
          ''');
          await database.execute('''
            INSERT INTO blood_requests_new
              (id, seeker_id, bank_id, blood_group, quantity, status, created_at, updated_at)
            SELECT id, seeker_id, bank_id, blood_group, quantity,
              CASE WHEN status IN ('Accepted', 'Completed') THEN 'Approved' ELSE status END,
              created_at, updated_at
            FROM blood_requests
          ''');
          await database.execute('DROP TABLE blood_requests');
          await database.execute(
            'ALTER TABLE blood_requests_new RENAME TO blood_requests',
          );
        }
        if (oldVersion < 4) {
          await database.execute('''
            CREATE TABLE app_session (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              user_id INTEGER NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            )
          ''');
        }
        if (oldVersion < 5) {
          await database.execute('''
            CREATE TABLE saved_accounts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              email TEXT NOT NULL,
              role TEXT NOT NULL CHECK (role IN ('seeker', 'bank')),
              last_used_at TEXT NOT NULL,
              UNIQUE(role, email)
            )
          ''');
        }
        if (oldVersion < 6) {
          final users = await database.query(
            'users',
            columns: ['id', 'password'],
          );
          for (final user in users) {
            final storedPassword = user['password']! as String;
            if (storedPassword.startsWith('pbkdf2-sha256:')) continue;
            await database.update(
              'users',
              {'password': await PasswordHasher.hash(storedPassword)},
              where: 'id = ?',
              whereArgs: [user['id']],
            );
          }
        }
      },
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE blood_banks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            address TEXT NOT NULL,
            city TEXT NOT NULL,
            phone TEXT NOT NULL,
            email TEXT NOT NULL,
            verified INTEGER NOT NULL DEFAULT 0,
            latitude REAL,
            longitude REAL,
            opening_hours TEXT NOT NULL DEFAULT ''
          )
        ''');
        await database.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            role TEXT NOT NULL CHECK (role IN ('seeker', 'bank')),
            bank_id INTEGER,
            phone TEXT NOT NULL DEFAULT '',
            created_at TEXT NOT NULL,
            FOREIGN KEY (bank_id) REFERENCES blood_banks(id) ON DELETE SET NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE blood_stock (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bank_id INTEGER NOT NULL,
            blood_group TEXT NOT NULL,
            quantity INTEGER NOT NULL DEFAULT 0,
            last_updated TEXT NOT NULL,
            UNIQUE(bank_id, blood_group),
            FOREIGN KEY (bank_id) REFERENCES blood_banks(id) ON DELETE CASCADE
          )
        ''');
        await database.execute('''
          CREATE TABLE blood_requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            seeker_id INTEGER NOT NULL,
            bank_id INTEGER NOT NULL,
            blood_group TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            status TEXT NOT NULL CHECK (status IN ('Pending', 'Approved', 'Rejected')),
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (seeker_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (bank_id) REFERENCES blood_banks(id) ON DELETE CASCADE
          )
        ''');
        await database.execute('''
          CREATE TABLE favourites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            seeker_id INTEGER NOT NULL,
            bank_id INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            UNIQUE(seeker_id, bank_id),
            FOREIGN KEY (seeker_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (bank_id) REFERENCES blood_banks(id) ON DELETE CASCADE
          )
        ''');
        await database.execute('''
          CREATE TABLE app_session (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            user_id INTEGER NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');
        await database.execute('''
          CREATE TABLE saved_accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL,
            role TEXT NOT NULL CHECK (role IN ('seeker', 'bank')),
            last_used_at TEXT NOT NULL,
            UNIQUE(role, email)
          )
        ''');
        await _seed(database);
      },
    );
    return _database!;
  }

  Future<void> initialize() async {
    await database;
  }

  String _now() => DateTime.now().toIso8601String();

  Future<void> _seed(Database database) async {
    final banks = [
      {
        'name': 'City Care Blood Bank',
        'address': '14 Main Avenue',
        'city': 'Central City',
        'phone': '+1 555 010 1001',
        'email': 'citycare@example.com',
        'verified': 1,
        'latitude': 40.7128,
        'longitude': -74.0060,
        'opening_hours': 'Open today 08:00-20:00',
      },
      {
        'name': 'LifeLine Blood Center',
        'address': '88 North Avenue',
        'city': 'North District',
        'phone': '+1 555 010 1002',
        'email': 'lifeline@example.com',
        'verified': 1,
        'latitude': 40.7306,
        'longitude': -73.9352,
        'opening_hours': 'Open today 09:00-18:00',
      },
      {
        'name': 'Hope Community Blood Bank',
        'address': '6 Hope Street',
        'city': 'West District',
        'phone': '+1 555 010 1003',
        'email': 'hope@example.com',
        'verified': 1,
        'latitude': 40.7580,
        'longitude': -73.9855,
        'opening_hours': 'Open today 08:30-19:00',
      },
      {
        'name': 'Red Cross Medical Center',
        'address': '22 Riverside Road',
        'city': 'East Borough',
        'phone': '+1 555 010 1004',
        'email': 'redcross@example.com',
        'verified': 1,
        'latitude': 40.6782,
        'longitude': -73.9442,
        'opening_hours': 'Open today 10:00-17:00',
      },
      {
        'name': 'Unity Donor Hospital',
        'address': '101 Garden Lane',
        'city': 'South Park',
        'phone': '+1 555 010 1005',
        'email': 'unity@example.com',
        'verified': 0,
        'latitude': 40.6501,
        'longitude': -73.9496,
        'opening_hours': 'Open today 08:00-16:00',
      },
    ];
    final stock = [
      [24, 8, 16, 0, 6, 3, 31, 0],
      [5, 0, 12, 18, 14, 7, 0, 11],
      [18, 4, 22, 2, 9, 0, 27, 5],
      [7, 12, 3, 9, 0, 2, 14, 6],
      [0, 6, 8, 0, 4, 1, 11, 3],
    ];
    for (var index = 0; index < banks.length; index++) {
      final bankId = await database.insert('blood_banks', banks[index]);
      for (
        var groupIndex = 0;
        groupIndex < AppStateData.bloodGroups.length;
        groupIndex++
      ) {
        await database.insert('blood_stock', {
          'bank_id': bankId,
          'blood_group': AppStateData.bloodGroups[groupIndex],
          'quantity': stock[index][groupIndex],
          'last_updated': _now(),
        });
      }
      await database.insert('users', {
        'name': banks[index]['name'],
        'email': banks[index]['email'],
        'password': await PasswordHasher.hash('bank123'),
        'role': 'bank',
        'bank_id': bankId,
        'created_at': _now(),
      });
    }
    await database.insert('users', {
      'name': 'Alex Johnson',
      'email': 'alex.johnson@example.com',
      'password': await PasswordHasher.hash('password123'),
      'role': 'seeker',
      'created_at': _now(),
    });
  }

  Future<UserRecord?> authenticate(
    String email,
    String password,
    String role,
  ) async {
    final database = await this.database;
    final rows = await database.query(
      'users',
      where: 'email = ? AND role = ?',
      whereArgs: [email.trim().toLowerCase(), role],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final user = rows.first;
    final storedPassword = user['password']! as String;
    final isHashed = storedPassword.startsWith('pbkdf2-sha256:');
    final passwordMatches = isHashed
        ? await PasswordHasher.verify(password, storedPassword)
        : password == storedPassword;
    if (!passwordMatches) return null;

    if (!isHashed) {
      await database.update(
        'users',
        {'password': await PasswordHasher.hash(password)},
        where: 'id = ?',
        whereArgs: [user['id']],
      );
    }
    return _user(user);
  }

  Future<UserRecord?> restoreSession() async {
    final database = await this.database;
    final sessions = await database.query(
      'app_session',
      columns: ['user_id'],
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (sessions.isEmpty) return null;
    final users = await database.query(
      'users',
      where: 'id = ?',
      whereArgs: [sessions.first['user_id']],
      limit: 1,
    );
    return users.isEmpty ? null : _user(users.first);
  }

  Future<void> saveSession(int userId) async {
    final database = await this.database;
    await database.insert('app_session', {
      'id': 1,
      'user_id': userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearSession() async {
    final database = await this.database;
    await database.delete('app_session', where: 'id = ?', whereArgs: [1]);
  }

  Future<void> saveAccount(String email, String role) async {
    final database = await this.database;
    await database.insert('saved_accounts', {
      'email': email.trim().toLowerCase(),
      'role': role,
      'last_used_at': _now(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<String>> savedAccounts(String role) async {
    final database = await this.database;
    final rows = await database.query(
      'saved_accounts',
      columns: ['email'],
      where: 'role = ?',
      whereArgs: [role],
      orderBy: 'last_used_at DESC, id DESC',
    );
    return rows.map((row) => row['email']! as String).toList();
  }

  Future<void> removeSavedAccount(String email, String role) async {
    final database = await this.database;
    await database.delete(
      'saved_accounts',
      where: 'email = ? AND role = ?',
      whereArgs: [email.trim().toLowerCase(), role],
    );
  }

  Future<int> insertSeeker({
    required String name,
    required String email,
    required String password,
  }) async {
    final database = await this.database;
    final passwordHash = await PasswordHasher.hash(password);
    return database.insert('users', {
      'name': name,
      'email': email.toLowerCase(),
      'password': passwordHash,
      'role': 'seeker',
      'created_at': _now(),
    });
  }

  Future<UserRecord> insertBank({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final database = await this.database;
    final passwordHash = await PasswordHasher.hash(password);
    return database.transaction((transaction) async {
      final bankId = await transaction.insert('blood_banks', {
        'name': name,
        'address': 'Address not set',
        'city': 'Central City',
        'phone': phone,
        'email': email.toLowerCase(),
        'verified': 0,
        'opening_hours': 'Hours not set',
      });
      for (final group in AppStateData.bloodGroups) {
        await transaction.insert('blood_stock', {
          'bank_id': bankId,
          'blood_group': group,
          'quantity': 0,
          'last_updated': _now(),
        });
      }
      final userId = await transaction.insert('users', {
        'name': name,
        'email': email.toLowerCase(),
        'password': passwordHash,
        'role': 'bank',
        'bank_id': bankId,
        'created_at': _now(),
      });
      return UserRecord(
        id: userId,
        name: name,
        email: email,
        role: 'bank',
        bankId: bankId,
      );
    });
  }

  UserRecord _user(Map<String, Object?> row) => UserRecord(
    id: row['id']! as int,
    name: row['name']! as String,
    email: row['email']! as String,
    role: row['role']! as String,
    bankId: row['bank_id'] as int?,
    phone: row['phone'] as String? ?? '',
  );

  BloodBankRecord _bank(
    Map<String, Object?> row, {
    Map<String, int> stock = const {},
    String? lastUpdated,
  }) {
    final latitude = row['latitude'] as num?;
    final longitude = row['longitude'] as num?;
    return BloodBankRecord(
      id: row['id'] as int?,
      name: row['name']! as String,
      location: row['city']! as String,
      address: row['address']! as String,
      contact: row['phone']! as String,
      email: row['email']! as String,
      stock: stock,
      distanceKm: _distanceKm(latitude?.toDouble(), longitude?.toDouble()),
      verified: (row['verified'] as int? ?? 0) == 1,
      latitude: latitude?.toDouble(),
      longitude: longitude?.toDouble(),
      openingHours: row['opening_hours'] as String? ?? '',
      lastUpdated:
          lastUpdated ?? row['last_updated'] as String? ?? 'Updated today',
    );
  }

  double _distanceKm(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return double.infinity;
    const earthRadiusKm = 6371.0;
    final latitudeDelta = _radians(latitude - _referenceLatitude);
    final longitudeDelta = _radians(longitude - _referenceLongitude);
    final first =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(_radians(_referenceLatitude)) *
            math.cos(_radians(latitude)) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    return earthRadiusKm *
        2 *
        math.atan2(math.sqrt(first), math.sqrt(1 - first));
  }

  double _radians(double degrees) => degrees * math.pi / 180;

  Future<List<BloodBankRecord>> banks({
    String? bloodGroup,
    String? location,
  }) async {
    final database = await this.database;
    final args = <Object?>[];
    final groupFilter = bloodGroup == null
        ? ''
        : 'AND s.blood_group = ? AND s.quantity > 0';
    if (bloodGroup != null) args.add(bloodGroup);
    final locationFilter = location == null || location.trim().isEmpty
        ? ''
        : 'WHERE lower(b.city) LIKE ? OR lower(b.address) LIKE ?';
    if (location != null && location.trim().isNotEmpty) {
      final query = '%${location.trim().toLowerCase()}%';
      args.addAll([query, query]);
    }
    final rows = await database.rawQuery(
      'SELECT b.*, s.blood_group, s.quantity, s.last_updated FROM blood_banks b LEFT JOIN blood_stock s ON s.bank_id = b.id $groupFilter $locationFilter ORDER BY s.quantity DESC',
      args,
    );
    final results = <BloodBankRecord>[];
    for (final row in rows) {
      BloodBankRecord? existing;
      for (final item in results) {
        if (item.id == row['id']) existing = item;
      }
      if (existing == null) {
        results.add(
          _bank(
            row,
            stock: row['blood_group'] == null
                ? {}
                : {row['blood_group']! as String: row['quantity']! as int},
          ),
        );
      } else if (row['blood_group'] != null) {
        existing.stock[row['blood_group']! as String] = row['quantity']! as int;
      }
    }
    return results;
  }

  Future<BloodBankRecord?> bankById(int id) async {
    final database = await this.database;
    final rows = await database.query(
      'blood_banks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final stockRows = await database.query(
      'blood_stock',
      where: 'bank_id = ?',
      whereArgs: [id],
    );
    return _bank(
      rows.first,
      stock: {
        for (final row in stockRows)
          row['blood_group']! as String: row['quantity']! as int,
      },
      lastUpdated: stockRows.isEmpty
          ? null
          : stockRows.first['last_updated'] as String?,
    );
  }

  Future<List<BloodRequestRecord>> requests({
    required int userId,
    required bool forBank,
  }) async {
    final database = await this.database;
    final column = forBank ? 'r.bank_id' : 'r.seeker_id';
    final rows = await database.rawQuery(
      'SELECT r.*, b.name AS bank_name, b.city, u.name AS seeker_name, u.email AS seeker_email FROM blood_requests r JOIN blood_banks b ON b.id = r.bank_id JOIN users u ON u.id = r.seeker_id WHERE $column = ? ORDER BY r.created_at DESC',
      [userId],
    );
    return rows
        .map(
          (row) => BloodRequestRecord(
            id: '${row['id']}',
            seekerId: row['seeker_id'] as int,
            bankId: row['bank_id'] as int,
            seekerName: row['seeker_name'] as String? ?? '',
            seekerEmail: row['seeker_email'] as String? ?? '',
            bloodGroup: row['blood_group']! as String,
            quantity: row['quantity']! as int,
            bankName: row['bank_name']! as String,
            location: row['city']! as String,
            dateTime: row['created_at']! as String,
            status: row['status']! as String,
          ),
        )
        .toList();
  }

  Future<String?> addRequest({
    required int seekerId,
    required int bankId,
    required String bloodGroup,
    required int quantity,
  }) async {
    if (quantity <= 0) return 'Enter a valid quantity greater than zero.';
    final database = await this.database;
    final rows = await database.query(
      'blood_stock',
      columns: ['quantity'],
      where: 'bank_id = ? AND blood_group = ?',
      whereArgs: [bankId, bloodGroup],
      limit: 1,
    );
    final available = rows.isEmpty ? 0 : rows.first['quantity']! as int;
    if (available < quantity) {
      return 'Only $available units of $bloodGroup are available.';
    }
    final now = _now();
    await database.insert('blood_requests', {
      'seeker_id': seekerId,
      'bank_id': bankId,
      'blood_group': bloodGroup,
      'quantity': quantity,
      'status': 'Pending',
      'created_at': now,
      'updated_at': now,
    });
    return null;
  }

  Future<bool> updateRequest({
    required int requestId,
    required int bankId,
    required String status,
  }) async {
    final database = await this.database;
    if (status != 'Approved' && status != 'Rejected') {
      return false;
    }
    return database.transaction((transaction) async {
      final rows = await transaction.query(
        'blood_requests',
        where: 'id = ? AND bank_id = ?',
        whereArgs: [requestId, bankId],
        limit: 1,
      );
      if (rows.isEmpty) return false;
      final request = rows.first;
      final currentStatus = request['status']! as String;
      if (currentStatus != 'Pending') return false;
      final count = await transaction.update(
        'blood_requests',
        {'status': status, 'updated_at': _now()},
        where: 'id = ? AND bank_id = ?',
        whereArgs: [requestId, bankId],
      );
      return count == 1;
    });
  }

  Future<String?> updateStock({
    required int bankId,
    required String group,
    required int quantity,
  }) async {
    if (quantity < 0) return 'Enter a valid quantity of zero or more.';
    final database = await this.database;
    final updatedRows = await database.update(
      'blood_stock',
      {'quantity': quantity, 'last_updated': _now()},
      where: 'bank_id = ? AND blood_group = ?',
      whereArgs: [bankId, group],
    );
    if (updatedRows != 1) return 'Stock record not found for $group.';
    return null;
  }

  Future<void> updateSeeker({
    required int userId,
    required String name,
    required String email,
    required String phone,
  }) async {
    final database = await this.database;
    await database.update(
      'users',
      {'name': name, 'email': email.toLowerCase(), 'phone': phone},
      where: 'id = ? AND role = ?',
      whereArgs: [userId, 'seeker'],
    );
  }

  Future<void> updateBank({
    required int bankId,
    required String name,
    required String address,
    required String city,
    required String phone,
    required String email,
  }) async {
    final database = await this.database;
    await database.transaction((transaction) async {
      await transaction.update(
        'blood_banks',
        {
          'name': name,
          'address': address,
          'city': city,
          'phone': phone,
          'email': email.toLowerCase(),
        },
        where: 'id = ?',
        whereArgs: [bankId],
      );
      await transaction.update(
        'users',
        {'name': name, 'email': email.toLowerCase()},
        where: 'bank_id = ? AND role = ?',
        whereArgs: [bankId, 'bank'],
      );
    });
  }

  Future<List<BloodBankRecord>> favourites(int seekerId) async {
    final database = await this.database;
    final rows = await database.rawQuery(
      'SELECT b.id FROM favourites f JOIN blood_banks b ON b.id = f.bank_id WHERE f.seeker_id = ? ORDER BY f.created_at DESC',
      [seekerId],
    );
    final results = <BloodBankRecord>[];
    for (final row in rows) {
      final bank = await bankById(row['id']! as int);
      if (bank != null) results.add(bank);
    }
    return results;
  }

  Future<bool> toggleFavourite({
    required int seekerId,
    required int bankId,
  }) async {
    final database = await this.database;
    final existing = await database.query(
      'favourites',
      where: 'seeker_id = ? AND bank_id = ?',
      whereArgs: [seekerId, bankId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      await database.delete(
        'favourites',
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
      return false;
    }
    await database.insert('favourites', {
      'seeker_id': seekerId,
      'bank_id': bankId,
      'created_at': _now(),
    });
    return true;
  }

  Future<bool> isFavourite({required int seekerId, required int bankId}) async {
    final database = await this.database;
    final rows = await database.query(
      'favourites',
      where: 'seeker_id = ? AND bank_id = ?',
      whereArgs: [seekerId, bankId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}

class AppStateData {
  static const bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
}
