import 'package:botroad/core/models/road_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RoadReport report({
    DateTime? createdAt,
    DateTime? expiresAt,
    String status = 'pending',
  }) {
    return RoadReport(
      latitude: -4.32,
      longitude: 15.31,
      type: 'embouteillage',
      severity: 'moyen',
      source: 'user',
      status: status,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }

  test('un signalement de plus de 48 heures sans expiration est inactif', () {
    final oldReport = report(
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    );

    expect(oldReport.isActive, isFalse);
  });

  test('un signalement recent reste actif pendant 48 heures', () {
    final recentReport = report(
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    expect(recentReport.isActive, isTrue);
  });

  test('un signalement sans date reste visible par compatibilite', () {
    expect(report().isActive, isTrue);
  });

  test('un signalement supprime ou expire reste inactif', () {
    expect(report(status: 'expired').isActive, isFalse);
    expect(report(status: 'deleted').isActive, isFalse);
  });
}
