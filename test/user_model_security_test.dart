import 'package:botroad/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ne serialise jamais le mot de passe utilisateur', () {
    final user = UserModel(
      key: 'user-1',
      email: 'user@example.com',
      password: 'secret-temporaire',
      nom: 'Utilisateur',
    );

    final json = user.toJson();

    expect(json.containsKey('password'), isFalse);
    expect(json.values, isNot(contains('secret-temporaire')));
  });

  test('ignore un ancien mot de passe provenant de Firestore', () {
    final user = UserModel.fromJson({
      'key': 'user-1',
      'email': 'user@example.com',
      'password': 'ancienne-valeur',
    });

    expect(user.password, isNull);
  });
}
