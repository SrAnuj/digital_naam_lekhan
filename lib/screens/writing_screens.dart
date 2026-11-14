import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import '../features/home/data/sankalp_progress_repository.dart';
import 'package:uuid/uuid.dart';

import '../features/jap/data/jap_session_repository.dart';

import '../features/jap/data/models/jap_session_model.dart';
import '../features/jap/data/models/jap_session_summary_model.dart';

import '../core/network/api_save_exception.dart';
import '../core/services/offline_progress_service.dart';

// ───────────────────────── SHARED PROGRESS HELPERS ─────────────────────────
// ---------------- SHARED PROGRESS HELPERS ----------------

String _todayDate() {
  final now = DateTime.now();

  final year = now.year.toString().padLeft(4, '0');
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '');
}

Map<String, dynamic>? _readMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return null;
}

/// Backend se aaj ka daily target aur completed progress load karta hai.
Future<void> _loadTodaySummary() async {
  final sankalpId = AppState.createdSankalpId;

  if (sankalpId == null || sankalpId <= 0) {
    AppState.dailySummaryError = 'Active Sankalp was not found.';
    AppState.hasDailySummaryLoaded = true;
    AppState.isDailySummaryLoading = false;
    return;
  }

  AppState.isDailySummaryLoading = true;
  AppState.dailySummaryError = null;

  try {
    final response =
        await SankalpProgressRepository.fetchTodaySummary(sankalpId);

    final summary = _readMap(response);

    if (summary == null) {
      throw Exception('Invalid daily progress response.');
    }

    final dailyTarget = _readMap(summary['daily_target']);

    AppState.todayGoal = _readInt(dailyTarget?['target_count']);
    AppState.todayWritten = _readInt(summary['completed_today']) ?? 0;

    AppState.isDailySummaryLoading = false;
    AppState.hasDailySummaryLoaded = true;
    AppState.dailySummaryError = null;
  } catch (error) {
    AppState.isDailySummaryLoading = false;
    AppState.hasDailySummaryLoaded = true;
    AppState.dailySummaryError = _progressError(error);
  }
}

/// Writing progress ko unique request ID ke saath backend par save karta hai.
Future<Map<String, dynamic>> _saveNaamProgress(
  int count,
  String requestId,
) async {
  final sankalpId = AppState.createdSankalpId;

  if (sankalpId == null || sankalpId <= 0) {
    throw Exception(
      'Your active Sankalp was not found. Please refresh your Sankalp and try again.',
    );
  }

  if (count <= 0) {
    throw Exception('Please enter a valid Naam count.');
  }

  return SankalpProgressRepository.saveWritingProgress(
    sankalpId: sankalpId,
    count: count,
    progressDate: _todayDate(),
    requestId: requestId,
  );
}

/// Successful API save ke baad local progress update karta hai.
void _updateLocalProgress(
  Map<String, dynamic> response,
  int savedCount,
) {
  final summary = _readMap(response['daily_target_summary']);

  final completedToday = _readInt(summary?['completed_today']);

  if (completedToday != null) {
    AppState.todayWritten = completedToday;
  } else {
    AppState.todayWritten += savedCount;
  }

  AppState.written += savedCount;
}

bool _isSankalpCompleted(Map<String, dynamic> response) {
  if (response['sankalp_completed'] == true) {
    return true;
  }

  final summary = _readMap(response['sankalp_summary']);

  return summary?['status']?.toString().toLowerCase() == 'completed';
}

Map<String, dynamic> _sankalpSummary(
  Map<String, dynamic> response,
) {
  return _readMap(response['sankalp_summary']) ?? {};
}

void _openCompletionScreen(
  BuildContext context,
  Map<String, dynamic> response,
) {
  Navigator.pushNamed(
    context,
    '/sankalp-complete',
    arguments: _sankalpSummary(response),
  );
}

String _progressError(Object error) {
  return error.toString().replaceFirst('Exception: ', '');
}

bool _isDailyGoalCompleted() {
  final goal = AppState.todayGoal;

  return goal != null && goal > 0 && AppState.todayWritten >= goal;
}

