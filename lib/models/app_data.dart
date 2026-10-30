class UserRecord {
  UserRecord({required this.id, required this.name, required this.email, required this.role, this.bankId, this.phone = ''});

  final int id;
  String name;
  String email;
  final String role;
  final int? bankId;
  String phone;
}

class BloodBankRecord {
  BloodBankRecord({
    this.id,
    required this.name,
    required this.location,
    required this.address,
    required this.contact,
    required this.email,
    required this.stock,
    required this.distanceKm,
    this.lastUpdated = 'Updated today at 09:40',
    this.verified = true,
    this.latitude,
    this.longitude,
    this.openingHours = 'Open today',
  });

  final int? id;
  int? get bankId => id;
  String name;
  String location;
  String address;
  String contact;
  String email;
  String bankType = 'Community blood bank';
  final Map<String, int> stock;
  final double distanceKm;
  String lastUpdated;
  bool verified;
  double? latitude;
  double? longitude;
  String openingHours;

  int unitsFor(String group) => stock[group] ?? 0;

  String statusFor(String group) {
    final units = unitsFor(group);
    if (units == 0) return 'Out of Stock';
    if (units <= 5) return 'Low Stock';
    return 'Available';
  }
}

class BloodRequestRecord {
  BloodRequestRecord({
    required this.id,
    this.seekerId,
    this.bankId,
    this.seekerName = '',
    this.seekerEmail = '',
    required this.bloodGroup,
    required this.quantity,
    required this.bankName,
    required this.location,
    required this.dateTime,
    required this.status,
  });

  final String id;
  final int? seekerId;
  final int? bankId;
  final String seekerName;
  final String seekerEmail;
  final String bloodGroup;
  final int quantity;
  String bankName;
  final String location;
  final String dateTime;
  String status;
}
