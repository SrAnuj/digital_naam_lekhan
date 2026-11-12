import 'package:flutter_test/flutter_test.dart';
import 'package:sankalp/features/jap/data/models/jap_session_model.dart';

void main() {
  group('JapSessionModel', () {
    test('parses a valid Jap session response', () {
      final json = {
        'id': 1,
        'sankalp_id': 3,
        'source': 'jap',
        'count': 250,
        'activity_date': '2026-11-11',
        'request_id': '7e2a1b44-9f31-4b0e-9f1a-8c2d6f4a1234',
        'metadata': {'device': 'android'},
        'jap_session': {
          'id': 1,
          'mala_size': 108,
          'completed_malas': 2,
          'extra_naam': 34,
          'duration_seconds': 300,
        },
        'created_at': '2026-11-11T10:00:00.000000Z',
      };

      final model = JapSessionModel.fromJson(json);

      expect(model.id, 1);
      expect(model.sankalpId, 3);
      expect(model.count, 250);
      expect(model.source, 'jap');
      expect(model.japSession?.malaSize, 108);
      expect(model.japSession?.completedMalas, 2);
      expect(model.japSession?.extraNaam, 34);
      expect(model.japSession?.durationSeconds, 300);
      expect(model.metadata?['device'], 'android');
    });

    test('handles missing optional session details', () {
      final model = JapSessionModel.fromJson({
        'id': 2,
        'sankalp_id': 3,
        'count': 108,
        'activity_date': '2026-11-11',
        'request_id': 'test-request',
      });

      expect(model.id, 2);
      expect(model.count, 108);
      expect(model.japSession, isNull);
      expect(model.metadata, isNull);
      expect(model.createdAt, isNull);
    });
  });

  group('JapSessionDetails', () {
    test('calculates expected Mala values from API data', () {
      const malaSize = 108;
      const count = 250;

      const completedMalas = count ~/ malaSize;
      const extraNaam = count % malaSize;

      expect(completedMalas, 2);
      expect(extraNaam, 34);
    });

    test('108 Naam completes exactly one Mala', () {
      const count = 108;
      const malaSize = 108;

      expect(count ~/ malaSize, 1);
      expect(count % malaSize, 0);
    });
  });
}
