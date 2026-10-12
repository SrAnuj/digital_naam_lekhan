import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

// ───────────────────────── 5. HOME DASHBOARD ─────────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _quick(BuildContext context, IconData icon, String label, String route) {
    return Expanded(
      child: DevCard(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        onTap: () => Navigator.pushNamed(context, route),
        child: Column(
          children: [
            Icon(icon, color: AppColors.maroon, size: 26),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: AppText.body(11, w: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = AppState.deity;
    final pct = AppState.written / AppState.target;
    return Scaffold(
      body: DevBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Maroon greeting banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 70),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.maroonDark, AppColors.maroon],
                        ),
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(28)),
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
                                      color: Colors.white, width: 1.5),
                                ),
                                child: Text(AppState.name[0],
                                    style: AppText.display(20,
                                        c: AppColors.maroon)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Jai Shri Ram, ${AppState.name}',
                                  style: AppText.display(18,
                                      c: Colors.white, w: FontWeight.w600),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.notifications_none_rounded,
                                    color: AppColors.goldLight, size: 26),
                                onPressed: () => Navigator.pushNamed(
                                    context, '/notifications'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Current sankalp card overlaps the banner
                    Transform.translate(
                      offset: const Offset(0, -52),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            DevCard(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/progress'),
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  Text('Your Current Sankalp',
                                      style: AppText.body(12,
                                          c: AppColors.muted,
                                          w: FontWeight.w500)),
                                  const SizedBox(height: 6),
                                  Text('श्री ${d.hi}',
                                      style: AppText.hindi(34)),
                                  const SizedBox(height: 4),
                                  Text(
                                      '${fmt(AppState.written)} / ${fmt(AppState.target)}',
                                      style: AppText.body(15,
                                          c: AppColors.ink,
                                          w: FontWeight.w600)),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: GradientProgress(
                                              value: pct, height: 9)),
                                      const SizedBox(width: 10),
                                      Text('${(pct * 100).round()}%',
                                          style: AppText.body(12,
                                              c: AppColors.maroon,
                                              w: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.local_fire_department_rounded,
                                          color: AppColors.saffron, size: 20),
                                      const SizedBox(width: 4),
                                      Text('${AppState.streak} Day Streak',
                                          style: AppText.body(13,
                                              w: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            DevCard(
                              child: Column(
                                children: [
                                  Text("Today's Goal",
                                      style: AppText.body(12.5,
                                          c: AppColors.muted)),
                                  const SizedBox(height: 2),
                                  Text('${AppState.todayGoal} Naam',
                                      style: AppText.display(22)),
                                  const SizedBox(height: 12),
                                  PrimaryButton(
                                    label: 'Continue Writing',
                                    trailing: Icons.arrow_forward_rounded,
                                    onTap: () => Navigator.pushNamed(
                                        context, '/writing'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _quick(context, Icons.auto_stories_rounded,
                                    'My Sankalps', '/my-sankalps'),
                                _quick(context, Icons.menu_book_rounded,
                                    'Naam Library', '/library'),
                                _quick(context, Icons.radio_button_checked,
                                    'Jap Counter', '/jap'),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Gifting moment (from the product workflow)
                            DevCard(
                              color: AppColors.creamDark.o(0.55),
                              onTap: () => Navigator.pushNamed(
                                  context, '/digital-pustika'),
                              child: Row(
                                children: [
                                  Icon(Icons.card_giftcard_rounded,
                                      color: AppColors.maroon, size: 30),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Gift a Naam Pustika',
                                            style: AppText.body(14,
                                                c: AppColors.maroon,
                                                w: FontWeight.w600)),
                                        Text(
                                            'Create a personalised Pustika for someone you love.',
                                            style: AppText.body(11.5,
                                                c: AppColors.muted)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: AppColors.maroon),
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
class NaamLibraryScreen extends StatelessWidget {
  const NaamLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      title: 'Choose Your Naam',
      subtitle: 'अपने इष्ट देव का नाम चुनें',
      showBack: false,
      navIndex: 3,
      body: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: deities.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, i) {
          final d = deities[i];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              AppState.deity = d;
              Navigator.pushNamed(context, '/naam-detail');
            },
            child: LayoutBuilder(
              builder: (context, c) => DeityAvatar(
                deity: d,
                size: c.maxWidth - 8,
                showLabel: true,
              ),
            ),
          );
        },
      ),
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
  @override
  Widget build(BuildContext context) {
    final d = AppState.deity;
    return Scaffold(
      body: DevBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Hero
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.1),
                          radius: 0.9,
                          colors: [Colors.white, d.c1, d.c2],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                              child: Text(d.symbol,
                                  style: const TextStyle(fontSize: 110))),
                          SafeArea(
                            child: IconButton(
                              icon: Icon(Icons.arrow_back_ios_new_rounded,
                                  color: AppColors.maroon),
                              onPressed: () => Navigator.maybePop(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -28),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 6),
                        decoration: const BoxDecoration(
                          color: AppColors.creamLight,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  Text('श्री ${d.hi}',
                                      style: AppText.hindi(36)),
                                  Text('${d.hi} नाम लेखन',
                                      style: AppText.hindi(17,
                                          c: AppColors.maroon,
                                          w: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text(
                                      '"A simple digital practice\nfor your daily Sankalp."',
                                      textAlign: TextAlign.center,
                                      style: AppText.body(12,
                                          c: AppColors.muted)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text('Choose your target',
                                style: AppText.body(14,
                                    c: AppColors.ink, w: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('How many Naam would you like to write?',
                                style: AppText.body(11.5, c: AppColors.muted)),
                            const SizedBox(height: 10),
                            for (final t in sankalpTargets)
                              SelectTile(
                                label: fmt(t),
                                selected: AppState.target == t,
                                onTap: () =>
                                    setState(() => AppState.target = t),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: AppColors.creamLight,
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
              child: SafeArea(
                top: false,
                child: PrimaryButton(
                  label: 'Continue',
                  trailing: Icons.arrow_forward_rounded,
                  onTap: () => Navigator.pushNamed(context, '/create-sankalp'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
