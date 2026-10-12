import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

// ───────────────────────── 8. CREATE SANKALP ─────────────────────────
class CreateSankalpScreen extends StatefulWidget {
  const CreateSankalpScreen({super.key});
  @override
  State<CreateSankalpScreen> createState() => _CreateSankalpScreenState();
}

class _CreateSankalpScreenState extends State<CreateSankalpScreen> {
  static const _options = ['Myself', 'Mother', 'Father', 'Family', 'Someone special'];
  late final TextEditingController _name =
      TextEditingController(text: AppState.name);
  late final TextEditingController _intent =
      TextEditingController(text: AppState.intention);

  @override
  void dispose() {
    _name.dispose();
    _intent.dispose();
    super.dispose();
  }

  InputDecoration _dec() => InputDecoration(
        filled: true,
        fillColor: AppColors.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.maroon, width: 1.4),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      title: 'Create Your Sankalp',
      subtitle: 'यह संकल्प किसके है ?',
      bottom: PrimaryButton(
        label: 'Continue',
        trailing: Icons.arrow_forward_rounded,
        onTap: () {
          AppState.name = _name.text.trim().isEmpty ? 'Devotee' : _name.text.trim();
          AppState.intention = _intent.text.trim();
          Navigator.pushNamed(context, '/design');
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          for (final o in _options)
            SelectTile(
              label: o,
              selected: AppState.forWhom == o,
              onTap: () => setState(() => AppState.forWhom = o),
            ),
          const SizedBox(height: 12),
          Text('Name', style: AppText.body(12, c: AppColors.muted)),
          const SizedBox(height: 6),
          TextField(
              controller: _name,
              style: AppText.body(14.5),
              decoration: _dec()),
          const SizedBox(height: 16),
          Text('Sankalp Intention (Optional)',
              style: AppText.body(12, c: AppColors.muted)),
          const SizedBox(height: 6),
          TextField(
            controller: _intent,
            style: AppText.body(14.5),
            maxLines: 3,
            decoration: _dec().copyWith(
                hintText: 'For the peace and happiness of my family.'),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 9. CHOOSE DESIGN ─────────────────────────
class MiniPage extends StatelessWidget {
  final int style; // 0 simple, 1 traditional, 2 premium
  const MiniPage({super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    final lines = Column(
      children: [
        for (var i = 0; i < 9; i++)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColors.line, width: 0.8)),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('राम',
                    style: AppText.hindi(8,
                        c: AppColors.muted.o(0.55), w: FontWeight.w500)),
              ),
            ),
          ),
      ],
    );
    if (style == 0) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(4),
        ),
        child: lines,
      );
    }
    if (style == 1) {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.creamLight,
            border: Border.all(color: AppColors.maroon, width: 1),
          ),
          child: lines,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
            colors: [AppColors.goldLight, AppColors.gold, AppColors.maroon]),
      ),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF3CC), Color(0xFFFBE5A8)]),
        ),
        child: Column(
          children: [
            Text('ॐ', style: AppText.hindi(9, c: AppColors.maroon)),
            Expanded(child: lines),
          ],
        ),
      ),
    );
  }
}

class ChooseDesignScreen extends StatefulWidget {
  const ChooseDesignScreen({super.key});
  @override
  State<ChooseDesignScreen> createState() => _ChooseDesignScreenState();
}

class _ChooseDesignScreenState extends State<ChooseDesignScreen> {
  static const _names = [
    ('Simple', 'Clean and minimal'),
    ('Traditional', 'Devotional style'),
    ('Premium', 'Elegant design'),
  ];

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      title: 'Choose Writing Style',
      subtitle: 'अपनी पसंद का डिज़ाइन चुनें',
      bottom: PrimaryButton(
        label: 'Continue',
        trailing: Icons.arrow_forward_rounded,
        onTap: () => Navigator.pushNamed(context, '/preview'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => AppState.design = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 190,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppState.design == i
                                    ? AppColors.maroon
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: MiniPage(style: i),
                          ),
                          const SizedBox(height: 8),
                          Text(_names[i].$1,
                              style: AppText.body(13,
                                  c: AppState.design == i
                                      ? AppColors.maroon
                                      : AppColors.ink,
                                  w: FontWeight.w600)),
                          Text(_names[i].$2,
                              textAlign: TextAlign.center,
                              style: AppText.body(10, c: AppColors.muted)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          DevCard(
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.gold, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'You can change the writing design later from Settings. Your Naam are never lost.',
                      style: AppText.body(12, c: AppColors.muted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 10. PREVIEW PUSTIKA ─────────────────────────
class PreviewPustikaScreen extends StatelessWidget {
  const PreviewPustikaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = AppState.deity;
    return DevScaffold(
      title: 'Preview Pustika',
      subtitle: 'आपकी पुस्तिका',
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SecondaryButton(
            label: 'Preview Pages',
            onTap: () => Navigator.pushNamed(context, '/example-page'),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Start Sankalp',
            onTap: () {
              final nav = Navigator.of(context);
              nav.pushNamedAndRemoveUntil('/home', (r) => false);
              nav.pushNamed('/writing');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 270),
              child: PustikaCover(
                deity: d,
                name: AppState.name,
                count: AppState.target,
                title: '${d.hi} नाम लेखन',
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Created for ${AppState.name}',
              style: AppText.body(13, c: AppColors.muted)),
          const SizedBox(height: 4),
          Text('Sankalp · ${fmt(AppState.target)} Naam',
              style: AppText.display(16)),
        ],
      ),
    );
  }
}
