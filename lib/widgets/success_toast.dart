import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Lightweight animated success toast — shows a thumbs-up icon that scales in,
/// holds briefly, then fades out. Non-intrusive: sits in a corner without
/// blocking interaction. Call [SuccessToast.show] from any widget context.
class SuccessToast {
  SuccessToast._();

  /// Show the toast anchored to the bottom-right of the nearest [Overlay].
  /// [message] is optional — if provided, a short label appears under the icon.
  static void show(BuildContext context, {String? message}) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _SuccessToastWidget(
        message: message,
        onDone: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _SuccessToastWidget extends StatefulWidget {
  final String? message;
  final VoidCallback onDone;

  const _SuccessToastWidget({this.message, required this.onDone});

  @override
  State<_SuccessToastWidget> createState() => _SuccessToastWidgetState();
}

class _SuccessToastWidgetState extends State<_SuccessToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    // Total duration: 0→300ms scale-in, hold, then 300ms fade-out
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Scale: 0 → 1.15 (overshoot) → 1.0 in first 300ms, then hold
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 25),
    ]).animate(_controller);

    // Opacity: instant-on, hold, then fade out in last 25%
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 48,
      right: 32,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) => Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.thumb_up_rounded,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
              if (widget.message != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.message!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
