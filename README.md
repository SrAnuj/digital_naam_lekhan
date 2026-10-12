# Digital Naam Lekhan (Flutter)

Phase 2 (MVP app) — all 25 screens designed in Flutter, UI only (no backend yet).

## Run
```bash
flutter create . --platforms=android,ios,web   # one-time: generates android/ios/web folders
flutter pub get
flutter run                                    # normal flow, starts at Splash
flutter run --dart-define=GALLERY=true         # opens the 25-screen review index
```
Long-press the Om on the splash screen to open the review index too.

## Structure
- `lib/theme.dart` colors, fonts, Indian number format
- `lib/widgets.dart` shared kit (buttons, cards, nav, cover, frames)
- `lib/data.dart` deities + demo state (replace with Provider/Riverpod + Laravel API)
- `lib/screens/*` the 25 screens, grouped by feature
- `lib/routes.dart` route table + screen list

## Deity artwork
Drop `assets/deities/<id>.png` (ram, radha, krishna, shiv, hanuman, durga, ganesh, lakshmi, waheguru) to replace placeholder tiles.

## Next steps (per roadmap)
State mgmt + local DB (autosave), Laravel auth/sync, notifications, Razorpay, share_plus, i18n (hi/en/pa), PDF generation.
