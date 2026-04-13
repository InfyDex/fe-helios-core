import 'package:flutter_test/flutter_test.dart';
import 'package:helios_auth_contract/helios_auth_contract.dart';

void main() {
  group('HeliosUser', () {
    test('fromJson and toJson round-trip', () {
      const original = HeliosUser(
        id: 'id-1',
        email: 'e@example.com',
        name: 'Eve',
        avatar: 'https://example.com/a.png',
        phone: '+1000',
      );
      final decoded = HeliosUser.fromJson(original.toJson());
      expect(decoded.id, original.id);
      expect(decoded.email, original.email);
      expect(decoded.name, original.name);
      expect(decoded.avatar, original.avatar);
      expect(decoded.phone, original.phone);
    });

    test('displayLabel prefers non-empty name', () {
      const u = HeliosUser(id: '1', email: 'mail@test.com', name: '  N  ');
      expect(u.displayLabel, 'N');
    });

    test('displayLabel falls back to email when name empty', () {
      const u = HeliosUser(id: '1', email: 'only@email.com', name: '   ');
      expect(u.displayLabel, 'only@email.com');
    });
  });
}
