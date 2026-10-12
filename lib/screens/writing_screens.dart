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
    for (final s in strokes) {
      if (s.length == 1) {
        canvas.drawCircle(
            s.first, 1.8, Paint()..color = AppColors.maroonDark);
        continue;
      }
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (var i = 1; i < s.length; i++) {
        path.lineTo(s[i].dx, s[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter old) => true;
}

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key});
  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  static const _rows = 4;
  final List<List<Offset>> _strokes = [];
  double _areaH = 1;

  int _rowsTouched() {
    final set = <int>{};
    final rowH = _areaH / _rows;
    for (final s in _strokes) {
      for (final p in s) {
        set.add((p.dy / rowH).floor().clamp(0, _rows - 1).toInt());
      }
    }
    return set.length;
  }

  void _save() {
    final n = _rowsTouched();
    if (n == 0) {
      showDemoSnack(context, 'Write at least one Naam first 🙏');
      return;
    }
    setState(() {
      AppState.todayWritten =
          (AppState.todayWritten + n).clamp(0, AppState.todayGoal).toInt();
      AppState.written += n;
      _strokes.clear();
    });
    if (AppState.todayWritten >= AppState.todayGoal) {
      Navigator.pushNamed(context, '/daily-complete');
    } else {
      showDemoSnack(context, '$n Naam saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = AppState.deity;
    final goal = AppState.todayGoal;
    final done = AppState.todayWritten;
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
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      Expanded(
                        child: Text('${d.en} Naam Lekhan',
                            textAlign: TextAlign.center,
                            style: AppText.display(18,
                                c: Colors.white, w: FontWeight.w600)),
                      ),
                      IconButton(
                        icon: Icon(Icons.check_circle_outline_rounded,
                            color: AppColors.goldLight),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/daily-complete'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Column(
                children: [
                  Text("Today's Goal: $goal",
                      style: AppText.body(14, w: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: GradientProgress(
                              value: done / goal, height: 10)),
                      const SizedBox(width: 10),
                      Text('$done / $goal',
                          style: AppText.body(12.5,
                              c: AppColors.maroon, w: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_done_rounded,
                          size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('Progress saved automatically',
                          style: AppText.body(11, c: AppColors.muted)),
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
                    border: Border.all(color: AppColors.gold, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.gold.o(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: LayoutBuilder(builder: (context, c) {
                      _areaH = c.maxHeight;
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
                                                : AppColors.line),
                                      ),
                                    ),
                                    child: Text(d.hi,
                                        style: AppText.hindi(54,
                                            c: AppColors.muted.o(0.22),
                                            w: FontWeight.w500)),
                                  ),
                                ),
                            ],
                          ),
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (e) => setState(
                                  () => _strokes.add([e.localPosition])),
                              onPanUpdate: (e) => setState(
                                  () => _strokes.last.add(e.localPosition)),
                              child: CustomPaint(
                                  painter: _InkPainter(_strokes)),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Undo',
                      leading: Icons.undo_rounded,
                      onTap: () => setState(() {
                        if (_strokes.isNotEmpty) _strokes.removeLast();
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Clear',
                      leading: Icons.delete_outline_rounded,
                      onTap: () => setState(_strokes.clear),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: PrimaryButton(label: 'Save & Continue', onTap: _save),
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
    final pct = AppState.written / AppState.target;
    return DevScaffold(
      showBack: false,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: 'Continue Writing',
            onTap: () => Navigator.pushReplacementNamed(context, '/writing'),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Done for Today',
            onTap: () => Navigator.pushNamedAndRemoveUntil(
                context, '/home', (r) => false),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Icon(Icons.wb_sunny_rounded, color: AppColors.saffron, size: 30),
          const SizedBox(height: 6),
          Text("Today's Naam Completed",
              textAlign: TextAlign.center, style: AppText.display(24)),
          const SizedBox(height: 24),
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.goldLight.o(0.7),
                AppColors.goldLight.o(0.2),
                Colors.transparent,
              ]),
            ),
            child: Icon(Icons.spa_rounded, size: 110, color: AppColors.saffron),
          ),
          const SizedBox(height: 8),
          Text('${AppState.todayGoal} / ${AppState.todayGoal}',
              style: AppText.display(40)),
          const SizedBox(height: 22),
          DevCard(
            child: Column(
              children: [
                Text('Total Progress',
                    style: AppText.body(12, c: AppColors.muted)),
                const SizedBox(height: 2),
                Text('${fmt(AppState.written)} / ${fmt(AppState.target)}',
                    style: AppText.body(16,
                        c: AppColors.maroon, w: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: GradientProgress(value: pct, height: 9)),
                    const SizedBox(width: 10),
                    Text('${(pct * 100).round()}%',
                        style: AppText.body(12,
                            c: AppColors.maroon, w: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_fire_department_rounded,
                  color: AppColors.saffron),
              const SizedBox(width: 6),
              Text('${AppState.streak} Day Streak',
                  style: AppText.body(14, w: FontWeight.w500)),
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
    const n = 27;
    final center = size.center(Offset.zero);
    final r = size.width / 2 - 20;
    final lit = (progress * n).floor();
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      final p = center + Offset(math.cos(a), math.sin(a)) * r;
      final base = i < lit ? AppColors.maroonDark : const Color(0xFFB8743A);
      final paint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [Colors.white.o(0.55), base],
        ).createShader(Rect.fromCircle(center: p, radius: 15));
      canvas.drawCircle(p, 15, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BeadPainter old) => old.progress != progress;
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
    final d = AppState.deity;
    final goal = AppState.todayGoal;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF2D58C), Color(0xFFFFF1CC), Color(0xFFF2D58C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.maroon),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
              Text('श्री ${d.hi}', style: AppText.hindi(44)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _count = _count >= goal ? 1 : _count + 1);
                },
                child: SizedBox(
                  width: 290,
                  height: 290,
                  child: CustomPaint(
                    painter: _BeadPainter(_count / goal),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$_count',
                              style: AppText.display(76,
                                  c: AppColors.maroon)),
                          Text('Tap to Count',
                              style: AppText.display(18,
                                  c: AppColors.maroon,
                                  w: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text("Today's Goal",
                  style: AppText.body(12.5, c: AppColors.muted)),
              Text('$_count / $goal', style: AppText.display(22)),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Reset',
                        onTap: () => setState(() => _count = 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Save',
                        onTap: () {
                          setState(() {
                            AppState.written += _count;
                            AppState.todayWritten =
                                (AppState.todayWritten + _count)
                                    .clamp(0, goal)
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
