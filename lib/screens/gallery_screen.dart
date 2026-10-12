import 'package:flutter/material.dart';
import '../routes.dart';
import '../theme.dart';
import '../widgets.dart';

/// Design review index: jump straight to any of the 25 screens.
/// Run with:  flutter run --dart-define=GALLERY=true
/// (or long-press the Om on the splash screen).
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      title: 'All 25 Screens',
      subtitle: 'Design review',
      scroll: false,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      body: ListView.separated(
        itemCount: screenList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final s = screenList[i];
          return DevCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            onTap: () => Navigator.pushNamed(context, s.route),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: AppColors.maroon, shape: BoxShape.circle),
                  child: Text('${s.no}',
                      style: AppText.body(13,
                          c: Colors.white, w: FontWeight.w600)),
                ),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(s.title,
                        style: AppText.body(14, w: FontWeight.w500))),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.muted),
              ],
            ),
          );
        },
      ),
    );
  }
}
