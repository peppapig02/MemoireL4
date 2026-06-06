import 'package:botroad/core/models/route_segment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RouteSegment serializes route data', () {
    const segment = RouteSegment(
      id: 'segment-1',
      routeId: 'route-1',
      instruction: 'Continuer tout droit',
      startLat: -4.32,
      startLng: 15.31,
      endLat: -4.33,
      endLng: 15.32,
      distance: 1200,
      duration: 180,
      riskLevel: 'low',
      relatedReports: ['report-1'],
    );

    final json = segment.toJson();
    final parsed = RouteSegment.fromJson(json);

    expect(parsed.id, 'segment-1');
    expect(parsed.routeId, 'route-1');
    expect(parsed.instruction, 'Continuer tout droit');
    expect(parsed.distance, 1200);
    expect(parsed.relatedReports, ['report-1']);
  });
}
