import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'sankalp_setup_screens.dart' show MiniPage;

// ───────────────────────── 18. COMPLETION SCREEN ─────────────────────────
class CompletionScreen extends StatelessWidget {
  const CompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = AppState.deity;
    return DevScaffold(
      showBack: true,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: 'Get My Digital Pustika',
            leading: Icons.card_giftcard_rounded,
            onTap: () => Navigator.pushNamed(context, '/digital-pustika'),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Share',
            leading: Icons.share_rounded,
            onTap: () => Navigator.pushNamed(context, '/share'),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Icon(Icons.celebration_rounded, size: 40, color: AppColors.saffron),
          const SizedBox(height: 6),
          Text('Sankalp Completed', style: AppText.display(26)),
          const SizedBox(height: 18),
          Text('श्री ${d.hi}', style: AppText.hindi(44)),
          const SizedBox(height: 4),
          Text(fmt(AppState.target), style: AppText.display(56)),
          Text('Naam Written',
              style: AppText.display(18, c: AppColors.maroonDark)),
          const SizedBox(height: 8),
          Text('10 October 2026',
              style: AppText.body(12.5, c: AppColors.muted)),
          const SizedBox(height: 22),
          DevCard(
            color: AppColors.creamDark.o(0.5),
            child: Column(
              children: [
                Text('🙏  Congratulations  🙏',
                    style: AppText.display(18, c: AppColors.maroon)),
                const SizedBox(height: 6),
                Text(
                    'Would you like to create a Naam Pustika for someone you love?',
                    textAlign: TextAlign.center,
                    style: AppText.body(12.5, c: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 19. DIGITAL PUSTIKA PREVIEW ─────────────────────────
class DigitalPustikaPreviewScreen extends StatefulWidget {
  const DigitalPustikaPreviewScreen({super.key});
  @override
  State<DigitalPustikaPreviewScreen> createState() =>
      _DigitalPustikaPreviewScreenState();
}

class _DigitalPustikaPreviewScreenState
    extends State<DigitalPustikaPreviewScreen> {
  int _sel = 0;
  static const _labels = ['Front Cover', 'First Page', 'Writing Page', 'Completion'];

  Widget _big(Deity d) {
    switch (_sel) {
      case 0:
        return PustikaCover(
            deity: d,
            name: AppState.name,
            count: AppState.target,
            title: '${d.hi} नाम लेखन पुस्तिका');
      case 1:
        return AspectRatio(
          aspectRatio: 0.72,
          child: OrnateFrame(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('सप्रेम भेंट', style: AppText.hindi(22)),
                    const SizedBox(height: 10),
                    Text('मेरी माँ के लिए',
                        style: AppText.hindi(18, c: AppColors.ink)),
                    const SizedBox(height: 14),
                    Icon(Icons.spa_rounded, color: AppColors.saffron, size: 40),
                    const SizedBox(height: 14),
                    Text('प्रेम सहित — ${AppState.name}',
                        textAlign: TextAlign.center,
                        style: AppText.hindi(15, c: AppColors.maroon)),
                  ],
                ),
              ),
            ),
          ),
        );
      case 2:
        return AspectRatio(
            aspectRatio: 0.72, child: ExampleWritingPageBody(deity: d, page: 12));
      default:
        return AspectRatio(
          aspectRatio: 0.72,
          child: OrnateFrame(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_rounded,
                        color: AppColors.gold, size: 48),
                    const SizedBox(height: 10),
                    Text('Completion Certificate',
                        textAlign: TextAlign.center,
                        style: AppText.display(18)),
                    const SizedBox(height: 8),
                    Text('${fmt(AppState.target)} ${d.hi} Naam',
                        style: AppText.hindi(16, c: AppColors.ink)),
                    Text('Completed by ${AppState.name}',
                        style: AppText.body(12, c: AppColors.muted)),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = AppState.deity;
    return DevScaffold(
      title: 'Digital Pustika Preview',
      bottom: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Free Preview',
              onTap: () => Navigator.pushNamed(context, '/example-page'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: 'Buy Full Pustika',
              onTap: () => Navigator.pushNamed(context, '/payment'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 6),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: _big(d),
            ),
          ),
          const SizedBox(height: 10),
          Text(_labels[_sel], style: AppText.body(12.5, c: AppColors.muted)),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _sel = i),
                    child: Container(
                      height: 78,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _sel == i
                              ? AppColors.maroon
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: MiniPage(style: i == 0 ? 2 : (i == 2 ? 1 : 0)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 20. PAYMENT ─────────────────────────
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _method = 0;
  static const _methods = [
    (Icons.account_balance_wallet_rounded, 'UPI'),
    (Icons.credit_card_rounded, 'Cards'),
    (Icons.account_balance_rounded, 'Net Banking'),
    (Icons.wallet_rounded, 'Wallets'),
  ];

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      title: 'Payment',
      bottom: PrimaryButton(
        label: 'Pay ₹149',
        leading: Icons.lock_rounded,
        onTap: () {
          showDemoSnack(context, 'Payment successful (demo). Razorpay comes in Phase 4.');
          Navigator.pushNamed(context, '/purchases');
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DevCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Digital Naam Pustika', style: AppText.display(18)),
                const SizedBox(height: 10),
                for (final f in [
                  '${fmt(AppState.target)} Naam',
                  'Personalized Cover',
                  'All Writing Pages',
                  'Completion Certificate',
                  'High-quality PDF',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 17, color: AppColors.gold),
                        const SizedBox(width: 8),
                        Text(f, style: AppText.body(13)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.line),
                Center(
                  child: Text('₹149', style: AppText.display(38)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Pay with', style: AppText.body(13, c: AppColors.muted)),
          const SizedBox(height: 8),
          for (var i = 0; i < _methods.length; i++)
            SelectTile(
              label: _methods[i].$2,
              selected: _method == i,
              onTap: () => setState(() => _method = i),
              leading: Icon(_methods[i].$1, color: AppColors.maroon, size: 20),
            ),
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_rounded,
                    size: 15, color: AppColors.success),
                const SizedBox(width: 6),
                Text('Razorpay Secured Payment',
                    style: AppText.body(11.5, c: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 21. PURCHASES / DOWNLOADS ─────────────────────────
class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  Widget _item(BuildContext context, String title, String sub, String date,
      int miniStyle) {
    return DevCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: 56, height: 72, child: MiniPage(style: miniStyle)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppText.body(14, w: FontWeight.w600)),
                    Text(sub, style: AppText.body(12.5)),
                    Text('Purchased: $date',
                        style: AppText.body(11, c: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'View',
                  onTap: () => Navigator.pushNamed(context, '/digital-pustika'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'Download',
                  onTap: () => showDemoSnack(context, 'Download started (demo)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = AppState.deity;
    return DevScaffold(
      title: 'My Digital Products',
      body: Column(
        children: [
          const SizedBox(height: 6),
          _item(context, '${d.en} Naam Pustika',
              '${fmt(AppState.target)} Naam', '10 Oct 2026', 1),
          _item(context, 'Completion Certificate',
              '${fmt(AppState.target)} Naam', '10 Oct 2026', 0),
        ],
      ),
    );
  }
}

// ───────────────────────── 22. SHARE CARD ─────────────────────────
class ShareCardScreen extends StatelessWidget {
  const ShareCardScreen({super.key});

  Widget _circle(BuildContext context, IconData icon, Color color, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => showDemoSnack(context, '$label – share sheet comes with share_plus'),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 6),
            Text(label, style: AppText.body(11.5, w: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = AppState.deity;
    return DevScaffold(
      title: 'Share Card',
      body: Column(
        children: [
          const SizedBox(height: 6),
          OrnateFrame(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF6DE), Color(0xFFF4D890)],
                ),
              ),
              child: Column(
                children: [
                  Text('श्री ${d.hi}', style: AppText.hindi(32)),
                  const SizedBox(height: 6),
                  Text(fmt(AppState.target),
                      style: AppText.display(54)),
                  Text('${d.en.toUpperCase()} NAAM\nCOMPLETED',
                      textAlign: TextAlign.center,
                      style: AppText.cinzel(19)),
                  const SizedBox(height: 14),
                  Text(AppState.name, style: AppText.display(18, c: AppColors.ink)),
                  Text('Digital Naam Lekhan',
                      style: AppText.body(11, c: AppColors.muted)),
                  const SizedBox(height: 10),
                  Icon(Icons.spa_rounded, color: AppColors.saffron, size: 36),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              _circle(context, Icons.chat_rounded, const Color(0xFF25D366),
                  'WhatsApp'),
              _circle(context, Icons.camera_alt_rounded,
                  const Color(0xFFC13584), 'Instagram'),
              _circle(context, Icons.download_rounded, AppColors.maroon,
                  'Download'),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 25. EXAMPLE WRITING PAGE ─────────────────────────
class ExampleWritingPageBody extends StatelessWidget {
  final Deity deity;
  final int page;
  const ExampleWritingPageBody(
      {super.key, required this.deity, required this.page});

  @override
  Widget build(BuildContext context) {
    return OrnateFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
        child: Column(
          children: [
            Text('श्री ${deity.hi}',
                style: AppText.hindi(16, c: AppColors.maroon)),
            const SizedBox(height: 4),
            Expanded(
              child: Column(
                children: [
                  for (var r = 0; r < 9; r++)
                    Expanded(
                      child: Row(
                        children: [
                          for (var c = 0; c < 4; c++)
                            Expanded(
                              child: Center(
                                child: FittedBox(
                                  child: Text(deity.hi,
                                      style: AppText.hindi(14,
                                          c: AppColors.ink,
                                          w: FontWeight.w500)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Text('Page $page / 250',
                style: AppText.body(9.5, c: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class ExampleWritingPageScreen extends StatelessWidget {
  const ExampleWritingPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      title: 'Example Writing Page',
      scroll: false,
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
      body: ExampleWritingPageBody(deity: AppState.deity, page: 12),
    );
  }
}
