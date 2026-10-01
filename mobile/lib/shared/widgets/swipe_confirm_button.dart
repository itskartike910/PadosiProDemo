import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

// ── Swipe Confirm Button ────────────────────────────────────────────────────
// Slide-to-confirm or tap to auto-animate. Adapted from Classy Professional
// Service, re-coloured in PadosiPro's warm teal palette (light mode only).
class SwipeConfirmButton extends StatefulWidget {
  final String label;
  final VoidCallback onConfirmed;
  final bool isLoading;
  final bool isDeactivated;

  /// When true, the button auto-slides to completion (e.g. 6th OTP digit typed)
  final bool isAutoSlide;
  final VoidCallback? onTapDisabled;
  final bool Function()? onValidate;

  const SwipeConfirmButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    required this.isLoading,
    this.isDeactivated = false,
    this.isAutoSlide = false,
    this.onTapDisabled,
    this.onValidate,
  });

  @override
  State<SwipeConfirmButton> createState() => _SwipeConfirmButtonState();
}

class _SwipeConfirmButtonState extends State<SwipeConfirmButton>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _dragOffset = 0.0;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic),
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SwipeConfirmButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When isAutoSlide becomes true (e.g. 6th OTP digit entered), trigger confirm
    if (widget.isAutoSlide && !oldWidget.isAutoSlide && !_confirmed) {
      _triggerConfirm();
    }
    // Reset if deactivated externally (e.g. OTP cleared after error)
    if (widget.isDeactivated && !oldWidget.isDeactivated && !widget.isAutoSlide) {
      setState(() {
        _confirmed = false;
        _dragOffset = 0.0;
      });
      _ctrl.reset();
    }
  }

  void _triggerConfirm() {
    if (widget.isDeactivated && !widget.isAutoSlide) {
      widget.onTapDisabled?.call();
      return;
    }
    if (_confirmed || widget.isLoading) return;
    if (widget.onValidate != null && !widget.onValidate!()) {
      setState(() => _dragOffset = 0.0);
      _ctrl.reset();
      return;
    }
    setState(() => _confirmed = true);
    _ctrl.forward().then((_) {
      widget.onConfirmed();
      // Auto-reset after 3 s so user can retry if backend rejects
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _confirmed = false;
            _dragOffset = 0.0;
          });
          _ctrl.reset();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isInactive = widget.isDeactivated && !widget.isAutoSlide;

    // Track background & border
    final Color trackBg = isInactive
        ? const Color(0xFFECEFF1).withValues(alpha: 0.8)
        : const Color(0xFFE6F4F1).withValues(alpha: 0.9);
    final Color trackBorder = isInactive
        ? const Color(0xFFCFD8DC).withValues(alpha: 0.6)
        : AppColors.primary.withValues(alpha: 0.35);

    return LayoutBuilder(builder: (context, constraints) {
      const handleSize = 48.0;
      final maxDrag = constraints.maxWidth - handleSize - 8.0;

      final double currentOffset = isInactive
          ? 0.0
          : (_ctrl.isAnimating
              ? _anim.value * maxDrag
              : (_confirmed ? maxDrag : _dragOffset.clamp(0.0, maxDrag)));

      final progress = maxDrag > 0 ? (currentOffset / maxDrag) : 0.0;

      // Text colour lerps from primary to white as handle moves right
      final Color textColor = isInactive
          ? const Color(0xFF90A4AE)
          : Color.lerp(
              AppColors.primaryDark,
              Colors.white,
              progress,
            )!;

      return GestureDetector(
        onTap: _triggerConfirm,
        onHorizontalDragUpdate: (widget.isLoading || isInactive)
            ? null
            : (details) {
                if (widget.onValidate != null && !widget.onValidate!()) return;
                setState(() {
                  _dragOffset += details.primaryDelta!;
                  _dragOffset = _dragOffset.clamp(0.0, maxDrag);
                });
              },
        onHorizontalDragEnd: (widget.isLoading || isInactive)
            ? null
            : (details) {
                if (_dragOffset >= maxDrag * 0.75) {
                  _triggerConfirm();
                } else {
                  setState(() => _dragOffset = 0.0);
                }
              },
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: trackBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: trackBorder, width: 1.4),
            boxShadow: [
              if (!isInactive)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // ── Active fill track gradient ──
              if (!isInactive)
                Container(
                  width: currentOffset + handleSize / 2 + 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFA8D5C8), Color(0xFF3D7A6B)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius:
                        BorderRadius.horizontal(left: Radius.circular(28)),
                  ),
                ),

              // ── Label / Loading ──
              Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      )
                    : Text(
                        widget.label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
              ),

              // ── Draggable handle ──
              Positioned(
                left: currentOffset + 4,
                child: Container(
                  width: handleSize,
                  height: handleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isInactive
                        ? const LinearGradient(
                            colors: [Color(0xFFB0BEC5), Color(0xFF90A4AE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [
                              Color(0xFF5A9E8D),
                              AppColors.primaryDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    boxShadow: [
                      if (!isInactive)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                      color: isInactive
                          ? Colors.white
                          : Color.lerp(Colors.white, Colors.white, progress),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
