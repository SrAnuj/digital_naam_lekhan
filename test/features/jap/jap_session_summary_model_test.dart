import 'package:flutter_test/flutter_test.dart';
import 'package:sankalp/features/jap/data/models/jap_session_summary_model.dart';

void main() {
  group('JapSessionSummaryModel', () {
    test('parses complete summary response', () {
      final json = {
        'sankalp_id': 3,
        'total_sessions': 10,
        'total_naam': 2500,
        'total_completed_malas': 20,
        'total_extra_naam': 340,
        'total_duration_seconds': 3000,
        'today_naam': 250,
        'today_sessions': 2,
      };

      final model = JapSessionSummaryModel.fromJson(json);

      expect(model.sankalpId, 3);
      expect(model.totalSessions, 10);
      expect(model.totalNaam, 2500);
      expect(model.totalCompletedMalas, 20);
      expect(model.totalExtraNaam, 340);
      expect(model.totalDurationSeconds, 3000);
      expect(model.todayNaam, 250);
      expect(model.todaySessions, 2);
    });

    test('uses zero for missing numeric values', () {
      final model = JapSessionSummaryModel.fromJson({
        'sankalp_id': 3,
      });

      expect(model.sankalpId, 3);
      expect(model.totalSessions, 0);
      expect(model.totalNaam, 0);
      expect(model.todayNaam, 0);
      expect(model.todaySessions, 0);
    });
  });
}
