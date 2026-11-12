class JapSessionSummaryModel {
  final int sankalpId;
  final int totalSessions;
  final int totalNaam;
  final int totalCompletedMalas;
  final int totalExtraNaam;
  final int totalDurationSeconds;
  final int todayNaam;
  final int todaySessions;

  const JapSessionSummaryModel({
    required this.sankalpId,
    required this.totalSessions,
    required this.totalNaam,
    required this.totalCompletedMalas,
    required this.totalExtraNaam,
    required this.totalDurationSeconds,
    required this.todayNaam,
    required this.todaySessions,
  });

  factory JapSessionSummaryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return JapSessionSummaryModel(
      sankalpId: _toInt(json['sankalp_id']),
      totalSessions: _toInt(json['total_sessions']),
      totalNaam: _toInt(json['total_naam']),
      totalCompletedMalas: _toInt(json['total_completed_malas']),
      totalExtraNaam: _toInt(json['total_extra_naam']),
      totalDurationSeconds: _toInt(json['total_duration_seconds']),
      todayNaam: _toInt(json['today_naam']),
      todaySessions: _toInt(json['today_sessions']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