double _dailyProgress(int completed, int? goal) {
  if (goal == null || goal <= 0) return 0.0;

  return (completed / goal).clamp(0.0, 1.0).toDouble();
}
// ───────────────────────── 11. WRITING SCREEN ─────────────────────────

class _InkPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _InkPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.maroonDark
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;

      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          1.8,
          Paint()..color = AppColors.maroonDark,
        );
        continue;
      }

      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);

      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) => true;
}

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key});

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  static const int _rows = 4;

  final List<List<Offset>> _strokes = [];

  double _areaH = 1;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    await _loadTodaySummary();

    if (!mounted) return;

    setState(() {});
  }

  int _rowsTouched() {
    if (_areaH <= 0) return 0;

    final touchedRows = <int>{};
    final rowHeight = _areaH / _rows;

    for (final stroke in _strokes) {
      for (final point in stroke) {
        final row = (point.dy / rowHeight).floor().clamp(0, _rows - 1).toInt();

        touchedRows.add(row);
      }
    }

    return touchedRows.length;
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final count = _rowsTouched();

    if (count == 0) {
      showDemoSnack(context, 'Write at least one Naam first 🙏');
      return;
    }

    final sankalpId = AppState.createdSankalpId;

    if (sankalpId == null || sankalpId <= 0) {
      showDemoSnack(context, 'Your active Sankalp was not found.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final requestId = const Uuid().v4();
    final progressDate = _todayDate();

    try {
      final response = await _saveNaamProgress(count, requestId);

      if (!mounted) return;

      _updateLocalProgress(response, count);

      setState(() {
        _strokes.clear();
        _isSaving = false;
      });

      if (_isSankalpCompleted(response)) {
        _openCompletionScreen(context, response);
      } else if (_isDailyGoalCompleted()) {
        Navigator.pushNamed(context, '/daily-complete');
      } else {
        showDemoSnack(context, '$count Naam saved successfully 🙏');
      }
    } catch (error) {
      if (!mounted) return;

      if (error is ApiSaveException && error.isRetryable) {
        try {
          await OfflineProgressService.instance.enqueue(
            action: 'writing_progress',
            requestId: requestId,
            payload: {
              'sankalp_id': sankalpId,
              'count': count,
              'progress_date': progressDate,
            },
          );

          if (!mounted) return;

          _updateLocalProgress({}, count);

          setState(() {
            _strokes.clear();
            _isSaving = false;
          });

          showDemoSnack(
            context,
            '$count Naam saved offline. Pending sync.',
          );

          return;
        } catch (queueError) {
          if (!mounted) return;

          setState(() {
            _isSaving = false;
          });

          showDemoSnack(
            context,
            'Offline save failed: ${_progressError(queueError)}',
          );

          return;
        }
      }

      setState(() {
        _isSaving = false;
      });

      showDemoSnack(
        context,
        'Unable to save Naam: ${_progressError(error)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deity = AppState.deity;
    final goal = AppState.todayGoal;
    final done = AppState.todayWritten;

    final progress = _dailyProgress(done, goal);

    return Scaffold(
      body: DevBackground(
        child: Column(
          children: [
            // Dark header
            Container(
              color: AppColors.maroonDark,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.maybePop(context),
                      ),
                      Expanded(
                        child: Text(
                          '${deity?.en ?? 'Naam'} Naam Lekhan',
                          textAlign: TextAlign.center,
                          style: AppText.display(
                            18,
                            c: Colors.white,
                            w: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.goldLight,
                        ),
                        onPressed: _isSaving ? null : _save,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Daily goal and progress
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Column(
                children: [
                  if (AppState.isDailySummaryLoading)
                    Text(
                      'Loading daily progress...',
                      style: AppText.body(13, c: AppColors.muted),
                    )
                  else if (goal == null || goal <= 0)
                    Text(
                      'Daily goal not set',
                      style: AppText.body(
                        14,
                        c: AppColors.maroon,
                        w: FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      "Today's Goal: $goal",
                      style: AppText.body(14, w: FontWeight.w600),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GradientProgress(
                          value: progress,
                          height: 10,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        goal == null || goal <= 0
                            ? '$done completed'
                            : '$done / $goal',
                        style: AppText.body(
                          12.5,
                          c: AppColors.maroon,
                          w: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (AppState.dailySummaryError != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Could not refresh daily progress',
                      style: AppText.body(
                        10.5,
                        c: AppColors.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_done_rounded,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Save your progress to the cloud',
                        style: AppText.body(11, c: AppColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Writing canvas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.gold,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.o(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _areaH = constraints.maxHeight;

                        return Stack(
                          children: [
                            Column(
                              children: [
                                for (var i = 0; i < _rows; i++)
                                  Expanded(
                                    child: Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: i == _rows - 1
                                                ? Colors.transparent
                                                : AppColors.line,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        deity?.hi ?? '',
                                        style: AppText.hindi(
                                          54,
                                          c: AppColors.muted.o(0.22),
                                          w: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanStart: _isSaving
                                    ? null
                                    : (details) {
                                        setState(() {
                                          _strokes.add([
                                            details.localPosition,
                                          ]);
                                        });
                                      },
                                onPanUpdate: _isSaving
                                    ? null
                                    : (details) {
                                        if (_strokes.isEmpty) return;

                                        setState(() {
                                          _strokes.last.add(
                                            details.localPosition,
                                          );
                                        });
                                      },
                                child: CustomPaint(
                                  painter: _InkPainter(_strokes),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Undo and clear
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Undo',
                      leading: Icons.undo_rounded,
                      onTap: () {
                        if (_isSaving) return;

                        setState(() {
                          if (_strokes.isNotEmpty) {
                            _strokes.removeLast();
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Clear',
                      leading: Icons.delete_outline_rounded,
                      onTap: () {
                        if (_isSaving) return;

                        setState(() {
                          _strokes.clear();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Save writing
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: PrimaryButton(
                label: _isSaving ? 'Saving...' : 'Save & Continue',
                onTap: _isSaving ? () {} : _save,
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 14),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 12. DAILY COMPLETION ─────────────────────────
// ───────────────────────── 12. DAILY COMPLETION ─────────────────────────

class DailyCompletionScreen extends StatelessWidget {
  const DailyCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final int target = AppState.target;
    final int written = AppState.written;

    final double progress =
        target > 0 ? (written / target).clamp(0.0, 1.0).toDouble() : 0.0;

    final int dailyGoal = AppState.todayGoal ?? 0;

    return DevScaffold(
      showBack: false,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: 'Continue Writing',
            onTap: () {
              Navigator.pushReplacementNamed(context, '/writing');
            },
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Done for Today',
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Icon(
            Icons.wb_sunny_rounded,
            color: AppColors.saffron,
            size: 30,
          ),
          const SizedBox(height: 6),
          Text(
            "Today's Naam Completed",
            textAlign: TextAlign.center,
            style: AppText.display(24),
          ),
          const SizedBox(height: 24),
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.goldLight.o(0.7),
                  AppColors.goldLight.o(0.2),
                  Colors.transparent,
                ],
              ),
            ),
            child: Icon(
              Icons.spa_rounded,
              size: 110,
              color: AppColors.saffron,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppState.todayWritten} / $dailyGoal',
            style: AppText.display(40),
          ),
          const SizedBox(height: 22),
          DevCard(
            child: Column(
              children: [
                Text(
                  'Total Progress',
                  style: AppText.body(12, c: AppColors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  '${fmt(written)} / ${fmt(target)}',
                  style: AppText.body(
                    16,
                    c: AppColors.maroon,
                    w: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GradientProgress(
                        value: progress,
                        height: 9,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(progress * 100).round()}%',
                      style: AppText.body(
                        12,
                        c: AppColors.maroon,
                        w: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.saffron,
              ),
              const SizedBox(width: 6),
              Text(
                '${AppState.streak} Day Streak',
                style: AppText.body(14, w: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
} // ───────────────────────── 16. JAP COUNTER ─────────────────────────

class _BeadPainter extends CustomPainter {
  final double progress;

  _BeadPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const beadCount = 27;

    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 20;
    final litCount = (progress.clamp(0.0, 1.0) * beadCount).floor();

    for (var i = 0; i < beadCount; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / beadCount;
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * radius;

      final baseColor =
          i < litCount ? AppColors.maroonDark : const Color(0xFFB8743A);

      final paint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [
            Colors.white.o(0.55),
            baseColor,
          ],
        ).createShader(
          Rect.fromCircle(center: position, radius: 15),
        );

      canvas.drawCircle(position, 15, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BeadPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class JapCounterScreen extends StatefulWidget {
  const JapCounterScreen({super.key});

  @override
  State<JapCounterScreen> createState() => _JapCounterScreenState();
}

class SankalpCompletionScreen extends StatelessWidget {
  const SankalpCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;

    final summary = arguments is Map
        ? Map<String, dynamic>.from(arguments)
        : <String, dynamic>{};

    final target = _readInt(summary['target_count']) ?? AppState.target;
    final completed = _readInt(summary['completed_count']) ?? AppState.written;

    final completedAt = summary['completed_at']?.toString();
    final deityName = AppState.deity?.hi ?? 'Naam';

    String completionDate = 'Today';
    if (completedAt != null && completedAt.isNotEmpty) {
      final parsedDate = DateTime.tryParse(completedAt);
      if (parsedDate != null) {
        completionDate = '${parsedDate.day.toString().padLeft(2, '0')}-'
            '${parsedDate.month.toString().padLeft(2, '0')}-'
            '${parsedDate.year}';
      }
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF2D58C),
              Color(0xFFFFF1CC),
              Color(0xFFF2D58C),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 42,
                  color: AppColors.saffron,
                ),
                const SizedBox(height: 20),
                Text(
                  'ॐ',
                  style: AppText.hindi(
                    54,
                    c: AppColors.maroon,
                    w: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Sankalp Completed!',
                  textAlign: TextAlign.center,
                  style: AppText.display(
                    30,
                    c: AppColors.maroon,
                    w: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'आपका $deityName नाम संकल्प पूर्ण हुआ।',
                  textAlign: TextAlign.center,
                  style: AppText.hindi(
                    20,
                    c: AppColors.maroon,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your devotion and dedication have completed this Sankalp.',
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    14,
                    c: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Naam Completed',
                        style: AppText.body(
                          13,
                          c: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${fmt(completed)} / ${fmt(target)}',
                        style: AppText.display(
                          30,
                          c: AppColors.maroon,
                          w: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 30,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Completed on $completionDate',
                        style: AppText.body(
                          12,
                          c: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Continue to Home',
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JapCounterScreenState extends State<JapCounterScreen> {
  int _count = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    await _loadTodaySummary();

    if (!mounted) return;

    setState(() {});
  }

  int? get _activeSankalpId {
    final id = AppState.createdSankalpId;

    if (id == null || id <= 0) return null;

    return id;
  }

  // ───────────────────── SAVE JAP SESSION ─────────────────────

  Future<void> _save() async {
    if (_isSaving) return;

    if (_count <= 0) {
      showDemoSnack(context, 'Count at least one Naam 🙏');
      return;
    }

    final savedCount = _count;
    final sankalpId = _activeSankalpId;

    if (sankalpId == null) {
      showDemoSnack(context, 'Your active Sankalp was not found.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final requestId = const Uuid().v4();
    final activityDate = _todayDate();

    try {
      final result = await JapSessionRepository.saveSession(
        sankalpId: sankalpId,
        count: savedCount,
        requestId: requestId,
        activityDate: activityDate,
      );

      if (!mounted) return;

      AppState.todayWritten += savedCount;
      AppState.written += savedCount;

      setState(() {
        _count = 0;
        _isSaving = false;
      });

      final completionResponse = {
        'sankalp_summary': result.sankalpSummary,
        'sankalp_completed': result.sankalpCompleted,
      };

      if (_isSankalpCompleted(completionResponse)) {
        _openCompletionScreen(context, completionResponse);
      } else if (_isDailyGoalCompleted()) {
        Navigator.pushNamed(context, '/daily-complete');
      } else {
        showDemoSnack(
          context,
          '$savedCount Jap saved successfully 🙏',
        );
      }
    } catch (error) {
      if (!mounted) return;

      if (error is ApiSaveException && error.isRetryable) {
        try {
          await OfflineProgressService.instance.enqueue(
            action: 'jap_session',
            requestId: requestId,
            payload: {
              'sankalp_id': sankalpId,
              'count': savedCount,
              'activity_date': activityDate,
              'mala_size': 108,
              'duration_seconds': 0,
            },
          );

          if (!mounted) return;

          AppState.todayWritten += savedCount;
          AppState.written += savedCount;

          setState(() {
            _count = 0;
            _isSaving = false;
          });

          showDemoSnack(
            context,
            '$savedCount Jap saved offline. Pending sync.',
          );

          return;
        } catch (queueError) {
          if (!mounted) return;

          setState(() {
            _isSaving = false;
          });

          showDemoSnack(
            context,
            'Offline save failed: ${_progressError(queueError)}',
          );

          return;
        }
      }

      setState(() {
        _isSaving = false;
      });

      showDemoSnack(
        context,
        'Unable to save Jap: ${_progressError(error)}',
      );
    }
  }

  // ───────────────────── JAP SUMMARY ─────────────────────

  Future<void> _showJapSummary() async {
    final sankalpId = _activeSankalpId;

    if (sankalpId == null) {
      showDemoSnack(context, 'Your active Sankalp was not found.');
      return;
    }

    final future = JapSessionRepository.fetchSummary(
      sankalpId: sankalpId,
    );

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(sheetContext).size.height * 0.58,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1CC),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.maroon.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Jap Summary',
                  style: AppText.display(
                    24,
                    c: AppColors.maroon,
                  ),
                ),
                Text(
                  'Your Naam Jap progress',
                  style: AppText.body(
                    12,
                    c: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: FutureBuilder<List<JapSessionSummaryModel>>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.maroon,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Unable to load Jap Summary.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: AppText.body(12),
                          ),
                        );
                      }

                      final summaries = snapshot.data ?? [];

                      JapSessionSummaryModel? summary;

                      for (final item in summaries) {
                        if (item.sankalpId == sankalpId) {
                          summary = item;
                          break;
                        }
                      }

                      if (summary == null) {
                        return Center(
                          child: Text(
                            'No Jap sessions recorded yet.',
                            style: AppText.body(
                              13,
                              c: AppColors.muted,
                            ),
                          ),
                        );
                      }

                      return ListView(
                        children: [
                          _summaryTile(
                            'Today\'s Jap',
                            summary.todayNaam,
                            Icons.today_rounded,
                          ),
                          _summaryTile(
                            'Total Jap',
                            summary.totalNaam,
                            Icons.radio_button_checked,
                          ),
                          _summaryTile(
                            'Completed Malas',
                            summary.totalCompletedMalas,
                            Icons.brightness_7_rounded,
                          ),
                          _summaryTile(
                            'Extra Naam',
                            summary.totalExtraNaam,
                            Icons.add_circle_outline_rounded,
                          ),
                          _summaryTile(
                            'Total Sessions',
                            summary.totalSessions,
                            Icons.history_rounded,
                          ),
                          _summaryTile(
                            'Today Sessions',
                            summary.todaySessions,
                            Icons.calendar_today_rounded,
                          ),
                          _summaryTile(
                            'Total Duration',
                            summary.totalDurationSeconds,
                            Icons.timer_outlined,
                            suffix: ' sec',
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryTile(
    String label,
    int value,
    IconData icon, {
    String suffix = '',
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.maroon,
            size: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppText.body(
                12,
                c: AppColors.ink,
              ),
            ),
          ),
          Text(
            '${fmt(value)}$suffix',
            style: AppText.body(
              15,
              c: AppColors.maroon,
              w: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── JAP HISTORY ─────────────────────

  Future<void> _showJapHistory() async {
    final sankalpId = _activeSankalpId;

    if (sankalpId == null) {
      showDemoSnack(context, 'Your active Sankalp was not found.');
      return;
    }

    final future = JapSessionRepository.fetchHistory(
      sankalpId: sankalpId,
      page: 1,
      perPage: 20,
    );

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(sheetContext).size.height * 0.72,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1CC),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.maroon.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Jap History',
                  style: AppText.display(
                    24,
                    c: AppColors.maroon,
                  ),
                ),
                Text(
                  'Your previous Jap sessions',
                  style: AppText.body(
                    12,
                    c: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<JapSessionModel>>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.maroon,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Unable to load Jap History.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: AppText.body(12),
                          ),
                        );
                      }

                      final sessions = snapshot.data ?? [];

                      if (sessions.isEmpty) {
                        return Center(
                          child: Text(
                            'No Jap history available yet.',
                            style: AppText.body(
                              13,
                              c: AppColors.muted,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: sessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final details = session.japSession;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.creamDark,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.history_rounded,
                                      color: AppColors.maroon,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _formatActivityDate(
                                          session.activityDate,
                                        ),
                                        style: AppText.body(
                                          13,
                                          c: AppColors.maroon,
                                          w: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${fmt(session.count)} Naam',
                                      style: AppText.body(
                                        14,
                                        c: AppColors.maroon,
                                        w: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (details != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _historyDetail(
                                          'Malas',
                                          details.completedMalas,
                                        ),
                                      ),
                                      Expanded(
                                        child: _historyDetail(
                                          'Extra Naam',
                                          details.extraNaam,
                                        ),
                                      ),
                                      Expanded(
                                        child: _historyDetail(
                                          'Duration',
                                          details.durationSeconds,
                                          suffix: ' sec',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  'Session #${session.id}',
                                  style: AppText.body(
                                    10,
                                    c: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _historyDetail(
    String label,
    int value, {
    String suffix = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.body(
            10,
            c: AppColors.muted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${fmt(value)}$suffix',
          style: AppText.body(
            12,
            c: AppColors.ink,
            w: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatActivityDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) return value;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day-$month-$year';
  }

  // ───────────────────── BUILD ─────────────────────

  @override
  Widget build(BuildContext context) {
    final deity = AppState.deity;
    final goal = AppState.todayGoal;

    // Saved Writing + saved Jap + current unsaved Jap count.
    final combinedToday = AppState.todayWritten + _count;

    final progress = _dailyProgress(combinedToday, goal);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF2D58C),
              Color(0xFFFFF1CC),
              Color(0xFFF2D58C),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.maroon,
                  ),
                  onPressed:
                      _isSaving ? null : () => Navigator.maybePop(context),
                ),
              ),
              Text(
                deity == null ? 'नाम' : 'श्री ${deity.hi}',
                style: AppText.hindi(44),
              ),
              const Spacer(),

              // Existing Jap Bead Counter.
              GestureDetector(
                onTap: _isSaving
                    ? null
                    : () {
                        HapticFeedback.lightImpact();

                        setState(() {
                          // Counting continues even after daily goal.
                          _count++;
                        });
                      },
                child: SizedBox(
                  width: 290,
                  height: 290,
                  child: CustomPaint(
                    painter: _BeadPainter(progress),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_count',
                            style: AppText.display(
                              76,
                              c: AppColors.maroon,
                            ),
                          ),
                          Text(
                            'Tap to Count',
                            style: AppText.display(
                              18,
                              c: AppColors.maroon,
                              w: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              Text(
                AppState.isDailySummaryLoading
                    ? 'Loading daily progress...'
                    : "Today's Goal",
                style: AppText.body(
                  12.5,
                  c: AppColors.muted,
                ),
              ),
              Text(
                goal == null || goal <= 0
                    ? '$combinedToday completed • Goal not set'
                    : '$combinedToday / $goal',
                textAlign: TextAlign.center,
                style: AppText.display(22),
              ),

              const SizedBox(height: 12),

              // Summary and History actions.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _showJapSummary,
                        icon: const Icon(
                          Icons.analytics_outlined,
                          size: 18,
                        ),
                        label: const Text('Summary'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.maroon,
                          side: const BorderSide(
                            color: AppColors.maroon,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _showJapHistory,
                        icon: const Icon(
                          Icons.history_rounded,
                          size: 18,
                        ),
                        label: const Text('History'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.maroon,
                          side: const BorderSide(
                            color: AppColors.maroon,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Existing Reset and Save buttons.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Reset',
                        onTap: () {
                          if (_isSaving) return;

                          setState(() {
                            // Only unsaved counter session resets.
                            _count = 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: _isSaving ? 'Saving...' : 'Save',
                        onTap: _isSaving ? () {} : _save,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
