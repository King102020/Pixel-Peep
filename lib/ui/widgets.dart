import 'package:flutter/material.dart';
import 'package:pixel_peep/services/audio_service.dart';

/// Shared colours and widgets so every menu looks like one game.
abstract final class Palette {
  static const background = Color(0xFF211F30);
  static const panel = Color(0xFF2E2A45);
  static const panelBorder = Color(0xFF4B4470);
  static const accent = Color(0xFFFFD54A);
  static const text = Color(0xFFF5F1FF);
  static const muted = Color(0xFF9D96C2);
}

const pixelText = TextStyle(
  color: Palette.text,
  fontWeight: FontWeight.w900,
  letterSpacing: 1.2,
  shadows: [Shadow(color: Colors.black54, offset: Offset(2, 2))],
);

/// Dims the game behind a menu. Content scrolls when the window is too short,
/// so no button is ever cut off on a small phone.
class Scrim extends StatelessWidget {
  const Scrim({super.key, required this.child, this.opacity = 0.75});
  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Palette.background.withValues(alpha: opacity),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (_, box) => ScrollHint(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: box.maxHeight,
                  minWidth: box.maxWidth,
                ),
                child: Center(
                  child: Padding(padding: const EdgeInsets.all(8), child: child),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Vertical scroll view with an always-visible scrollbar, so players can
/// tell there is more below.
class ScrollHint extends StatefulWidget {
  const ScrollHint({super.key, required this.child});
  final Widget child;

  @override
  State<ScrollHint> createState() => _ScrollHintState();
}

class _ScrollHintState extends State<ScrollHint> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        child: SingleChildScrollView(controller: _controller, child: widget.child),
      );
}

/// True on short windows (phone landscape), where menus use smaller type.
bool isShortScreen(BuildContext context) => MediaQuery.sizeOf(context).height < 420;

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = 20});
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Palette.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Palette.panelBorder, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(0, 6))],
        ),
        child: child,
      );
}

/// Chunky text button with a press bounce and click sound.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = Palette.accent,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              AudioService.instance.playSfx(Sfx.buttonClick);
              widget.onPressed!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.93 : 1,
        duration: const Duration(milliseconds: 80),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black26, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  offset: Offset(0, _down ? 1 : 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Palette.background, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: pixelText.copyWith(
                    color: Palette.background,
                    fontSize: 16,
                    shadows: const [],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 18});
  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < stars ? Palette.accent : Palette.muted,
              size: size,
            ),
        ],
      );
}

String formatTime(double seconds) {
  final m = seconds ~/ 60;
  final s = (seconds % 60).floor().toString().padLeft(2, '0');
  return '$m:$s';
}


/// Lays [builder]'s widget over the letterboxed 16:9 playfield so in-game UI
/// lines up with the game on any window shape.
class GameRect extends StatelessWidget {
  const GameRect({super.key, required this.builder});
  final Widget Function(Size rect) builder;

  static const double aspect = 16 / 9;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        var w = box.maxWidth, h = box.maxHeight;
        if (w / h > aspect) {
          w = h * aspect;
        } else {
          h = w / aspect;
        }
        return Center(
          child: SizedBox(width: w, height: h, child: builder(Size(w, h))),
        );
      });
}
