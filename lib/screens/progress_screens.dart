import 'package:flutter/material.dart';
import 'package:sankalp/features/home/data/sankalp_progress_repository.dart';
import 'package:sankalp/features/home/data/user_sankalp_repository.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

// ───────────────────────── 13. PROGRESS DASHBOARD ─────────────────────────

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  bool _isLoading = true;
  String? _error;

  int _written = 0;
  double _dailyAverage = 0;

  final List<int> _milestones = [1008, 5000, 11000, 21000];

  final Map<String, int> _progressByDate = {};

  DateTime _month = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  int get _selectedDayCount {
    return _progressByDate[_dateKey(_selectedDate)] ?? 0;
  }

  Future<void> _loadProgress() async {
    final sankalpId = AppState.createdSankalpId;

    if (sankalpId == null || sankalpId <= 0) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Sankalp not found. Please create your Sankalp first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Overall completed count from My Sankalps API.
      final sankalps = await UserSankalpRepository.fetchMySankalps();

      final matchingSankalp = sankalps.firstWhere(
        (item) => int.tryParse(item['id'].toString()) == sankalpId,
        orElse: () => <String, dynamic>{},
      );

      if (matchingSankalp.isEmpty) {
        throw Exception('Sankalp not found in your Sankalp list.');
      }

      final totalWritten =
          int.tryParse(matchingSankalp['completed_count'].toString()) ?? 0;

      // Daily progress records.
      final records =
          await SankalpProgressRepository.fetchProgressHistory(sankalpId);

      final Map<String, int> progress = {};

      var dailyTotal = 0;
      final activeDates = <String>{};

      for (final record in records) {
        final date = record['progress_date']?.toString().trim();

        if (date == null || date.isEmpty) continue;

        final count = int.tryParse(record['count'].toString()) ?? 0;

        progress[date] = (progress[date] ?? 0) + count;

        dailyTotal += count;

        if (count > 0) {
          activeDates.add(date);
        }
      }

      final average =
          activeDates.isEmpty ? 0.0 : dailyTotal / activeDates.length;

      DateTime? latestDate;

      if (progress.isNotEmpty) {
        final availableDates = progress.keys
            .map((date) => DateTime.tryParse(date))
            .whereType<DateTime>()
            .toList();

        if (availableDates.isNotEmpty) {
          availableDates.sort((a, b) => a.compareTo(b));
          latestDate = availableDates.last;
        }
      }

      if (!mounted) return;

      setState(() {
        _written = totalWritten;
        _dailyAverage = average;

        _progressByDate
          ..clear()
          ..addAll(progress);

        // Select latest date having recorded progress.
        if (latestDate != null) {
          _selectedDate = latestDate;
          _month = DateTime(latestDate.year, latestDate.month);
        }

        _isLoading = false;
        AppState.written = totalWritten;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _changeMonth(int amount) {
    setState(() {
      _month = DateTime(_month.year, _month.month + amount);

      final daysInMonth = DateTime(
        _month.year,
        _month.month + 1,
        0,
      ).day;

      final day =
          _selectedDate.day > daysInMonth ? daysInMonth : _selectedDate.day;

      _selectedDate = DateTime(_month.year, _month.month, day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final deity = AppState.deity;
    final target = AppState.target > 0 ? AppState.target : 0;

    final pct =
        target > 0 ? (_written / target).clamp(0.0, 1.0).toDouble() : 0.0;

    return DevScaffold(
      title: 'Your Sankalp',
      showBack: false,
      navIndex: 2,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _loadProgress,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 4),

                      Text(
                        deity != null ? 'श्री ${deity.hi}' : 'Your Sankalp',
                        textAlign: TextAlign.center,
                        style: AppText.hindi(38),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '${fmt(_written)} / ${fmt(target)}',
                        textAlign: TextAlign.center,
                        style: AppText.body(16, w: FontWeight.w600),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: GradientProgress(
                              value: pct,
                              height: 11,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${(pct * 100).round()}%',
                            style: AppText.body(
                              12.5,
                              c: AppColors.maroon,
                              w: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Expanded(
                            child: StatBox(label: 'Started', value: '—'),
                          ),
                          Expanded(
                            child: StatBox(label: 'Streak', value: '—'),
                          ),
                          Expanded(
                            child: StatBox(
                              label: 'Daily Avg',
                              value: fmt(_dailyAverage.round()),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // DAILY HISTORY SECTION
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Daily History',
                          style: AppText.display(18),
                        ),
                      ),

                      const SizedBox(height: 10),

                      _historyCalendar(),

                      const SizedBox(height: 22),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Milestones',
                          style: AppText.display(18),
                        ),
                      ),

                      const SizedBox(height: 10),

                      DevCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < _milestones.length; i++) ...[
                              _milestoneItem(_milestones[i]),
                              if (i != _milestones.length - 1)
                                const Divider(
                                  height: 1,
                                  color: AppColors.line,
                                ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Pull down to refresh your progress.',
                        textAlign: TextAlign.center,
                        style: AppText.body(11, c: AppColors.muted),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _historyCalendar() {
    final daysInMonth = DateTime(
      _month.year,
      _month.month + 1,
      0,
    ).day;

    final offset = DateTime(
          _month.year,
          _month.month,
          1,
        ).weekday -
        1;

    final cells = <int?>[
      for (var i = 0; i < offset; i++) null,
      for (var day = 1; day <= daysInMonth; day++) day,
    ];

    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final today = DateTime.now();

    return DevCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                '${_monthNames[_month.month - 1]} ${_month.year}',
                style: AppText.display(16, c: AppColors.ink),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          Row(
            children: [
              for (final weekday in [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun',
              ])
                Expanded(
                  child: Center(
                    child: Text(
                      weekday,
                      style: AppText.body(10.5, c: AppColors.muted),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (var row = 0; row < cells.length / 7; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: _historyCell(
                        cells[row * 7 + col],
                        today,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Naam completed',
                style: AppText.body(10.5, c: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 14),
          Text(
            '${_selectedDate.day} '
            '${_monthNames[_selectedDate.month - 1]} '
            '${_selectedDate.year}',
            style: AppText.body(14, w: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          Text(
            _selectedDayCount > 0
                ? '${fmt(_selectedDayCount)} Naam completed'
                : 'No Naam written',
            style: AppText.body(13, c: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _historyCell(int? day, DateTime today) {
    if (day == null) {
      return const SizedBox(height: 38);
    }

    final date = DateTime(_month.year, _month.month, day);
    final count = _progressByDate[_dateKey(date)] ?? 0;

    final done = count > 0;

    final selected = date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;

    final isToday = today.year == date.year &&
        today.month == date.month &&
        today.day == date.day;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      child: Center(
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? AppColors.success
                : done
                    ? AppColors.success.o(0.15)
                    : Colors.transparent,
            border: isToday
                ? Border.all(
                    color: AppColors.maroon,
                    width: 1.4,
                  )
                : null,
          ),
          child: Text(
            '$day',
            style: AppText.body(
              12.5,
              c: selected
                  ? Colors.white
                  : done
                      ? AppColors.success
                      : AppColors.ink,
              w: done || selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _milestoneItem(int milestone) {
    final done = _written >= milestone;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: done ? AppColors.success : AppColors.gold,
          ),
          const SizedBox(width: 12),
          Text(
            fmt(milestone),
            style: AppText.body(
              14.5,
              w: done ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const Spacer(),
          Text(
            done ? 'Completed' : 'Upcoming',
            style: AppText.body(
              11.5,
              c: done ? AppColors.success : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: AppColors.maroon,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unable to load progress.',
              textAlign: TextAlign.center,
              style: AppText.body(14, c: AppColors.muted),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Try Again',
              onTap: _loadProgress,
            ),
          ],
        ),
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
  DateTime _month = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = true;
  String? _error;

  final Map<String, int> _progressByDate = {};

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> _loadHistory() async {
    final sankalpId = AppState.createdSankalpId;

    if (sankalpId == null || sankalpId <= 0) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Sankalp not found. Please create your Sankalp first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final records =
          await SankalpProgressRepository.fetchProgressHistory(sankalpId);

      final Map<String, int> progress = {};

      for (final record in records) {
        final date = record['progress_date']?.toString().trim();

        if (date == null || date.isEmpty) continue;

        final count = int.tryParse(record['count'].toString()) ?? 0;

        progress[date] = (progress[date] ?? 0) + count;
      }

      if (!mounted) return;

      setState(() {
        _progressByDate
          ..clear()
          ..addAll(progress);

        // Automatically select the latest date with recorded progress.
        if (progress.isNotEmpty) {
          final availableDates = progress.keys
              .map((date) => DateTime.tryParse(date))
              .whereType<DateTime>()
              .toList();

          if (availableDates.isNotEmpty) {
            availableDates.sort((a, b) => a.compareTo(b));

            final latestDate = availableDates.last;

            _selectedDate = latestDate;
            _month = DateTime(latestDate.year, latestDate.month);
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int get _selectedDayCount {
    return _progressByDate[_dateKey(_selectedDate)] ?? 0;
  }

  void _changeMonth(int amount) {
    setState(() {
      _month = DateTime(_month.year, _month.month + amount);

      final daysInMonth = DateTime(
        _month.year,
        _month.month + 1,
        0,
      ).day;

      final day =
          _selectedDate.day > daysInMonth ? daysInMonth : _selectedDate.day;

      _selectedDate = DateTime(_month.year, _month.month, day);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return DevScaffold(
        title: 'Sankalp History',
        bottom: null,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return DevScaffold(
        title: 'Sankalp History',
        bottom: null,
        body: _errorView(),
      );
    }

    final daysInMonth = DateTime(
      _month.year,
      _month.month + 1,
      0,
    ).day;

    final offset = DateTime(
          _month.year,
          _month.month,
          1,
        ).weekday -
        1;

    final cells = <int?>[
      for (var i = 0; i < offset; i++) null,
      for (var day = 1; day <= daysInMonth; day++) day,
    ];

    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final today = DateTime.now();

    return DevScaffold(
      title: 'Sankalp History',
      bottom: null,
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '${_monthNames[_month.month - 1]} ${_month.year}',
                  style: AppText.display(18, c: AppColors.ink),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            Row(
              children: [
                for (final weekday in [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun',
                ])
                  Expanded(
                    child: Center(
                      child: Text(
                        weekday,
                        style: AppText.body(10.5, c: AppColors.muted),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (var row = 0; row < cells.length / 7; row++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(
                        child: _cell(
                          cells[row * 7 + col],
                          today,
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            DevCard(
              child: Column(
                children: [
                  Text(
                    '${_selectedDate.day} '
                    '${_monthNames[_selectedDate.month - 1]} '
                    '${_selectedDate.year}',
                    style: AppText.body(14, w: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedDayCount > 0
                        ? '${fmt(_selectedDayCount)} Naam completed'
                        : 'No Naam written',
                    style: AppText.body(13, c: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'View Details',
                    onTap: () {
                      if (_selectedDayCount > 0) {
                        showDemoSnack(
                          context,
                          '${fmt(_selectedDayCount)} Naam completed on this day.',
                        );
                      } else {
                        showDemoSnack(
                          context,
                          'No Naam progress recorded for this day.',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: AppColors.maroon,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unable to load history.',
              textAlign: TextAlign.center,
              style: AppText.body(14, c: AppColors.muted),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Try Again',
              onTap: _loadHistory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(int? day, DateTime today) {
    if (day == null) {
      return const SizedBox(height: 36);
    }

    final date = DateTime(_month.year, _month.month, day);
    final done = (_progressByDate[_dateKey(date)] ?? 0) > 0;

    final selected = date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;

    final isToday = today.year == date.year &&
        today.month == date.month &&
        today.day == date.day;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      child: Center(
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? AppColors.success
                : done
                    ? AppColors.success.o(0.15)
                    : Colors.transparent,
            border: isToday
                ? Border.all(
                    color: AppColors.maroon,
                    width: 1.4,
                  )
                : null,
          ),
          child: Text(
            '$day',
            style: AppText.body(
              12.5,
              c: selected
                  ? Colors.white
                  : done
                      ? AppColors.success
                      : AppColors.ink,
              w: done || selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── 15. MY SANKALPS ─────────────────────────

class MySankalpsScreen extends StatefulWidget {
  const MySankalpsScreen({super.key});

  @override
  State<MySankalpsScreen> createState() => _MySankalpsScreenState();
}

class _MySankalpsScreenState extends State<MySankalpsScreen> {
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _sankalps = [];

  @override
  void initState() {
    super.initState();
    _loadSankalps();
  }

  Future<void> _loadSankalps() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await UserSankalpRepository.fetchMySankalps();

      debugPrint('SANKALP API COUNT: ${result.length}');
      debugPrint('SANKALP API DATA: $result');

      debugPrint(
        'ACTIVE SANKALPS: ${result.where((item) => item['status']?.toString() == 'active').length}',
      );

      debugPrint(
        'COMPLETED SANKALPS: ${result.where((item) => item['status']?.toString() == 'completed').length}',
      );

      if (!mounted) return;

      setState(() {
        _sankalps = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Deity _getDeity(Map<String, dynamic> sankalp) {
    final naam = sankalp['naam'] is Map
        ? Map<String, dynamic>.from(sankalp['naam'])
        : <String, dynamic>{};

    final icon = naam['icon']?.toString();

    String? imageUrl;

    if (icon != null && icon.isNotEmpty) {
      imageUrl = icon.startsWith('http')
          ? icon
          : 'https://sankalp.premierwebtechservices.com/storage/$icon';
    }

    return Deity(
      _intValue(naam['id']).toString(),
      naam['name_hindi']?.toString() ?? '',
      naam['name']?.toString() ?? 'Naam',
      'ॐ',
      AppColors.maroon,
      AppColors.gold,
      imageUrl: imageUrl,
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Text(
        text,
        style: AppText.display(16, c: AppColors.ink),
      ),
    );
  }

  Widget _item(Map<String, dynamic> sankalp) {
    final naam = sankalp['naam'] is Map
        ? Map<String, dynamic>.from(sankalp['naam'])
        : <String, dynamic>{};

    final total = _intValue(sankalp['target_count']);
    final completed = _intValue(sankalp['completed_count']);

    final safeTotal = total > 0 ? total : 0;
    final safeDone = completed.clamp(0, safeTotal);

    final percentage =
        safeTotal > 0 ? (safeDone / safeTotal).clamp(0.0, 1.0).toDouble() : 0.0;

    final hindiName = naam['name_hindi']?.toString() ?? '';
    final englishName = naam['name']?.toString() ?? 'Naam';

    final title = hindiName.isNotEmpty ? '$hindiName नाम' : '$englishName Naam';

    final status = sankalp['status']?.toString() ?? 'active';
    final isCompleted = status == 'completed';

    final deity = _getDeity(sankalp);

    return DevCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      onTap: () {
        AppState.createdSankalpId = _intValue(sankalp['id']);
        AppState.target = total;
        AppState.written = completed;
        AppState.deity = deity;

        Navigator.pushNamed(
          context,
          isCompleted ? '/completion' : '/progress',
        );
      },
      child: Row(
        children: [
          DeityAvatar(
            deity: deity,
            size: 56,
            radius: 10,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.hindi(16, c: AppColors.maroon),
                ),
                const SizedBox(height: 2),
                Text(
                  '${fmt(safeDone)} / ${fmt(safeTotal)}',
                  style: AppText.body(12.5, w: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: GradientProgress(
                        value: percentage,
                        height: 7,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(percentage * 100).round()}%',
                      style: AppText.body(11, c: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_rounded,
              size: 44,
              color: AppColors.maroon,
            ),
            const SizedBox(height: 12),
            Text(
              'You have not created any Sankalp yet.',
              textAlign: TextAlign.center,
              style: AppText.body(14, c: AppColors.muted),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Choose Naam',
              trailing: Icons.arrow_forward_rounded,
              onTap: () => Navigator.pushNamed(context, '/library'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 42,
              color: AppColors.maroon,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unable to load Sankalps.',
              textAlign: TextAlign.center,
              style: AppText.body(14, c: AppColors.muted),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Try Again',
              onTap: _loadSankalps,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSankalps = _sankalps
        .where((item) => item['status']?.toString() == 'active')
        .toList();

    final completedSankalps = _sankalps
        .where((item) => item['status']?.toString() == 'completed')
        .toList();

    debugPrint('ACTIVE SANKALPS: ${activeSankalps.length}');
    debugPrint('COMPLETED SANKALPS: ${completedSankalps.length}');

    return DevScaffold(
      title: 'My Sankalps',
      scroll: false,
      bottom: PrimaryButton(
        label: 'New Sankalp',
        leading: Icons.add_rounded,
        onTap: () => Navigator.pushNamed(context, '/library'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : _sankalps.isEmpty
                  ? _emptyView()
                  : RefreshIndicator(
                      onRefresh: _loadSankalps,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (activeSankalps.isNotEmpty) ...[
                            _label('Active'),
                            for (final sankalp in activeSankalps)
                              _item(sankalp),
                          ],
                          if (completedSankalps.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _label('Completed'),
                            for (final sankalp in completedSankalps)
                              _item(sankalp),
                          ],
                        ],
                      ),
                    ),
    );
  }
}
