import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/services/app_services.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'theme.dart';

const bool kGallery = bool.fromEnvironment('GALLERY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Token storage, API client, auth repository, local session flags
  await AppServices.init();

  // Keep the app in portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Configure status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const NaamLekhanApp());
}

class NaamLekhanApp extends StatelessWidget {
  const NaamLekhanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Naam Lekhan',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      initialRoute: kGallery ? '/gallery' : '/splash',
      onGenerateRoute: onGenerateRoute,

      // Keep a phone-sized column on web and tablets
      builder: (context, child) => Container(
        color: AppColors.maroonDark,
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 480,
          ),
          child: child,
        ),
      ),
    );
  }
}
