import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

// ───────────────────────── 1. SPLASH ─────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600));
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.2,
            colors: [Color(0xFFFFF9E6), Color(0xFFF7DFA6), Color(0xFFE4B861)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              GestureDetector(
                onLongPress: () => Navigator.pushNamed(context, '/gallery'),
                child: Text('ॐ',
                    style: AppText.hindi(96, c: AppColors.maroon)),
              ),
              const SizedBox(height: 8),
              Text('DIGITAL', style: AppText.cinzel(34)),
              Text('NAAM LEKHAN',
                  style: AppText.cinzel(30, c: AppColors.maroonDark)),
              const SizedBox(height: 18),
              Text('Write. Remember.\nComplete Your Sankalp.',
                  textAlign: TextAlign.center,
                  style: AppText.display(16,
                      c: AppColors.maroonDark, w: FontWeight.w500)),
              const Spacer(flex: 2),
              Icon(Icons.local_fire_department_rounded,
                  size: 64, color: AppColors.saffron),
              Container(
                width: 70,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.maroon,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(40)),
                ),
              ),
              const Spacer(flex: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, __) => GradientProgress(value: _c.value, height: 5),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── 2. ONBOARDING ─────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  static const _pages = [
    (
      Icons.temple_hindu_rounded,
      'A beautiful way to\nremember your Isht Dev',
      'Start your personal Naam Lekhan journey and create a daily spiritual writing habit.'
    ),
    (
      Icons.edit_note_rounded,
      'Write the Naam,\nbuild your Sankalp',
      'Write with your finger or stylus. Your progress is saved automatically — never lose a single Naam.'
    ),
    (
      Icons.card_giftcard_rounded,
      'Bridge between\ngenerations',
      'You write digitally. Gift a personalised Naam Pustika to your parents and grandparents to write by hand.'
    ),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _pages.length - 1) {
      Navigator.pushNamed(context, '/language');
    } else {
      _pc.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;
    return DevScaffold(
      showBack: false,
      scroll: false,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/language'),
              child: Text('Skip',
                  style: AppText.body(14, c: AppColors.muted)),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                final p = _pages[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            Colors.white,
                            AppColors.goldLight.o(0.55),
                            AppColors.cream,
                          ]),
                        ),
                        child: Icon(p.$1, size: 110, color: AppColors.gold),
                      ),
                      const SizedBox(height: 28),
                      Icon(Icons.local_fire_department_rounded,
                          color: AppColors.saffron, size: 28),
                      const SizedBox(height: 6),
                      Text(p.$2,
                          textAlign: TextAlign.center,
                          style: AppText.display(24)),
                      const SizedBox(height: 12),
                      Text(p.$3,
                          textAlign: TextAlign.center,
                          style: AppText.body(13.5, c: AppColors.muted)),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _pages.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(4),
                  width: i == _page ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.maroon : AppColors.gold.o(0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: PrimaryButton(
                label: last ? 'Start My Journey' : 'Next', onTap: _next),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 3. CHOOSE LANGUAGE ─────────────────────────
class ChooseLanguageScreen extends StatefulWidget {
  const ChooseLanguageScreen({super.key});
  @override
  State<ChooseLanguageScreen> createState() => _ChooseLanguageScreenState();
}

class _ChooseLanguageScreenState extends State<ChooseLanguageScreen> {
  int _sel = 0;
  static const _langs = [
    ('अ', 'हिंदी', 'Hindi'),
    ('A', 'English', 'English'),
    ('ਅ', 'ਪੰਜਾਬੀ', 'Punjabi'),
  ];

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      title: 'Choose Language',
      subtitle: 'अपनी भाषा चुनें',
      bottom: PrimaryButton(
          label: 'Continue',
          onTap: () => Navigator.pushNamed(context, '/account')),
      body: Column(
        children: [
          const SizedBox(height: 24),
          for (var i = 0; i < _langs.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DevCard(
                onTap: () => setState(() => _sel = i),
                color: _sel == i ? AppColors.creamDark.o(0.6) : null,
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.maroon,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_langs[i].$1,
                          style: AppText.hindi(22, c: Colors.white)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(_langs[i].$2,
                          style: AppText.hindi(20, c: AppColors.ink)),
                    ),
                    Icon(
                      _sel == i
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: _sel == i ? AppColors.maroon : AppColors.gold,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text('More languages coming soon',
              style: AppText.body(12, c: AppColors.muted)),
        ],
      ),
    );
  }
}

// ───────────────────────── 4. CREATE ACCOUNT ─────────────────────────
class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  Widget _authButton(BuildContext context, IconData icon, String label,
      {Color iconColor = AppColors.ink}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DevCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () => Navigator.pushNamedAndRemoveUntil(
            context, '/home', (r) => false),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 14),
            Text(label, style: AppText.body(14.5, w: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      showBack: true,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Icon(Icons.local_fire_department_rounded,
              size: 52, color: AppColors.saffron),
          const SizedBox(height: 8),
          Text('Welcome', style: AppText.display(30)),
          Text('to Digital Naam Lekhan',
              style: AppText.body(14, c: AppColors.muted)),
          const SizedBox(height: 32),
          _authButton(context, Icons.g_mobiledata_rounded,
              'Continue with Google',
              iconColor: const Color(0xFFDB4437)),
          _authButton(context, Icons.apple, 'Continue with Apple'),
          _authButton(
              context, Icons.phone_iphone_rounded, 'Continue with Mobile',
              iconColor: AppColors.maroon),
          const SizedBox(height: 4),
          Row(children: [
            const Expanded(child: Divider(color: AppColors.line)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: AppText.body(12, c: AppColors.muted)),
            ),
            const Expanded(child: Divider(color: AppColors.line)),
          ]),
          const SizedBox(height: 16),
          SecondaryButton(
            label: 'Continue as Guest',
            onTap: () => Navigator.pushNamedAndRemoveUntil(
                context, '/home', (r) => false),
          ),
          const SizedBox(height: 40),
          Text.rich(
            TextSpan(
              style: AppText.body(11.5, c: AppColors.muted),
              children: [
                const TextSpan(text: 'By continuing, you agree to our\n'),
                TextSpan(
                    text: 'Terms & Privacy Policy',
                    style: AppText.body(11.5,
                        c: AppColors.maroon, w: FontWeight.w600)),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
