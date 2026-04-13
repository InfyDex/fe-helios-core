import 'package:flutter_test/flutter_test.dart';
import 'package:helios_auth_contract/helios_auth_contract.dart';

void main() {
  test('HeliosAuthSnapshot signedOut is not logged in', () {
    expect(HeliosAuthSnapshot.signedOut.isLoggedIn, isFalse);
  });
}
