class JapSessionModel {
  final int id;
  final int sankalpId;
  final String source;
  final int count;
  final String activityDate;
  final String requestId;
  final Map<String, dynamic>? metadata;
  final JapSessionDetails? japSession;
  final DateTime? createdAt;

  const JapSessionModel({
    required this.id,
    required this.sankalpId,
    required this.source,
    required this.count,
    required this.activityDate,
    required this.requestId,
    this.metadata,
    this.japSession,
    this.createdAt,
  });

  factory JapSessionModel.fromJson(Map<String, dynamic> json) {
    final sessionData = json['jap_session'];

    return JapSessionModel(
      id: _toInt(json['id']),
      sankalpId: _toInt(json['sankalp_id']),
      source: json['source']?.toString() ?? 'jap',
      count: _toInt(json['count']),
      activityDate: json['activity_date']?.toString() ?? '',
      requestId: json['request_id']?.toString() ?? '',
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      japSession: sessionData is Map
          ? JapSessionDetails.fromJson(
              Map<String, dynamic>.from(sessionData),
            )
          : null,
      createdAt: _toDateTime(json['created_at']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class JapSessionDetails {
  final int? id;
  final int malaSize;
  final int completedMalas;
  final int extraNaam;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int durationSeconds;

  const JapSessionDetails({
    this.id,
    required this.malaSize,
    required this.completedMalas,
    required this.extraNaam,
    this.startedAt,
    this.completedAt,
    required this.durationSeconds,
  });

  factory JapSessionDetails.fromJson(Map<String, dynamic> json) {
    return JapSessionDetails(
      id: json['id'] == null ? null : int.tryParse(json['id'].toString()),
      malaSize: _toInt(json['mala_size'], 108),
      completedMalas: _toInt(json['completed_malas']),
      extraNaam: _toInt(json['extra_naam']),
      startedAt: _toDateTime(json['started_at']),
      completedAt: _toDateTime(json['completed_at']),
      durationSeconds: _toInt(json['duration_seconds']),
    );
  }

  static int _toInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    return int.tryParse(value.toString()) ?? fallback;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
