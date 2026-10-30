import '../models/app_data.dart';

class SessionService {
  SessionService._();

  static final instance = SessionService._();

  UserRecord? user;
  BloodBankRecord? bank;

  void setUser(UserRecord value) {
    user = value;
    bank = null;
  }

  void setBank(UserRecord value, BloodBankRecord valueBank) {
    user = value;
    bank = valueBank;
  }

  void clear() {
    user = null;
    bank = null;
  }
}