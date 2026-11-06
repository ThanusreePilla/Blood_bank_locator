import '../models/app_data.dart';
import 'database.dart';
import 'session.dart';
import 'package:flutter/foundation.dart';

class AppState {
  AppState._();

  static const bloodGroups = AppStateData.bloodGroups;
  static final database = DatabaseService.instance;
  static final session = SessionService.instance;
  static bool get isDatabaseAvailable => !kIsWeb;

  static final List<_WebUser> _webUsers = [
    _WebUser(
      user: UserRecord(
        id: 1,
        name: 'Alex Johnson',
        email: 'alex.johnson@example.com',
        role: 'seeker',
      ),
      password: 'password123',
    ),
    _WebUser(
      user: UserRecord(
        id: 2,
        name: 'City Care Blood Bank',
        email: 'citycare@example.com',
        role: 'bank',
        bankId: 1,
      ),
      password: 'bank123',
    ),
  ];

  static final List<BloodBankRecord> _webBanks = [
    BloodBankRecord(
      id: 1,
      name: 'City Care Blood Bank',
      location: 'Central City',
      address: '14 Main Avenue',
      contact: '+1 555 010 1001',
      email: 'citycare@example.com',
      stock: const {
        'A+': 24,
        'A-': 8,
        'B+': 16,
        'B-': 0,
        'AB+': 6,
        'AB-': 3,
        'O+': 31,
        'O-': 0,
      },
      distanceKm: 0,
      verified: true,
      openingHours: 'Open today 08:00-20:00',
    ),
  ];
  static final List<BloodRequestRecord> _webRequests = [];
  static final Set<String> _webFavourites = <String>{};
  static final Map<String, List<String>> _savedWebAccounts = {
    'seeker': <String>[],
    'bank': <String>[],
  };
  static int _nextWebUserId = 3;
  static int _nextWebBankId = 2;
  static int _nextWebRequestId = 1;

  static Future<void> initialize() async {
    if (kIsWeb) return;
    await database.initialize();
    final user = await database.restoreSession();
    if (user == null) return;
    if (user.role == 'bank' && user.bankId != null) {
      final bank = await database.bankById(user.bankId!);
      if (bank != null) {
        session.setBank(user, bank);
        return;
      }
    } else if (user.role == 'seeker') {
      session.setUser(user);
      return;
    }
    await database.clearSession();
  }

  static String get seekerName => session.user?.name ?? 'Seeker';
  static String get seekerEmail => session.user?.email ?? '';
  static String get seekerPhone => session.user?.phone ?? '';
  static String get currentRole => session.user?.role ?? '';
  static bool isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

  static Future<UserRecord?> login({
    required String email,
    required String password,
    required String role,
  }) async {
    if (!isDatabaseAvailable) {
      final matches = _webUsers.where(
        (entry) =>
            entry.user.email == email.trim().toLowerCase() &&
            entry.password == password &&
            entry.user.role == role,
      );
      if (matches.isEmpty) return null;
      final entry = matches.first;
      _saveWebAccount(entry.user.email, entry.user.role);
      if (entry.user.role == 'bank') {
        final bank = _webBankById(entry.user.bankId!);
        if (bank == null) return null;
        session.setBank(entry.user, bank);
      } else {
        session.setUser(entry.user);
      }
      return entry.user;
    }

    final user = await database.authenticate(email, password, role);
    if (user == null) return null;
    if (user.role == 'bank' && user.bankId != null) {
      final bank = await database.bankById(user.bankId!);
      if (bank == null) return null;
      session.setBank(user, bank);
    } else {
      session.setUser(user);
    }
    await database.saveSession(user.id);
    await database.saveAccount(user.email, role);
    return user;
  }

  static Future<List<String>> savedAccounts({required String role}) =>
      isDatabaseAvailable
      ? database.savedAccounts(role)
      : Future.value(List<String>.from(_savedWebAccounts[role] ?? const []));

  static Future<void> removeSavedAccount({
    required String email,
    required String role,
  }) async {
    if (!isDatabaseAvailable) {
      final normalizedEmail = email.trim().toLowerCase();
      _savedWebAccounts[role]?.remove(normalizedEmail);
      return;
    }
    await database.removeSavedAccount(email, role);
  }

