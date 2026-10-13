import 'package:flutter/material.dart';
import '../core/services/app_services.dart';
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

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      title: 'Daily Reminder',
      subtitle: 'दैनिक समय',
      bottom: PrimaryButton(
        label: 'Save Reminder',
        onTap: () {
          showDemoSnack(context, 'Reminder saved 🙏');
          Navigator.maybePop(context);
        },
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
            child: Icon(Icons.notifications_active_rounded,
                size: 44, color: AppColors.maroon),
          ),
          const SizedBox(height: 12),
          Text('A gentle reminder to write your Naam each day.',
              textAlign: TextAlign.center,
              style: AppText.body(12.5, c: AppColors.muted)),
          const SizedBox(height: 22),
          SelectTile(
              label: 'Morning – 7:00 AM',
              selected: _sel == 0,
              onTap: () => setState(() => _sel = 0)),
          SelectTile(
              label: 'Afternoon – 12:00 PM',
              selected: _sel == 1,
              onTap: () => setState(() => _sel = 1)),
          SelectTile(
              label: 'Evening – 7:00 PM',
              selected: _sel == 2,
              onTap: () => setState(() => _sel = 2)),
          SelectTile(
            label: 'Custom Time',
            trailing: _sel == 3 ? _custom.format(context) : null,
            selected: _sel == 3,
            onTap: () async {
              setState(() => _sel = 3);
              final t =
                  await showTimePicker(context: context, initialTime: _custom);
              if (t != null) setState(() => _custom = t);
            },
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 23. PROFILE / SETTINGS ─────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await AppServices.auth.logout();
    } catch (_) {
      // Offline / expired token: still log out on this device.
    }
    await AppServices.session.clearUser();
    AppState.name = 'Devotee';
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/account', (r) => false);
    }
  }

  Widget _row(BuildContext context, IconData icon, String label,
      {String? value, String? route, bool danger = false}) {
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                size: 21,
                color: danger ? Colors.red.shade700 : AppColors.maroon),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: AppText.body(14,
                      c: danger ? Colors.red.shade700 : AppColors.ink,
                      w: FontWeight.w500)),
            ),
            if (value != null)
              Text(value, style: AppText.body(12.5, c: AppColors.muted)),
            if (!danger)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const div = Divider(height: 1, color: AppColors.line);
    return DevScaffold(
      title: 'Profile',
      showBack: false,
      navIndex: 4,
      body: Column(
        children: [
          const SizedBox(height: 4),
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [AppColors.goldLight, AppColors.gold]),
              border: Border.all(color: AppColors.maroon, width: 2),
            ),
            child: Text(AppState.name[0],
                style: AppText.display(38, c: AppColors.maroon)),
          ),
          const SizedBox(height: 10),
          Text(AppState.name, style: AppText.display(22)),
          Text('madhvi@gmail.com',
              style: AppText.body(12.5, c: AppColors.muted)),
          const SizedBox(height: 20),
          DevCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _row(context, Icons.auto_stories_rounded, 'My Sankalps',
                    route: '/my-sankalps'),
                div,
                _row(context, Icons.shopping_bag_outlined, 'My Purchases',
                    route: '/purchases'),
                div,
                _row(context, Icons.notifications_none_rounded, 'Notifications',
                    route: '/notifications'),
                div,
                _row(context, Icons.language_rounded, 'Language',
                    value: 'English'),
                div,
                _row(context, Icons.family_restroom_rounded, 'Family Sankalp',
                    route: '/family'),
                div,
                _row(context, Icons.help_outline_rounded, 'Help & Support'),
                div,
                _row(context, Icons.privacy_tip_outlined, 'Terms & Privacy'),
                div,
                _row(context, Icons.info_outline_rounded, 'About'),
                div,
                _row(context, Icons.logout_rounded, 'Logout',
                    route: '/account', danger: true),
              ],
            ),
          ),
        ],
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
