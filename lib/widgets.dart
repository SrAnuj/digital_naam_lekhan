import 'package:flutter/material.dart';
import 'data.dart';
import 'theme.dart';

/// Warm cream paper gradient used behind every screen.
class DevBackground extends StatelessWidget {
  final Widget child;
  const DevBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF9EC), AppColors.cream, Color(0xFFFAE7BE)],
        ),
      ),
      child: child,
    );
  }
}

/// Standard screen: header + scrolling body + pinned bottom + optional nav.
class DevScaffold extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget body;
  final Widget? bottom;
  final bool showBack;
  final List<Widget>? actions;
  final int? navIndex;
  final bool scroll;
  final EdgeInsets padding;

  const DevScaffold({
    super.key,
    this.title,
    this.subtitle,
    required this.body,
    this.bottom,
    this.showBack = true,
    this.actions,
    this.navIndex,
    this.scroll = true,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 20),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DevBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (title != null)
                ScreenHeader(
                    title: title!,
                    subtitle: subtitle,
                    showBack: showBack,
                    actions: actions),
              Expanded(
                child: scroll
                    ? SingleChildScrollView(padding: padding, child: body)
                    : Padding(padding: padding, child: body),
              ),
              if (bottom != null)
                Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: bottom),
              if (navIndex != null) AppBottomNav(index: navIndex!),
            ],
          ),
        ),
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final List<Widget>? actions;
  final Color? color;
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.actions,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.maroon;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: showBack
                ? IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: c),
                    onPressed: () => Navigator.maybePop(context),
                  )
                : null,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    textAlign: TextAlign.center,
                    style: AppText.display(20, c: c)),
                if (subtitle != null)
                  Text(subtitle!,
                      textAlign: TextAlign.center,
                      style: AppText.hindi(13, c: AppColors.muted,
                          w: FontWeight.w500)),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48),
            child: actions == null
                ? null
                : Row(mainAxisSize: MainAxisSize.min, children: actions!),
          ),
        ],
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  final int index;
  const AppBottomNav({super.key, required this.index});

  static const _items = [
    (Icons.home_rounded, 'Home', '/home'),
    (Icons.edit_rounded, 'Write', '/writing'),
    (Icons.insights_rounded, 'Progress', '/progress'),
    (Icons.menu_book_rounded, 'Library', '/library'),
    (Icons.person_rounded, 'Profile', '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.creamLight,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.o(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: InkWell(
                onTap: () {
                  if (i == index) return;
                  final nav = Navigator.of(context);
                  if (i == 0) {
                    nav.pushNamedAndRemoveUntil(_items[i].$3, (r) => false);
                  } else {
                    nav.pushNamedAndRemoveUntil(
                        _items[i].$3, (r) => r.settings.name == '/home');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_items[i].$1,
                          size: 22,
                          color: i == index
                              ? AppColors.maroon
                              : AppColors.muted),
                      const SizedBox(height: 2),
                      Text(_items[i].$2,
                          style: AppText.body(10.5,
                              c: i == index
                                  ? AppColors.maroon
                                  : AppColors.muted,
                              w: i == index
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? trailing;
  final IconData? leading;
  final Color? color;
  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.trailing,
    this.leading,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.maroon;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(c, Colors.white, 0.12)!, c],
            ),
            boxShadow: [
              BoxShadow(
                  color: c.o(0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                Icon(leading, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: AppText.body(15,
                      c: Colors.white, w: FontWeight.w600)),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Icon(trailing, color: Colors.white, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? leading;
  const SecondaryButton(
      {super.key, required this.label, this.onTap, this.leading});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.creamLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                Icon(leading, color: AppColors.maroon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: AppText.body(14,
                      c: AppColors.maroon, w: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class DevCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsets margin;
  const DevCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
              boxShadow: [
                BoxShadow(
                    color: AppColors.gold.o(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GradientProgress extends StatelessWidget {
  final double value;
  final double height;
  const GradientProgress({super.key, required this.value, this.height = 8});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: AppColors.line,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.maroon, AppColors.saffron, AppColors.gold]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Radio-style selectable row.
class SelectTile extends StatelessWidget {
  final String label;
  final String? trailing;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  const SelectTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.creamDark.o(0.6) : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.maroon : AppColors.line,
                width: selected ? 1.4 : 1),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.maroon : AppColors.gold,
                size: 22,
              ),
              const SizedBox(width: 12),
              if (leading != null) ...[leading!, const SizedBox(width: 10)],
              Expanded(
                  child: Text(label,
                      style: AppText.body(14.5,
                          w: selected ? FontWeight.w600 : FontWeight.w500))),
              if (trailing != null)
                Text(trailing!,
                    style: AppText.body(13, c: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deity artwork placeholder. Drop `assets/deities/<id>.png` to override.
class DeityAvatar extends StatelessWidget {
  final Deity deity;
  final double size;
  final double radius;
  final bool showLabel;
  final bool selected;
  const DeityAvatar({
    super.key,
    required this.deity,
    this.size = 90,
    this.radius = 14,
    this.showLabel = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final art = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [Colors.white.o(0.9), deity.c1, deity.c2],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
                child: Text(deity.symbol, style: TextStyle(fontSize: size * 0.42))),
            Image.asset(
              'assets/deities/${deity.id}.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius + 2),
            border: Border.all(
                color: selected ? AppColors.maroon : AppColors.gold,
                width: selected ? 2.2 : 1.2),
          ),
          child: art,
        ),
        if (showLabel) ...[
          const SizedBox(height: 6),
          Text(deity.hi,
              style: AppText.hindi(14, c: AppColors.maroon)),
        ],
      ],
    );
  }
}

/// Double gold frame used on Pustika pages & covers.
class OrnateFrame extends StatelessWidget {
  final Widget child;
  final Color fill;
  final double scale;
  const OrnateFrame({
    super.key,
    required this.child,
    this.fill = AppColors.creamLight,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5 * scale),
      decoration: BoxDecoration(
        color: AppColors.maroon,
        borderRadius: BorderRadius.circular(10 * scale),
        boxShadow: [
          BoxShadow(
              color: Colors.black.o(0.22),
              blurRadius: 14 * scale,
              offset: Offset(0, 6 * scale)),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(4 * scale),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(7 * scale),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(5 * scale),
            border: Border.all(color: AppColors.maroon, width: 1.2 * scale),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Scalable Pustika cover. Width drives all sizes.
class PustikaCover extends StatelessWidget {
  final Deity deity;
  final String name;
  final int count;
  final String title;
  const PustikaCover({
    super.key,
    required this.deity,
    required this.name,
    required this.count,
    this.title = 'नाम लेखन पुस्तिका',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final k = (c.maxWidth.isFinite ? c.maxWidth : 200) / 200;
      return AspectRatio(
        aspectRatio: 0.72,
        child: OrnateFrame(
          scale: k,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5 * k),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF6DE), Color(0xFFF6DDA2)],
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8 * k, vertical: 10 * k),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 170 * k,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ॐ',
                        style: AppText.hindi(26 * k, c: AppColors.gold)),
                    Text('श्री ${deity.hi}',
                        style: AppText.hindi(34 * k, c: AppColors.maroon)),
                    Text(title,
                        textAlign: TextAlign.center,
                        style: AppText.hindi(12 * k,
                            c: AppColors.maroon, w: FontWeight.w600)),
                    SizedBox(height: 8 * k),
                    Icon(Icons.temple_hindu_rounded,
                        size: 54 * k, color: AppColors.gold),
                    SizedBox(height: 8 * k),
                    Text('Created for',
                        style: AppText.body(8.5 * k, c: AppColors.muted)),
                    Text(name,
                        style: AppText.display(14 * k, c: AppColors.maroon)),
                    SizedBox(height: 4 * k),
                    Text('Sankalp',
                        style: AppText.body(8.5 * k, c: AppColors.muted)),
                    Text('${fmt(count)} Naam',
                        style: AppText.display(13 * k, c: AppColors.maroon)),
                    SizedBox(height: 6 * k),
                    Icon(Icons.spa_rounded,
                        size: 26 * k, color: AppColors.saffron),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class StatBox extends StatelessWidget {
  final String label;
  final String value;
  const StatBox({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Text(label, style: AppText.body(10.5, c: AppColors.muted)),
            const SizedBox(height: 2),
            Text(value,
                style: AppText.body(13.5,
                    c: AppColors.maroon, w: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

void showDemoSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, style: AppText.body(13, c: Colors.white)),
      backgroundColor: AppColors.maroon,
      behavior: SnackBarBehavior.floating,
    ));
}