  static Future<String?> registerSeeker({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!isDatabaseAvailable) {
      final normalizedEmail = email.trim().toLowerCase();
      if (_webUsers.any((entry) => entry.user.email == normalizedEmail)) {
        return 'An account with this email already exists.';
      }
      final user = UserRecord(
        id: _nextWebUserId++,
        name: name,
        email: normalizedEmail,
        role: 'seeker',
      );
      _webUsers.add(_WebUser(user: user, password: password));
      session.setUser(user);
      _saveWebAccount(normalizedEmail, 'seeker');
      return null;
    }

    try {
      final id = await database.insertSeeker(
        name: name,
        email: email,
        password: password,
      );
      session.setUser(
        UserRecord(id: id, name: name, email: email, role: 'seeker'),
      );
      await database.saveSession(id);
      await database.saveAccount(email, 'seeker');
      return null;
    } catch (error) {
      return error.toString().contains('UNIQUE')
          ? 'An account with this email already exists.'
          : 'Could not create the account.';
    }
  }

  static Future<String?> registerBank({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    if (!isDatabaseAvailable) {
      final normalizedEmail = email.trim().toLowerCase();
      if (_webUsers.any((entry) => entry.user.email == normalizedEmail)) {
        return 'A bank account with this email already exists.';
      }
      final bankId = _nextWebBankId++;
      final user = UserRecord(
        id: _nextWebUserId++,
        name: name,
        email: normalizedEmail,
        role: 'bank',
        bankId: bankId,
      );
      final bank = BloodBankRecord(
        id: bankId,
        name: name,
        location: 'Central City',
        address: 'Address not set',
        contact: phone,
        email: normalizedEmail,
        stock: {for (final group in bloodGroups) group: 0},
        distanceKm: 0,
        verified: false,
        openingHours: 'Hours not set',
      );
      _webUsers.add(_WebUser(user: user, password: password));
      _webBanks.add(bank);
      session.setBank(user, bank);
      _saveWebAccount(normalizedEmail, 'bank');
      return null;
    }

    try {
      final user = await database.insertBank(
        name: name,
        phone: phone,
        email: email,
        password: password,
      );
      final bank = await database.bankById(user.bankId!);
      if (bank != null) {
        session.setBank(user, bank);
        await database.saveSession(user.id);
        await database.saveAccount(user.email, 'bank');
      }
      return null;
    } catch (error) {
      return error.toString().contains('UNIQUE')
          ? 'A bank account with this email already exists.'
          : 'Could not create the bank account.';
    }
  }

  static Future<List<BloodBankRecord>> searchBanks({
    required String bloodGroup,
    required String location,
  }) async {
    if (!isDatabaseAvailable) {
      final query = location.trim().toLowerCase();
      return Future.value(
        _webBanks
            .where(
              (bank) =>
                  bank.unitsFor(bloodGroup) > 0 &&
                  (query.isEmpty ||
                      bank.location.toLowerCase().contains(query) ||
                      bank.address.toLowerCase().contains(query)),
            )
            .map(_copyBank)
            .toList(),
      );
    }
    return database.banks(bloodGroup: bloodGroup, location: location);
  }

  static Future<List<BloodBankRecord>> nearbyBanks() async {
    final banks = isDatabaseAvailable
        ? await database.banks()
        : _webBanks.map(_copyBank).toList();
    banks.sort((first, second) {
      final distanceComparison = first.distanceKm.compareTo(second.distanceKm);
      return distanceComparison != 0
          ? distanceComparison
          : first.name.compareTo(second.name);
    });
    return banks;
  }

  static Future<BloodBankRecord?> bankById(int id) => isDatabaseAvailable
      ? database.bankById(id)
      : Future.value(_webBankById(id));

  static Future<void> refreshBankSession() async {
    final user = session.user;
    final bankId = session.bank?.id;
    if (user == null || bankId == null) return;
    if (!isDatabaseAvailable) {
      final bank = _webBankById(bankId);
      if (bank != null) session.setBank(user, bank);
      return;
    }
    final bank = await database.bankById(bankId);
    if (bank != null) session.setBank(user, bank);
  }

  static Future<List<BloodRequestRecord>> seekerRequests() {
    if (session.user?.role != 'seeker') return Future.value([]);
    if (!isDatabaseAvailable) {
      return Future.value(
        _webRequests
            .where((request) => request.seekerId == session.user!.id)
            .toList(),
      );
    }
    return database.requests(userId: session.user!.id, forBank: false);
  }

  static Future<List<BloodRequestRecord>> bankRequests() {
    if (session.bank == null) return Future.value([]);
    if (!isDatabaseAvailable) {
      return Future.value(
        _webRequests
            .where((request) => request.bankId == session.bank!.id)
            .toList(),
      );
    }
    return database.requests(userId: session.bank!.id!, forBank: true);
  }

  static Future<String?> addRequest({
    required String bloodGroup,
    required int quantity,
    required BloodBankRecord bank,
  }) async {
    if (session.user?.role != 'seeker' || bank.id == null) {
      return Future.value('Please sign in before creating a request.');
    }
    if (!isDatabaseAvailable) {
      if (quantity <= 0) {
        return Future.value('Enter a valid quantity greater than zero.');
      }
      if (bank.unitsFor(bloodGroup) < quantity) {
        return Future.value(
          'Only ${bank.unitsFor(bloodGroup)} units are available.',
        );
      }
      _webRequests.add(
        BloodRequestRecord(
          id: '${_nextWebRequestId++}',
          seekerId: session.user!.id,
          bankId: bank.id,
          bloodGroup: bloodGroup,
          quantity: quantity,
          bankName: bank.name,
          location: bank.location,
          dateTime: DateTime.now().toIso8601String(),
          status: 'Pending',
        ),
      );
      return Future.value(null);
    }
    try {
      return await database.addRequest(
        seekerId: session.user!.id,
        bankId: bank.id!,
        bloodGroup: bloodGroup,
        quantity: quantity,
      );
    } catch (_) {
      return 'Could not save the blood request. Please try again.';
    }
  }

  static Future<bool> updateRequestStatus(
    BloodRequestRecord request,
    String status,
  ) async {
    if (session.bank?.id == null || request.id.isEmpty) {
      return Future.value(false);
    }
    if (!isDatabaseAvailable) {
      final index = _webRequests.indexWhere(
        (item) => item.id == request.id && item.bankId == session.bank!.id,
      );
      if (index == -1) return Future.value(false);
      final current = _webRequests[index].status;
      final valid =
          current == 'Pending' &&
          (status == 'Approved' || status == 'Rejected');
      if (!valid) return Future.value(false);
      _webRequests[index].status = status;
      return Future.value(true);
    }
    try {
      return await database.updateRequest(
        requestId: int.parse(request.id),
        bankId: session.bank!.id!,
        status: status,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<String?> updateStock(
    BloodBankRecord bank,
    String group,
    int quantity,
  ) async {
    if (session.bank?.id == null || session.bank!.id != bank.id) {
      return 'Please sign in as a blood bank.';
    }
    if (!isDatabaseAvailable) {
      if (quantity < 0) return 'Enter a valid quantity of zero or more.';
      session.bank!.stock[group] = quantity;
      final sourceBank = _webBankSourceById(bank.id!);
      sourceBank?.stock[group] = quantity;
      return null;
    }
    String? error;
    try {
      error = await database.updateStock(
        bankId: session.bank!.id!,
        group: group,
        quantity: quantity,
      );
    } catch (_) {
      error = 'Could not save the stock update. Please try again.';
    }
    if (error == null) session.bank!.stock[group] = quantity;
    return error;
  }

  static Future<List<BloodBankRecord>> savedBanks() {
    if (session.user?.role != 'seeker') return Future.value([]);
    if (!isDatabaseAvailable) {
      return Future.value(
        _webBanks
            .where(
              (bank) =>
                  _webFavourites.contains('${session.user!.id}:${bank.id}'),
            )
            .map(_copyBank)
            .toList(),
      );
    }
    return database.favourites(session.user!.id);
  }

  static Future<bool> toggleSaved(BloodBankRecord bank) async {
    if (session.user?.role != 'seeker' || bank.id == null) {
      return Future.value(false);
    }
    if (!isDatabaseAvailable) {
      return Future.value(_toggleWebFavourite(bank.id!));
    }
    try {
      return await database.toggleFavourite(
        seekerId: session.user!.id,
        bankId: bank.id!,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isSaved(BloodBankRecord bank) async {
    if (session.user?.role != 'seeker' || bank.id == null) {
      return Future.value(false);
    }
    if (!isDatabaseAvailable) {
      return Future.value(
        _webFavourites.contains('${session.user!.id}:${bank.id}'),
      );
    }
    try {
      return await database.isFavourite(
        seekerId: session.user!.id,
        bankId: bank.id!,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<void> updateSeekerProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    if (session.user?.role != 'seeker') return;
    if (!isDatabaseAvailable) {
      session.user!.name = name;
      session.user!.email = email;
      session.user!.phone = phone;
      return;
    }
    await database.updateSeeker(
      userId: session.user!.id,
      name: name,
      email: email,
      phone: phone,
    );
    session.user!.name = name;
    session.user!.email = email;
    session.user!.phone = phone;
  }

  static Future<void> updateBankProfile({
    required String name,
    required String address,
    required String city,
    required String phone,
    required String email,
  }) async {
    if (session.bank?.id == null) return;
    if (!isDatabaseAvailable) {
      final bank = session.bank!;
      bank.name = name;
      bank.address = address;
      bank.location = city;
      bank.contact = phone;
      bank.email = email;
      final sourceBank = _webBankSourceById(bank.id!);
      if (sourceBank != null) {
        sourceBank.name = name;
        sourceBank.address = address;
        sourceBank.location = city;
        sourceBank.contact = phone;
        sourceBank.email = email;
      }
      session.user!.name = name;
      session.user!.email = email;
      return;
    }
    await database.updateBank(
      bankId: session.bank!.id!,
      name: name,
      address: address,
      city: city,
      phone: phone,
      email: email,
    );
    final bank = await database.bankById(session.bank!.id!);
    if (bank != null && session.user != null) {
      session.setBank(session.user!, bank);
    }
    session.user?.name = name;
    session.user?.email = email;
  }

  static Future<void> resetSession() async {
    session.clear();
    if (isDatabaseAvailable) {
      await database.clearSession();
    }
  }

  static BloodBankRecord? _webBankById(int id) {
    final bank = _webBankSourceById(id);
    return bank == null ? null : _copyBank(bank);
  }

  static BloodBankRecord? _webBankSourceById(int id) {
    for (final bank in _webBanks) {
      if (bank.id == id) return bank;
    }
    return null;
  }

  static BloodBankRecord _copyBank(BloodBankRecord bank) => BloodBankRecord(
    id: bank.id,
    name: bank.name,
    location: bank.location,
    address: bank.address,
    contact: bank.contact,
    email: bank.email,
    stock: Map<String, int>.from(bank.stock),
    distanceKm: bank.distanceKm,
    lastUpdated: bank.lastUpdated,
    verified: bank.verified,
    latitude: bank.latitude,
    longitude: bank.longitude,
    openingHours: bank.openingHours,
  );

  static void _saveWebAccount(String email, String role) {
    final normalizedEmail = email.trim().toLowerCase();
    final accounts = _savedWebAccounts[role];
    if (accounts == null) return;
    accounts.remove(normalizedEmail);
    accounts.insert(0, normalizedEmail);
    if (accounts.length > 10) accounts.removeLast();
  }

  static bool _toggleWebFavourite(int bankId) {
    final key = '${session.user!.id}:$bankId';
    if (_webFavourites.remove(key)) return false;
    _webFavourites.add(key);
    return true;
  }
}

class _WebUser {
  _WebUser({required this.user, required this.password});

  final UserRecord user;
  final String password;
}

class AppStateData {
  static const bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
}
