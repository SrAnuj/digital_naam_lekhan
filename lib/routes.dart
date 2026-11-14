import 'package:flutter/material.dart';

import 'screens/auth_screens.dart';
import 'screens/gallery_screen.dart';
import 'screens/home_library_screens.dart';
import 'screens/onboarding_screens.dart';
import 'screens/progress_screens.dart';
import 'screens/pustika_screens.dart';
import 'screens/sankalp_setup_screens.dart';
import 'screens/settings_screens.dart';
import 'screens/writing_screens.dart';

// CMS Pages
import 'features/pages/presentation/screens/cms_page_screen.dart';

class ScreenEntry {
  final int no;
  final String title;
  final String route;
  final WidgetBuilder builder;

  const ScreenEntry(this.no, this.title, this.route, this.builder);
}

/// The 25 MVP screens, in design-sheet order.
final List<ScreenEntry> screenList = [
  ScreenEntry(1, 'Splash Screen', '/splash', (_) => const SplashScreen()),
  ScreenEntry(2, 'Onboarding', '/onboarding', (_) => const OnboardingScreen()),
  ScreenEntry(
      3, 'Choose Language', '/language', (_) => const ChooseLanguageScreen()),
  ScreenEntry(
      4, 'Create Account', '/account', (_) => const CreateAccountScreen()),
  ScreenEntry(5, 'Home Dashboard', '/home', (_) => const HomeScreen()),
  ScreenEntry(6, 'Naam Library', '/library', (_) => const NaamLibraryScreen()),
  ScreenEntry(
      7, 'Naam Detail', '/naam-detail', (_) => const NaamDetailScreen()),
  ScreenEntry(8, 'Create Sankalp', '/create-sankalp',
      (_) => const CreateSankalpScreen()),
  ScreenEntry(9, 'Choose Design', '/design', (_) => const ChooseDesignScreen()),
  ScreenEntry(
      10, 'Preview Pustika', '/preview', (_) => const PreviewPustikaScreen()),
  ScreenEntry(11, 'Writing Screen', '/writing', (_) => const WritingScreen()),
  ScreenEntry(12, 'Daily Completion', '/daily-complete',
      (_) => const DailyCompletionScreen()),
  ScreenEntry(13, 'Progress Dashboard', '/progress',
      (_) => const ProgressDashboardScreen()),
  ScreenEntry(
      14, 'Sankalp History', '/history', (_) => const SankalpHistoryScreen()),
  ScreenEntry(
      15, 'My Sankalps', '/my-sankalps', (_) => const MySankalpsScreen()),
  ScreenEntry(16, 'Jap Counter', '/jap', (_) => const JapCounterScreen()),
  ScreenEntry(17, 'Notification Settings', '/notifications',
      (_) => const NotificationSettingsScreen()),
  ScreenEntry(
      18, 'Completion Screen', '/completion', (_) => const CompletionScreen()),
  ScreenEntry(19, 'Digital Pustika Preview', '/digital-pustika',
      (_) => const DigitalPustikaPreviewScreen()),
  ScreenEntry(20, 'Payment Screen', '/payment', (_) => const PaymentScreen()),
  ScreenEntry(21, 'Purchases / Downloads', '/purchases',
      (_) => const PurchasesScreen()),
  ScreenEntry(22, 'Share Card', '/share', (_) => const ShareCardScreen()),
  ScreenEntry(
      23, 'Profile / Settings', '/profile', (_) => const ProfileScreen()),
  ScreenEntry(26, 'Edit Profile', '/profile-update',
      (_) => const ProfileUpdateScreen()),
  ScreenEntry(
    27,
    'Sankalp Completion',
    '/sankalp-complete',
    (_) => const SankalpCompletionScreen(),
  ),
  ScreenEntry(24, 'Family Sankalp (Premium)', '/family',
      (_) => const FamilySankalpScreen()),
  ScreenEntry(25, 'Example Writing Page', '/example-page',
      (_) => const ExampleWritingPageScreen()),
];

final Map<String, WidgetBuilder> appRoutes = {
  for (final s in screenList) s.route: s.builder,

  '/gallery': (_) => const GalleryScreen(),

  // Phone login flow
  '/phone': (_) => const PhoneLoginScreen(),
  '/otp': (_) => const OtpScreen(),
  '/profile-setup': (_) => const ProfileSetupScreen(),

  // CMS Pages
  '/about': (_) => const CmsPageScreen(slug: 'about'),
  '/help-support': (_) => const CmsPageScreen(slug: 'help-support'),
  '/terms-conditions': (_) => const CmsPageScreen(slug: 'terms-and-conditions'),
  '/privacy-policy': (_) => const CmsPageScreen(slug: 'privacy-policy'),
};

Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  debugPrint('ROUTE REQUESTED: ${settings.name}');
  debugPrint(
      'SANKALP ROUTE EXISTS: ${appRoutes.containsKey('/sankalp-complete')}');
  debugPrint('ALL ROUTES: ${appRoutes.keys.toList()}');

  final builder = appRoutes[settings.name];

  if (builder == null) {
    debugPrint('ROUTE NOT FOUND: ${settings.name}');
    return null;
  }

  return PageRouteBuilder<dynamic>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) {
      return builder(context);
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}
