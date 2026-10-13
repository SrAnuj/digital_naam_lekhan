import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/services/app_services.dart';
import '../data.dart';
import '../features/auth/data/auth_repository.dart';
import '../theme.dart';
import '../widgets.dart';

// ───────────────────────── shared bits ─────────────────────────

/// PrimaryButton with a disabled / busy state.
class _AuthButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;
  const _AuthButton({
    required this.label,
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled || busy,
        child:
            PrimaryButton(label: busy ? 'Please wait…' : label, onTap: onTap),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String? message;
  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox(height: 22);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        message!,
        textAlign: TextAlign.center,
        style: AppText.body(12.5, c: Colors.red.shade700),
      ),
    );
  }
}

Widget _heroIcon(IconData icon) => Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          Colors.white,
          AppColors.goldLight.o(0.55),
          AppColors.cream,
        ]),
      ),
      child: Icon(icon, size: 40, color: AppColors.maroon),
    );

// ───────────────────────── 4a. PHONE LOGIN ─────────────────────────
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});
  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  /// Indian mobile: 10 digits, starts with 6-9.
  bool get _valid => RegExp(r'^[6-9]\d{9}$').hasMatch(_ctrl.text);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_valid || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final phone = '+91${_ctrl.text}';
    try {
      await AppServices.auth.sendOtp(phone);
      if (!mounted) return;
      Navigator.pushNamed(context, '/otp', arguments: {'phone': phone});
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      title: 'Login with Mobile',
      subtitle: 'मोबाइल नंबर से लॉगिन',
      bottom: _AuthButton(
        label: 'Send OTP',
        enabled: _valid,
        busy: _busy,
        onTap: _send,
      ),
      body: Column(
        children: [
          const SizedBox(height: 28),
          _heroIcon(Icons.phone_iphone_rounded),
          const SizedBox(height: 20),
          Text('Enter your mobile number', style: AppText.display(22)),
          const SizedBox(height: 6),
          Text(
            'We will send a 6-digit OTP to verify your number',
            textAlign: TextAlign.center,
            style: AppText.body(13, c: AppColors.muted),
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold, width: 1.2),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('🇮🇳  +91',
                      style: AppText.body(16, w: FontWeight.w600)),
                ),
                Container(width: 1, height: 28, color: AppColors.line),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    style: AppText.body(18, w: FontWeight.w500),
                    cursorColor: AppColors.maroon,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '98765 43210',
                      hintStyle: AppText.body(18, c: AppColors.muted.o(0.5)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 16),
                    ),
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ],
            ),
          ),
          _ErrorText(_error),
          const SizedBox(height: 24),
          Text.rich(
            TextSpan(
              style: AppText.body(11.5, c: AppColors.muted),
              children: [
                const TextSpan(text: 'By continuing, you agree to our\n'),
                TextSpan(
                  text: 'Terms & Privacy Policy',
                  style: AppText.body(11.5,
                      c: AppColors.maroon, w: FontWeight.w600),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 4b. OTP VERIFY ─────────────────────────
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _len = 6;
  static const _resendSeconds = 30;

  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  StreamSubscription<void>? _sub;
  Timer? _timer;

  String _phone = '';
  bool _didInit = false;
  bool _busy = false;
  int _left = _resendSeconds;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['phone'] is String) {
      _phone = args['phone'] as String;
    }

    _startTimer();

    // Android may read the SMS by itself -> continue without typing.
    _sub = AppServices.auth.autoVerified.listen((_) => _verify());
    if (AppServices.auth.hasAutoCredential) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _pretty {
    final d = _phone.startsWith('+91') ? _phone.substring(3) : _phone;
    return d.length == 10
        ? '+91 ${d.substring(0, 5)} ${d.substring(5)}'
        : _phone;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_left <= 1) {
        t.cancel();
        setState(() => _left = 0);
      } else {
        setState(() => _left--);
      }
    });
  }

  String? _nameFrom(Map<String, dynamic> data) {
    final user = data['user'];
    final raw = (user is Map ? user['name'] : null) ?? data['name'];
    final s = raw is String ? raw.trim() : '';
    return s.isEmpty ? null : s;
  }

  Future<void> _verify() async {
    if (_busy) return;
    final auto = AppServices.auth.hasAutoCredential;
    if (!auto && _ctrl.text.length != _len) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final data = await AppServices.auth.verifyOtp(_ctrl.text);

      final session = AppServices.session;
      await session.setGuest(false);

      // Name from the server, else the one saved earlier on this device.
      final name = _nameFrom(data) ?? session.userName;
      if (name != null) {
        await session.setUserName(name);
        AppState.name = name;
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        name == null ? '/profile-setup' : '/home',
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = authErrorMessage(e);
        _ctrl.clear();
      });
      _focus.requestFocus();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_left > 0 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppServices.auth.sendOtp(_phone, resend: true);
      if (!mounted) return;
      _ctrl.clear();
      setState(() => _left = _resendSeconds);
      _startTimer();
      showDemoSnack(context, 'OTP sent again');
    } catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _box(int i) {
    final text = _ctrl.text;
    final filled = i < text.length;
    final active = _focus.hasFocus && i == text.length.clamp(0, _len - 1);
    final borderColor = _error != null
        ? Colors.red.shade600
        : active
            ? AppColors.maroon
            : filled
                ? AppColors.gold
                : AppColors.line;

    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: active ? 1.8 : 1.2),
      ),
      child: Text(filled ? text[i] : '',
          style: AppText.display(22, c: AppColors.ink)),
    );
  }

  /// Six visible boxes, with one invisible TextField laid on top.
  /// That keeps paste, SMS autofill and the number keypad working.
  Widget _otpField() {
    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < _len; i++) ...[
                Expanded(child: _box(i)),
                if (i != _len - 1) const SizedBox(width: 8),
              ],
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                autofocus: true,
                showCursor: false,
                enableInteractiveSelection: false,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_len),
                ],
                decoration: const InputDecoration(
                    border: InputBorder.none, counterText: ''),
                onChanged: (v) {
                  setState(() => _error = null);
                  if (v.length == _len) _verify();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      title: 'Verify OTP',
      subtitle: 'ओटीपी दर्ज करें',
      bottom: _AuthButton(
        label: 'Verify & Continue',
        enabled: _ctrl.text.length == _len,
        busy: _busy,
        onTap: _verify,
      ),
      body: Column(
        children: [
          const SizedBox(height: 28),
          _heroIcon(Icons.sms_rounded),
          const SizedBox(height: 20),
          Text('Enter the 6-digit code', style: AppText.display(22)),
          const SizedBox(height: 6),
          Text('Sent to $_pretty', style: AppText.body(13, c: AppColors.muted)),
          TextButton(
            onPressed: () => Navigator.maybePop(context),
            child: Text('Change number',
                style: AppText.body(12.5,
                    c: AppColors.maroon, w: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          _otpField(),
          _ErrorText(_error),
          const SizedBox(height: 18),
          if (_left > 0)
            Text(
              'Resend OTP in 00:${_left.toString().padLeft(2, '0')}',
              style: AppText.body(13, c: AppColors.muted),
            )
          else
            TextButton(
              onPressed: _resend,
              child: Text('Resend OTP',
                  style: AppText.body(14,
                      c: AppColors.maroon, w: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── 4c. PROFILE SETUP (first login) ─────────────────────────
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  bool _busy = false;

  bool get _valid => _name.text.trim().length >= 2;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_valid || _busy) return;
    setState(() => _busy = true);

    final n = _name.text.trim();
    try {
      await AppServices.auth.updateName(n);
      await AppServices.session.setUserName(n);
      AppState.name = n;
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
    } catch (e) {
      if (mounted) showDemoSnack(context, authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _skip() {
    AppState.name = 'Devotee';
    Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return DevScaffold(
      title: 'Your Name',
      subtitle: 'आपका नाम',
      showBack: false,
      actions: [
        TextButton(
          onPressed: _skip,
          child: Text('Skip', style: AppText.body(14, c: AppColors.muted)),
        ),
      ],
      bottom: _AuthButton(
        label: 'Continue',
        enabled: _valid,
        busy: _busy,
        onTap: _save,
      ),
      body: Column(
        children: [
          const SizedBox(height: 28),
          _heroIcon(Icons.person_rounded),
          const SizedBox(height: 20),
          Text('What should we call you?', style: AppText.display(22)),
          const SizedBox(height: 6),
          Text(
            'This name appears on your Sankalp\nand Naam Pustika',
            textAlign: TextAlign.center,
            style: AppText.body(13, c: AppColors.muted),
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold, width: 1.2),
            ),
            child: TextField(
              controller: _name,
              autofocus: true,
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              style: AppText.body(18, w: FontWeight.w500),
              cursorColor: AppColors.maroon,
              decoration: InputDecoration(
                border: InputBorder.none,
                counterText: '',
                hintText: 'Your name',
                hintStyle: AppText.body(18, c: AppColors.muted.o(0.5)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
            ),
          ),
        ],
      ),
    );
  }
}
