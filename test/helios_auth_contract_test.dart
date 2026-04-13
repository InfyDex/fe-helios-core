import 'package:flutter_test/flutter_test.dart';
import 'package:helios_auth_contract/helios_auth_contract.dart';

void main() {
  group('HeliosAuthSnapshot', () {
    test('signedOut is not logged in', () {
      expect(HeliosAuthSnapshot.signedOut.isLoggedIn, isFalse);
    });

    test('loading is not logged in', () {
      expect(HeliosAuthSnapshot.loading.isLoggedIn, isFalse);
    });

    test('authenticated with user is logged in', () {
      const user = HeliosUser(id: '1', email: 'a@b.com');
      const snap = HeliosAuthSnapshot(
        status: HeliosAuthStatus.authenticated,
        user: user,
      );
      expect(snap.isLoggedIn, isTrue);
    });
  });

  group('HeliosAuthStatus', () {
    test('has three values', () {
      expect(HeliosAuthStatus.values.length, 3);
    });
  });
}
