import 'package:flutter/material.dart';
import '../core/services/app_services.dart';
import '../core/services/notification_service.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

// ───────────────────────── 17. NOTIFICATION SETTINGS ─────────────────────────

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  int _sel = 0;
  TimeOfDay _custom = const TimeOfDay(hour: 21, minute: 0);

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedReminder();
  }

  // Load reminder from Laravel API first.
  // If API fails, use existing local SharedPreferences data.
  Future<void> _loadSavedReminder() async {
    try {
      final response = await AppServices.api.dio.get('/reminders');

      final responseData = response.data;

      if (responseData is Map && responseData['success'] == true) {
        final data = responseData['data'];

        if (data is List && data.isNotEmpty && data.first is Map) {
          final reminder = data.first as Map;

          final reminderTime = reminder['reminder_time']?.toString();

          if (reminderTime != null && reminderTime.contains(':')) {
            final parts = reminderTime.split(':');

            final hour = int.tryParse(parts[0]);
            final minute = int.tryParse(parts[1]);

            if (hour != null &&
                minute != null &&
                hour >= 0 &&
                hour <= 23 &&
                minute >= 0 &&
                minute <= 59) {
              if (!mounted) return;

              setState(() {
                _setSelectedTime(hour, minute);
                _isLoading = false;
              });

              return;
            }
          }
        }
      }

      // API response invalid or empty: use local fallback.
      await _loadLocalReminder();
    } catch (e) {
      // API unavailable: use locally saved reminder.
      await _loadLocalReminder();
    }
  }

  // Load reminder from local storage.
  Future<void> _loadLocalReminder() async {
    try {
      final saved = await NotificationService.instance.getSavedReminder();

      if (!mounted) return;

      setState(() {
        _sel = saved['selection'] as int? ?? 0;

        _custom = TimeOfDay(
          hour: saved['hour'] as int? ?? 21,
          minute: saved['minute'] as int? ?? 0,
        );

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // Match API time with existing UI options.
  void _setSelectedTime(int hour, int minute) {
    if (hour == 7 && minute == 0) {
      _sel = 0;
    } else if (hour == 12 && minute == 0) {
      _sel = 1;
    } else if (hour == 19 && minute == 0) {
      _sel = 2;
    } else {
      _sel = 3;
      _custom = TimeOfDay(hour: hour, minute: minute);
    }
  }

  // Save reminder to Laravel first, then schedule local notification.
  Future<void> _saveReminder() async {
    if (_isSaving || _isLoading) return;

    setState(() {
      _isSaving = true;
    });

    int hour;
    int minute;

    switch (_sel) {
      case 0:
        hour = 7;
        minute = 0;
        break;

      case 1:
        hour = 12;
        minute = 0;
        break;

      case 2:
        hour = 19;
        minute = 0;
        break;

      case 3:
        hour = _custom.hour;
        minute = _custom.minute;
        break;

      default:
        hour = 7;
        minute = 0;
    }

    try {
      // Format required by Laravel: HH:mm
      final reminderTime = '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}';

      // Step 1: Save reminder settings in Laravel.
      final response = await AppServices.api.dio.put(
        '/reminders',
        data: {
          'reminder_time': reminderTime,
          'timezone': 'Asia/Kolkata',
          'is_enabled': true,
        },
      );

      // debugPrint('REMINDER API STATUS: ${response.statusCode}');
      // debugPrint('REMINDER API TYPE: ${response.data.runtimeType}');
      // debugPrint('REMINDER API RESPONSE: ${response.data}');

      final responseData = response.data;

      if (responseData is! Map || responseData['success'] != true) {
        throw Exception(
          'Reminder API returned unexpected response: $responseData',
        );
      }

      // Step 2: Schedule local notification only after API success.
      final localSuccess = await NotificationService.instance.saveDailyReminder(
        selection: _sel,
        hour: hour,
        minute: minute,
      );

      if (!mounted) return;

      if (localSuccess) {
        showDemoSnack(context, 'Daily reminder saved 🙏');
        Navigator.maybePop(context);
      } else {
        showDemoSnack(
          context,
          'Reminder saved on server, but notifications are not allowed on this device. Please enable notification permission.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      showDemoSnack(
        context,
        'Unable to save reminder. Please check your internet connection and try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      title: 'Daily Reminder',
      subtitle: 'दैनिक समय',
      bottom: PrimaryButton(
        label: _isSaving ? 'Saving...' : 'Save Reminder',
        onTap: _isSaving || _isLoading ? () {} : _saveReminder,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.goldLight.o(0.35),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              size: 44,
              color: AppColors.maroon,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A gentle reminder to write your Naam each day.',
            textAlign: TextAlign.center,
            style: AppText.body(
              12.5,
              c: AppColors.muted,
            ),
          ),
          const SizedBox(height: 22),
          SelectTile(
            label: 'Morning – 7:00 AM',
            selected: _sel == 0,
            onTap: () => setState(() => _sel = 0),
          ),
          SelectTile(
            label: 'Afternoon – 12:00 PM',
            selected: _sel == 1,
            onTap: () => setState(() => _sel = 1),
          ),
          SelectTile(
            label: 'Evening – 7:00 PM',
            selected: _sel == 2,
            onTap: () => setState(() => _sel = 2),
          ),
          SelectTile(
            label: 'Custom Time',
            trailing: _sel == 3 ? _custom.format(context) : null,
            selected: _sel == 3,
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _custom,
              );

              if (time != null && mounted) {
                setState(() {
                  _sel = 3;
                  _custom = time;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
// ───────────────────────── 17. NOTIFICATION SETTINGS ─────────────────────────

// ───────────────────────── 23. PROFILE / SETTINGS ─────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Load authenticated user's profile from Laravel.
  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final profile = await AppServices.auth.fetchProfile();

      if (!mounted) return;

      final name = profile['name']?.toString().trim() ?? '';

      setState(() {
        _profile = profile;
        _isLoading = false;
      });

      // Keep existing local app name in sync.
      if (name.isNotEmpty) {
        AppState.name = name;
        await AppServices.session.setUserName(name);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Unable to load profile. Please try again.';
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await AppServices.auth.logout();
    } catch (_) {
      // Offline / expired token: still log out on this device.
    }

    await AppServices.session.clearUser();
    AppState.name = 'Devotee';

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/account',
        (r) => false,
      );
    }
  }

  Widget _row(
    BuildContext context,
    IconData icon,
    String label, {
    String? value,
    String? route,
    bool danger = false,
  }) {
    return InkWell(
      onTap: () {
        if (route == '/account') {
          _logout(context);
        } else if (route != null) {
          Navigator.pushNamed(context, route);
        } else {
          showDemoSnack(context, '$label – coming soon');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 21,
              color: danger ? Colors.red.shade700 : AppColors.maroon,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppText.body(
                  14,
                  c: danger ? Colors.red.shade700 : AppColors.ink,
                  w: FontWeight.w500,
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: AppText.body(12.5, c: AppColors.muted),
              ),
            if (!danger)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _profileAvatar(String name, String? avatarUrl) {
    final hasAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;

    return Container(
      width: 84,
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.goldLight, AppColors.gold],
        ),
        border: Border.all(
          color: AppColors.maroon,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: hasAvatar
            ? Image.network(
                avatarUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'D',
                      style: AppText.display(38, c: AppColors.maroon),
                    ),
                  );
                },
              )
            : Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'D',
                  style: AppText.display(38, c: AppColors.maroon),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const div = Divider(height: 1, color: AppColors.line);

    final name = _profile?['name']?.toString().trim().isNotEmpty == true
        ? _profile!['name'].toString().trim()
        : 'Devotee';

    final email = _profile?['email']?.toString() ?? '';
    final phone = _profile?['phone']?.toString() ?? '';
    final avatar = _profile?['avatar']?.toString();

    final language = AppServices.session.language == 'hi' ? 'Hindi' : 'English';

    return DevScaffold(
      title: 'Profile',
      showBack: false,
      navIndex: 4,
      body: Column(
        children: [
          const SizedBox(height: 4),

          // Profile avatar from API.
          _profileAvatar(name, avatar),

          const SizedBox(height: 10),

          // Dynamic name.
          Text(
            name,
            style: AppText.display(22),
          ),

          // Dynamic email.
          Text(
            email.isNotEmpty ? email : 'Email not added',
            style: AppText.body(12.5, c: AppColors.muted),
          ),

          if (phone.isNotEmpty)
            Text(
              phone,
              style: AppText.body(12, c: AppColors.muted),
            ),

          if (_isLoading) ...[
            const SizedBox(height: 8),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppText.body(12, c: Colors.red),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: _loadProfile,
              child: const Text('Retry'),
            ),
          ],

          const SizedBox(height: 12),

          // Edit Profile option.
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/profile-update').then((_) {
                if (mounted) {
                  _loadProfile();
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: AppColors.goldLight.o(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.maroon,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Edit Profile',
                    style: AppText.body(
                      13,
                      c: AppColors.maroon,
                      w: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.maroon,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Existing menu items remain unchanged.
          DevCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _row(
                  context,
                  Icons.auto_stories_rounded,
                  'My Sankalps',
                  route: '/my-sankalps',
                ),
                div,
                _row(
                  context,
                  Icons.shopping_bag_outlined,
                  'My Purchases',
                  route: '/purchases',
                ),
                div,
                _row(
                  context,
                  Icons.notifications_none_rounded,
                  'Notifications',
                  route: '/notifications',
                ),
                div,
                _row(
                  context,
                  Icons.language_rounded,
                  'Language',
                  value: language,
                ),
                div,
                _row(
                  context,
                  Icons.family_restroom_rounded,
                  'Family Sankalp',
                  route: '/family',
                ),
                div,
                _row(
                  context,
                  Icons.help_outline_rounded,
                  'Help & Support',
                ),
                div,
                _row(
                  context,
                  Icons.privacy_tip_outlined,
                  'Terms & Privacy',
                ),
                div,
                _row(
                  context,
                  Icons.info_outline_rounded,
                  'About',
                ),
                div,
                _row(
                  context,
                  Icons.logout_rounded,
                  'Logout',
                  route: '/account',
                  danger: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileUpdateScreen extends StatefulWidget {
  const ProfileUpdateScreen({super.key});

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _email = '';
  String _phone = '';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AppServices.auth.fetchProfile();

      if (!mounted) return;

      setState(() {
        _nameController.text = profile['name']?.toString() ?? '';
        _email = profile['email']?.toString() ?? '';
        _phone = profile['phone']?.toString() ?? '';
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Unable to load profile. Please try again.';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      await AppServices.auth.updateName(name);

      AppState.name = name;
      await AppServices.session.setUserName(name);

      if (!mounted) return;

      showDemoSnack(context, 'Profile updated successfully.');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      showDemoSnack(
        context,
        'Unable to update profile. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _readOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.body(
            13,
            c: AppColors.ink,
            w: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: AppColors.goldLight.o(0.18),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: AppColors.muted),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  value.isNotEmpty ? value : 'Not added',
                  style: AppText.body(13, c: AppColors.muted),
                ),
              ),
              const Icon(
                Icons.lock_outline_rounded,
                size: 17,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      title: 'Edit Profile',
      subtitle: 'अपनी जानकारी अपडेट करें',
      bottom: PrimaryButton(
        label: _isSaving ? 'Saving...' : 'Save Changes',
        onTap: _isLoading || _isSaving ? () {} : _saveProfile,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppText.body(13, c: Colors.red),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _loadProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.goldLight,
                                AppColors.gold,
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.maroon,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _nameController.text.trim().isNotEmpty
                                  ? _nameController.text.trim()[0].toUpperCase()
                                  : 'D',
                              style: AppText.display(
                                34,
                                c: AppColors.maroon,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Personal Information',
                        style: AppText.display(18),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Full Name',
                        style: AppText.body(
                          13,
                          c: AppColors.ink,
                          w: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: const BorderSide(
                              color: AppColors.line,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: const BorderSide(
                              color: AppColors.line,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: const BorderSide(
                              color: AppColors.maroon,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final name = value?.trim() ?? '';

                          if (name.isEmpty) {
                            return 'Please enter your name.';
                          }

                          if (name.length < 2) {
                            return 'Name must be at least 2 characters.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _readOnlyField(
                        label: 'Email Address',
                        value: _email,
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 18),
                      _readOnlyField(
                        label: 'Phone Number',
                        value: _phone,
                        icon: Icons.phone_outlined,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Email and phone number changes will be available '
                        'after secure verification.',
                        style: AppText.body(
                          12,
                          c: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}

// ───────────────────────── 24. FAMILY SANKALP (Premium) ─────────────────────────
class FamilySankalpScreen extends StatelessWidget {
  const FamilySankalpScreen({super.key});

  static const _members = [
    ('Mother', 10000, Color(0xFFD9708F)),
    ('Father', 15000, Color(0xFF4F8FD6)),
    ('Daughter', 5000, Color(0xFFE2791B)),
    ('Son', 5000, Color(0xFF2E7D32)),
  ];

  @override
  Widget build(BuildContext context) {
    const total = 100000;
    final done = _members.fold<int>(0, (a, m) => a + m.$2);
    final pct = done / total;
    return DevScaffold(
      title: 'Family Sankalp',
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('PRO',
              style: AppText.body(10, c: Colors.white, w: FontWeight.w700)),
        ),
      ],
      bottom: PrimaryButton(
        label: 'Invite Family Members',
        leading: Icons.person_add_alt_1_rounded,
        onTap: () => showDemoSnack(context, 'Invite link copied (demo)'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          SizedBox(
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (var i = 0; i < _members.length; i++)
                  Transform.translate(
                    offset: Offset((i - 1.5) * 52.0, 0),
                    child: Container(
                      width: 62,
                      height: 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _members[i].$3,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Text(_members[i].$1[0],
                          style: AppText.display(24, c: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text('Sharma Family', style: AppText.display(24)),
          const SizedBox(height: 14),
          Text('${fmt(done)} / ${fmt(total)}',
              style: AppText.body(16, w: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: GradientProgress(value: pct, height: 10)),
              const SizedBox(width: 10),
              Text('${(pct * 100).round()}%',
                  style: AppText.body(12.5,
                      c: AppColors.maroon, w: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Contributions', style: AppText.display(17)),
          ),
          const SizedBox(height: 10),
          DevCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < _members.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: _members[i].$3,
                          child: Text(_members[i].$1[0],
                              style: AppText.body(12,
                                  c: Colors.white, w: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        Text(_members[i].$1,
                            style: AppText.body(14, w: FontWeight.w500)),
                        const Spacer(),
                        Text(fmt(_members[i].$2),
                            style: AppText.body(14,
                                c: AppColors.maroon, w: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (i != _members.length - 1)
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
