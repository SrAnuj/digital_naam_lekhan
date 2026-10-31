import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'package:sankalp/features/home/data/home_repository.dart';
import 'package:sankalp/features/home/data/naam_library_repository.dart';

// ───────────────────────── 5. HOME DASHBOARD ─────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _homeLoading = true;
  bool _homeLoaded = false;
  String? _homeError;

  String _displayName = AppState.name;
  Map<String, dynamic>? _currentSankalp;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome() async {
    if (mounted) {
      setState(() {
        _homeLoading = true;
        _homeError = null;
      });
    }

    try {
      final data = await HomeRepository.fetchHome();

      if (!mounted) return;

      final userData = data['user'];
      final sankalpData = data['current_sankalp'];

      setState(() {
        if (userData is Map) {
          final name = userData['name']?.toString().trim();

          if (name != null && name.isNotEmpty) {
            _displayName = name;
          }
        }

        _currentSankalp =
            sankalpData is Map ? Map<String, dynamic>.from(sankalpData) : null;

        _homeLoaded = true;
        _homeLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _homeError = e.toString().replaceFirst('Exception: ', '');
        _homeLoading = false;
      });
    }
  }

  Widget _quick(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return Expanded(
      child: DevCard(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        onTap: () => Navigator.pushNamed(context, route),
        child: Column(
          children: [
            Icon(icon, color: AppColors.maroon, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.body(11, w: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = AppState.deity;
    final sankalp = _currentSankalp;
    final hasActiveSankalp = _homeLoaded && sankalp != null;

    final naamHindi = sankalp?['name_hindi']?.toString().trim();
    final displayNaam =
        naamHindi != null && naamHindi.isNotEmpty ? naamHindi : (d?.hi ?? '');

    final target = _homeLoaded
        ? (sankalp?['target_count'] as num?)?.toInt() ?? 0
        : AppState.target;

    final written = _homeLoaded
        ? (sankalp?['completed_count'] as num?)?.toInt() ?? 0
        : AppState.written;

    final safeTarget = target > 0 ? target : 0;
    final safeWritten = written.clamp(0, safeTarget);

    final pct = safeTarget > 0
        ? (safeWritten / safeTarget).clamp(0.0, 1.0).toDouble()
        : 0.0;

    final trimmedName = _displayName.trim();
    final initial = trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : 'U';

    return Scaffold(
      body: DevBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 70),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.maroonDark,
                            AppColors.maroon,
                          ],
                        ),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(28),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.goldLight,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  initial,
                                  style: AppText.display(
                                    20,
                                    c: AppColors.maroon,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Jai Shri Ram, $_displayName',
                                  style: AppText.display(
                                    18,
                                    c: Colors.white,
                                    w: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: AppColors.goldLight,
                                  size: 26,
                                ),
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/notifications',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_homeLoading)
                      const LinearProgressIndicator(
                        color: AppColors.maroon,
                        minHeight: 2,
                      ),
                    if (_homeError != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 18,
                              color: AppColors.maroon,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Could not refresh dashboard data.',
                                style: AppText.body(
                                  11,
                                  c: AppColors.muted,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _loadHome,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    Transform.translate(
                      offset: const Offset(0, -52),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            DevCard(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/progress',
                              ),
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  Text(
                                    'Your Current Sankalp',
                                    style: AppText.body(
                                      12,
                                      c: AppColors.muted,
                                      w: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _homeLoaded && !hasActiveSankalp
                                        ? 'No active Sankalp'
                                        : displayNaam.isNotEmpty
                                            ? 'श्री $displayNaam'
                                            : 'Choose your Naam',
                                    style: AppText.hindi(
                                      hasActiveSankalp || !_homeLoaded
                                          ? 34
                                          : 22,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  if (hasActiveSankalp || !_homeLoaded)
                                    Text(
                                      '${fmt(safeWritten)} / ${fmt(safeTarget)}',
                                      style: AppText.body(
                                        15,
                                        c: AppColors.ink,
                                        w: FontWeight.w600,
                                      ),
                                    )
                                  else
                                    Text(
                                      'Start a Sankalp to track your progress.',
                                      textAlign: TextAlign.center,
                                      style: AppText.body(
                                        12,
                                        c: AppColors.muted,
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GradientProgress(
                                          value: pct,
                                          height: 9,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${(pct * 100).round()}%',
                                        style: AppText.body(
                                          12,
                                          c: AppColors.maroon,
                                          w: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department_rounded,
                                        color: AppColors.saffron,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${AppState.streak} Day Streak',
                                        style: AppText.body(
                                          13,
                                          w: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            DevCard(
                              child: Column(
                                children: [
                                  Text(
                                    "Today's Goal",
                                    style: AppText.body(
                                      12.5,
                                      c: AppColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${AppState.todayGoal} Naam',
                                    style: AppText.display(22),
                                  ),
                                  const SizedBox(height: 12),
                                  PrimaryButton(
                                    label: 'Continue Writing',
                                    trailing: Icons.arrow_forward_rounded,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/writing',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _quick(
                                  context,
                                  Icons.auto_stories_rounded,
                                  'My Sankalps',
                                  '/my-sankalps',
                                ),
                                _quick(
                                  context,
                                  Icons.menu_book_rounded,
                                  'Naam Library',
                                  '/library',
                                ),
                                _quick(
                                  context,
                                  Icons.radio_button_checked,
                                  'Jap Counter',
                                  '/jap',
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            DevCard(
                              color: AppColors.creamDark.o(0.55),
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/digital-pustika',
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.card_giftcard_rounded,
                                    color: AppColors.maroon,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Gift a Naam Pustika',
                                          style: AppText.body(
                                            14,
                                            c: AppColors.maroon,
                                            w: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          'Create a personalised Pustika for someone you love.',
                                          style: AppText.body(
                                            11.5,
                                            c: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.maroon,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const AppBottomNav(index: 0),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 6. NAAM LIBRARY ─────────────────────────

class NaamLibraryScreen extends StatefulWidget {
  const NaamLibraryScreen({super.key});

  @override
  State<NaamLibraryScreen> createState() => _NaamLibraryScreenState();
}

class _NaamLibraryScreenState extends State<NaamLibraryScreen> {
  List<Deity> _deities = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDeities();
  }

  Future<void> _loadDeities() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await NaamLibraryRepository.fetchDeities();

      if (!mounted) return;

      setState(() {
        // Use API data only. No local dummy deity fallback.
        _deities = result;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _deities = [];
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      title: 'Choose Your Naam',
      subtitle: 'अपने इष्ट देव का नाम चुनें',
      showBack: false,
      navIndex: 3,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadDeities,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_deities.isEmpty) {
      return const Center(
        child: Text('No deities available from the API.'),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _deities.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final deity = _deities[index];

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            AppState.deity = deity;
            Navigator.pushNamed(context, '/naam-detail');
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return DeityAvatar(
                deity: deity,
                size: constraints.maxWidth - 8,
                showLabel: true,
              );
            },
          ),
        );
      },
    );
  }
}

// ───────────────────────── 7. NAAM DETAIL ─────────────────────────

class NaamDetailScreen extends StatefulWidget {
  const NaamDetailScreen({super.key});

  @override
  State<NaamDetailScreen> createState() => _NaamDetailScreenState();
}

class _NaamDetailScreenState extends State<NaamDetailScreen> {
  Map<String, dynamic>? _deityDetails;

  List<Map<String, dynamic>> _targets = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final deity = AppState.deity;

    if (deity == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please choose your Naam first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        NaamLibraryRepository.fetchDeityDetails(deity.id),
        NaamLibraryRepository.fetchSankalpTargets(),
      ]);

      if (!mounted) return;

      final details = results[0] as Map<String, dynamic>;
      final targets = results[1] as List<Map<String, dynamic>>;

      if (targets.isEmpty) {
        throw Exception('No Sankalp targets available.');
      }

      // Restore previously selected target.
      Map<String, dynamic>? selectedTarget;

      for (final item in targets) {
        final id = int.tryParse(item['id']?.toString() ?? '');
        final count = int.tryParse(
          item['target_count']?.toString() ?? '',
        );

        if (id == AppState.sankalpTargetId ||
            (AppState.sankalpTargetId == null && count == AppState.target)) {
          selectedTarget = item;
          break;
        }
      }

      // Select first API target if no previous selection exists.
      selectedTarget ??= targets.first;

      AppState.sankalpTargetId =
          int.tryParse(selectedTarget['id']?.toString() ?? '');

      AppState.target = int.tryParse(
            selectedTarget['target_count']?.toString() ?? '',
          ) ??
          0;

      setState(() {
        _deityDetails = details;
        _targets = targets;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _selectTarget(Map<String, dynamic> item) {
    final id = int.tryParse(item['id']?.toString() ?? '');
    final count = int.tryParse(
      item['target_count']?.toString() ?? '',
    );

    if (id == null || count == null) return;

    setState(() {
      AppState.sankalpTargetId = id;
      AppState.target = count;
    });
  }

  String? get _deityImageUrl {
    final icon = _deityDetails?['icon']?.toString().trim() ?? '';

    if (icon.isEmpty) {
      return AppState.deity?.imageUrl;
    }

    final uri = Uri.tryParse(icon);

    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty) {
      return icon;
    }

    final path = icon.startsWith('/') ? icon.substring(1) : icon;

    return 'https://sankalp.premierwebtechservices.com/storage/$path';
  }

  String get _deityHindi {
    final hindi = _deityDetails?['name_hindi']?.toString().trim() ?? '';

    return hindi.isNotEmpty ? hindi : AppState.deity?.hi ?? '';
  }

  Widget _buildHero() {
    final deity = AppState.deity!;

    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.1),
          radius: 0.9,
          colors: [Colors.white, deity.c1, deity.c2],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: _deityImageUrl != null
                ? Image.network(
                    _deityImageUrl!,
                    height: 170,
                    width: 170,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return Text(
                        deity.symbol,
                        style: const TextStyle(fontSize: 110),
                      );
                    },
                  )
                : Text(
                    deity.symbol,
                    style: const TextStyle(fontSize: 110),
                  ),
          ),
          SafeArea(
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.maroon,
              ),
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetContent() {
    return Transform.translate(
      offset: const Offset(0, -28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 6),
        decoration: const BoxDecoration(
          color: AppColors.creamLight,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'श्री $_deityHindi',
                    style: AppText.hindi(36),
                  ),
                  Text(
                    '$_deityHindi नाम लेखन',
                    style: AppText.hindi(
                      17,
                      c: AppColors.maroon,
                      w: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"A simple digital practice\nfor your daily Sankalp."',
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      12,
                      c: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Choose your target',
              style: AppText.body(
                14,
                c: AppColors.ink,
                w: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'How many Naam would you like to write?',
              style: AppText.body(
                11.5,
                c: AppColors.muted,
              ),
            ),
            const SizedBox(height: 10),
            for (final t in _targets)
              SelectTile(
                label: fmt(
                  int.tryParse(
                        t['target_count']?.toString() ?? '',
                      ) ??
                      0,
                ),
                selected: AppState.sankalpTargetId ==
                    int.tryParse(t['id']?.toString() ?? ''),
                onTap: () => _selectTarget(t),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = AppState.deity;

    if (d == null) {
      return Scaffold(
        body: DevBackground(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 48,
                      color: AppColors.maroon,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Please choose your Naam first.',
                      textAlign: TextAlign.center,
                      style: AppText.body(
                        16,
                        c: AppColors.ink,
                        w: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Choose Naam',
                      trailing: Icons.arrow_forward_rounded,
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        '/library',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: DevBackground(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.maroon,
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: AppText.body(
                                    14,
                                    c: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                PrimaryButton(
                                  label: 'Retry',
                                  trailing: Icons.refresh_rounded,
                                  onTap: _loadDetails,
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildHero(),
                              _buildTargetContent(),
                            ],
                          ),
                        ),
            ),
            if (!_isLoading && _errorMessage == null)
              Container(
                color: AppColors.creamLight,
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                child: SafeArea(
                  top: false,
                  child: PrimaryButton(
                    label: 'Continue',
                    trailing: Icons.arrow_forward_rounded,
                    onTap: () {
                      if (AppState.sankalpTargetId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select a Sankalp target.',
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.pushNamed(
                        context,
                        '/create-sankalp',
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
