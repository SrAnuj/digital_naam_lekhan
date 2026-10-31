import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

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

  void _save() {
    final count = _rowsTouched();

    if (count == 0) {
      showDemoSnack(context, 'Write at least one Naam first 🙏');
      return;
    }

    setState(() {
      AppState.todayWritten =
          (AppState.todayWritten + count).clamp(0, AppState.todayGoal).toInt();

      AppState.written += count;
      _strokes.clear();
    });

    if (AppState.todayGoal > 0 && AppState.todayWritten >= AppState.todayGoal) {
      Navigator.pushNamed(context, '/daily-complete');
    } else {
      showDemoSnack(context, '$count Naam saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    final deity = AppState.deity;
    final goal = AppState.todayGoal;
    final done = AppState.todayWritten;
    final progress = goal > 0 ? (done / goal).clamp(0.0, 1.0) : 0.0;

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
                        onPressed: () => Navigator.maybePop(context),
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
                        onPressed: () {
                          Navigator.pushNamed(context, '/daily-complete');
                        },
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
                        '$done / $goal',
                        style: AppText.body(
                          12.5,
                          c: AppColors.maroon,
                          w: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
                        'Progress saved automatically',
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
                                onPanStart: (details) {
                                  setState(() {
                                    _strokes.add([details.localPosition]);
                                  });
                                },
                                onPanUpdate: (details) {
                                  if (_strokes.isEmpty) return;

                                  setState(() {
                                    _strokes.last.add(details.localPosition);
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
                label: 'Save & Continue',
                onTap: _save,
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

class DailyCompletionScreen extends StatelessWidget {
  const DailyCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final target = AppState.target;
    final written = AppState.written;
    final progress = target > 0 ? (written / target).clamp(0.0, 1.0) : 0.0;

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
            '${AppState.todayWritten} / ${AppState.todayGoal}',
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
}

// ───────────────────────── 16. JAP COUNTER ─────────────────────────

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

class _JapCounterScreenState extends State<JapCounterScreen> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final deity = AppState.deity;
    final goal = AppState.todayGoal;
    final progress = goal > 0 ? (_count / goal).clamp(0.0, 1.0) : 0.0;

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
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
              Text(
                deity == null ? 'नाम' : 'श्री ${deity.hi}',
                style: AppText.hindi(44),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (goal <= 0) {
                    showDemoSnack(context, 'Please set a valid daily goal');
                    return;
                  }

                  HapticFeedback.lightImpact();

                  setState(() {
                    _count = _count >= goal ? 1 : _count + 1;
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
                "Today's Goal",
                style: AppText.body(12.5, c: AppColors.muted),
              ),
              Text(
                '$_count / $goal',
                style: AppText.display(22),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Reset',
                        onTap: () {
                          setState(() {
                            _count = 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Save',
                        onTap: () {
                          if (_count == 0) {
                            showDemoSnack(
                                context, 'Count at least one Naam 🙏');
                            return;
                          }

                          final savedCount = _count;

                          setState(() {
                            AppState.written += savedCount;
                            AppState.todayWritten =
                                (AppState.todayWritten + savedCount)
                                    .clamp(0, goal > 0 ? goal : 0)
                                    .toInt();

                            _count = 0;
                          });

                          showDemoSnack(context, 'Jap saved 🙏');
                        },
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
