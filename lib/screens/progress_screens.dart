import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

// ───────────────────────── 13. PROGRESS DASHBOARD ─────────────────────────
class ProgressDashboardScreen extends StatelessWidget {
  const ProgressDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = AppState.deity;
    final pct = AppState.written / AppState.target;
    final milestones = <int>[1008, 5000, 11000, 21000];
    return DevScaffold(
      title: 'Your Sankalp',
      showBack: false,
      navIndex: 2,
      body: Column(
        children: [
          const SizedBox(height: 4),
          Text('श्री ${d.hi}', style: AppText.hindi(38)),
          const SizedBox(height: 8),
          Text('${fmt(AppState.written)} / ${fmt(AppState.target)}',
              style: AppText.body(16, w: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: GradientProgress(value: pct, height: 11)),
              const SizedBox(width: 10),
              Text('${(pct * 100).round()}%',
                  style: AppText.body(12.5,
                      c: AppColors.maroon, w: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const StatBox(label: 'Started', value: '1 Oct 2026'),
              StatBox(label: 'Streak', value: '${AppState.streak} Days'),
              const StatBox(label: 'Daily Avg', value: '122'),
            ],
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Milestones', style: AppText.display(18)),
          ),
          const SizedBox(height: 10),
          DevCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < milestones.length; i++) ...[
                  Builder(builder: (context) {
                    final m = milestones[i];
                    final done = AppState.written >= m;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            done
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            color: done ? AppColors.success : AppColors.gold,
                          ),
                          const SizedBox(width: 12),
                          Text(fmt(m),
                              style: AppText.body(14.5,
                                  w: done ? FontWeight.w600 : FontWeight.w400)),
                          const Spacer(),
                          Text(done ? 'Completed' : 'Upcoming',
                              style: AppText.body(11.5,
                                  c: done ? AppColors.success : AppColors.muted)),
                        ],
                      ),
                    );
                  }),
                  if (i != milestones.length - 1)
                    const Divider(height: 1, color: AppColors.line),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 14. SANKALP HISTORY ─────────────────────────
class SankalpHistoryScreen extends StatefulWidget {
  const SankalpHistoryScreen({super.key});
  @override
  State<SankalpHistoryScreen> createState() => _SankalpHistoryScreenState();
}

class _SankalpHistoryScreenState extends State<SankalpHistoryScreen> {
  DateTime _month = DateTime(2026, 10);
  int _selected = 6;

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
  ];

  bool _done(int day) {
    if (_month.year == 2026 && _month.month == 10) return day <= 9;
    if (_month.year == 2026 && _month.month == 9) return day >= 24;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = DateTime(_month.year, _month.month, 1).weekday - 1; // Mon=0
    final cells = <int?>[
      for (var i = 0; i < offset; i++) null,
      for (var d = 1; d <= daysInMonth; d++) d,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final today = DateTime(2026, 10, 10);
    return DevScaffold(
      title: 'Sankalp History',
      bottom: null,
      body: Column(
        children: [
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() {
                  _month = DateTime(_month.year, _month.month - 1);
                  _selected = 1;
                }),
              ),
              Text('${_monthNames[_month.month - 1]} ${_month.year}',
                  style: AppText.display(18, c: AppColors.ink)),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => setState(() {
                  _month = DateTime(_month.year, _month.month + 1);
                  _selected = 1;
                }),
              ),
            ],
          ),
          Row(
            children: [
              for (final w in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                Expanded(
                  child: Center(
                      child: Text(w,
                          style: AppText.body(10.5, c: AppColors.muted))),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (var r = 0; r < cells.length / 7; r++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  for (var c = 0; c < 7; c++)
                    Expanded(child: _cell(cells[r * 7 + c], today)),
                ],
              ),
            ),
          const SizedBox(height: 18),
          DevCard(
            child: Column(
              children: [
                Text('$_selected ${_monthNames[_month.month - 1]} ${_month.year}',
                    style: AppText.body(14, w: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                    _done(_selected)
                        ? '${216} Naam completed'
                        : 'No Naam written',
                    style: AppText.body(13, c: AppColors.muted)),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'View Details',
                  onTap: () => showDemoSnack(
                      context, 'Daily detail view comes in the MVP phase'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(int? day, DateTime today) {
    if (day == null) return const SizedBox(height: 36);
    final done = _done(day);
    final sel = day == _selected;
    final isToday =
        today.year == _month.year && today.month == _month.month && today.day == day;
    return GestureDetector(
      onTap: () => setState(() => _selected = day),
      child: Center(
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: sel
                ? AppColors.success
                : done
                    ? AppColors.success.o(0.15)
                    : Colors.transparent,
            border: isToday
                ? Border.all(color: AppColors.maroon, width: 1.4)
                : null,
          ),
          child: Text('$day',
              style: AppText.body(12.5,
                  c: sel
                      ? Colors.white
                      : done
                          ? AppColors.success
                          : AppColors.ink,
                  w: done || sel ? FontWeight.w600 : FontWeight.w400)),
        ),
      ),
    );
  }
}

// ───────────────────────── 15. MY SANKALPS ─────────────────────────
class MySankalpsScreen extends StatelessWidget {
  const MySankalpsScreen({super.key});

  Widget _item(BuildContext context, Deity d, String title, int done, int total,
      {bool complete = false}) {
    final pct = done / total;
    return DevCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      onTap: () => Navigator.pushNamed(
          context, complete ? '/completion' : '/progress'),
      child: Row(
        children: [
          DeityAvatar(deity: d, size: 56, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppText.hindi(16, c: AppColors.maroon)),
                const SizedBox(height: 2),
                Text('${fmt(done)} / ${fmt(total)}',
                    style: AppText.body(12.5, w: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: GradientProgress(value: pct, height: 7)),
                    const SizedBox(width: 8),
                    Text('${(pct * 100).round()}%',
                        style: AppText.body(11, c: AppColors.muted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 10),
        child: Text(t, style: AppText.display(16, c: AppColors.ink)),
      );

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      title: 'My Sankalps',
      bottom: PrimaryButton(
        label: 'New Sankalp',
        leading: Icons.add_rounded,
        onTap: () => Navigator.pushNamed(context, '/library'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Active'),
          _item(context, deities[0], 'राम नाम', AppState.written, 21000),
          _item(context, deities[1], 'राधा नाम', 1250, 5000),
          const SizedBox(height: 8),
          _label('Completed'),
          _item(context, deities[3], 'शिव नाम', 11000, 11000, complete: true),
        ],
      ),
    );
  }
}
