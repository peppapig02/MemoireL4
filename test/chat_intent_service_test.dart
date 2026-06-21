import 'package:botroad/core/services/chat_intent_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = ChatIntentService();

  test('detecte un itineraire vers une destination', () {
    final request = service.parseMessage(
      message: 'Je veux aller à la Gare Centrale',
      userId: 'user-1',
    );

    expect(request.intent, ChatIntentService.calculateRouteIntent);
    expect(request.destinationText, 'la Gare Centrale');
    expect(request.userId, 'user-1');
  });

  test('extrait le depart et la destination', () {
    final request = service.parseMessage(message: 'Aller de Gombe à Limete');

    expect(request.intent, ChatIntentService.calculateRouteIntent);
    expect(request.startText, 'Gombe');
    expect(request.destinationText, 'Limete');
  });

  test('detecte une recherche de lieux proches', () {
    final request = service.parseMessage(
      message: 'Montre-moi les 3 pharmacies les plus proches',
    );

    expect(request.intent, ChatIntentService.findNearbyPlaceIntent);
    expect(request.category, 'pharmacie');
    expect(request.resultCount, 3);
  });

  test('priorise un signalement routier', () {
    final request = service.parseMessage(
      message: 'Je veux signaler un nid de poule',
    );

    expect(request.intent, ChatIntentService.reportBadRoadIntent);
  });
}
