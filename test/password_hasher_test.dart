import 'package:flutter_test/flutter_test.dart';
import 'package:blood_bank_locator/services/password_hasher.dart';

void main() {
  test('hashes passwords with a unique salt and verifies them', () async {
    final firstHash = await PasswordHasher.hash('sample-password');
    final secondHash = await PasswordHasher.hash('sample-password');

    expect(firstHash, startsWith('pbkdf2-sha256:600000:'));
    expect(secondHash, isNot(firstHash));
    expect(await PasswordHasher.verify('sample-password', firstHash), isTrue);
    expect(await PasswordHasher.verify('incorrect-password', firstHash), isFalse);
  });
}