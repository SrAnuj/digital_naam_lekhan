import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'routes.dart';
import 'theme.dart';

const bool kGallery = bool.fromEnvironment('GALLERY');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
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
      // Keep a phone-sized column when previewed on web / tablets.
      builder: (context, child) => Container(
        color: AppColors.maroonDark,
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: child,
        ),
      ),
    );
  }
}
