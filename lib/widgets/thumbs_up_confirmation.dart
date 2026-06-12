import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Centered, double-size thumbs-up confirmation overlay.
///
/// Replaces the old bottom-right SuccessToast: a large gold thumbs-up on a
/// rounded navy card in the CENTER of the screen, with an optional short
/// message below. Scales in with a subtle overshoot, holds, then fades out
/// after ~1.6 seconds. Non-blocking — taps pass straight through it.
void showThumbsUpConfirmation(BuildContext context, {String? message}) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _ThumbsUpConfirmation(
      message: message,
      onDone: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

class _ThumbsUpConfirmation extends StatefulWidget {
  final String? message;
  final VoidCallback onDone;

  const _ThumbsUpConfirmation({this.message, required this.onDone});

  @override
  State<_ThumbsUpConfirmation> createState() => _ThumbsUpConfirmationState();
}

class _ThumbsUpConfirmationState extends State<_ThumbsUpConfirmation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    // Total ~1.6s: quick scale-in with overshoot, hold, then fade out.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.08).chain(CurveTween(curve: Curves.easeOut)), weight: 14),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 56),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.92), weight: 20),
    ]).animate(_controller);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
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
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, child) => Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: child,
              ),
            ),
            child: Container(
              constraints: const BoxConstraints(minWidth: 260, maxWidth: 420),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.95),
                borderRadius: AppRadius.xlBR,
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyDark.withValues(alpha: 0.45),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Double the old 56px badge: large thumbs-up in gold
                  const Icon(
                    Icons.thumb_up_rounded,
                    color: AppColors.gold,
                    size: 112,
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: AppSpacing.base),
                    Text(
                      widget.message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.white,
                        fontSize: AppTextStyles.titleSize,
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
