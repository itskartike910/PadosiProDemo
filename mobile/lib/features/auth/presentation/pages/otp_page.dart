import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/swipe_confirm_button.dart';
import '../../presentation/providers/auth_provider.dart';

class OtpPage extends ConsumerStatefulWidget {
  final String email;
  final String phoneNumber;
  const OtpPage({super.key, required this.email, required this.phoneNumber});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage>
    with SingleTickerProviderStateMixin {
  final _focusNode     = FocusNode();
  final _otpController = TextEditingController();

  String  _otp         = '';
  bool    _canResend   = false;
  int     _secondsLeft = 60;
  Timer?  _timer;

  bool    _isSuccess    = false;
  bool    _hasError     = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestKeyboard());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _requestKeyboard() {
    if (!mounted) return;
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
      Future.microtask(() {
        if (mounted) FocusScope.of(context).requestFocus(_focusNode);
      });
    } else {
      FocusScope.of(context).requestFocus(_focusNode);
    }
  }

  void _startResendTimer() {
    setState(() { _secondsLeft = 60; _canResend = false; });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _verify() async {
    if (_otp.length != 6) return;
    setState(() { _hasError = false; _errorMessage = null; });
    await ref.read(authProvider.notifier).verifyOtp(
          email: widget.email, otp: _otp);
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    _otpController.clear();
    setState(() { _otp = ''; _hasError = false; _errorMessage = null; _isSuccess = false; });
    _startResendTimer();
    await ref.read(authProvider.notifier).sendOtp(
          phone: widget.phoneNumber, email: widget.email);
  }

  void _handleOtpChanged(String value) {
    if (value.length > 6) return;
    setState(() {
      _otp = value;
      _hasError = false;
      _errorMessage = null;
    });
    if (value.length == 6) {
      _verify();
    }
  }

  void _handleResetShake() {
    setState(() { _hasError = false; _otp = ''; _otpController.clear(); });
    _requestKeyboard();
  }

  void _goBack() {
    ref.read(authProvider.notifier).resetToUnauthenticated();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next is AuthSuccessPending) {
        // Keep the hexagon rotating and alive, then collapse into the checkmark
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) {
            setState(() => _isSuccess = true);
          }
        });
        // After collapse checkmark celebration, finalize success transition
        Future.delayed(const Duration(milliseconds: 2700), () {
          if (mounted) {
            ref.read(authProvider.notifier).finalizeSuccess(next.user);
          }
        });
      } else if (next is AuthOtpSent && next.error != null) {
        // Wrong OTP — stay on this page, show error and shake
        setState(() {
          _hasError     = true;
          _errorMessage = next.error;
        });
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0F9F7), Color(0xFFF5F0E8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.md),
                  _buildBackButton(),
                  const SizedBox(height: AppSizes.xl),
                  _buildHeader(),
                  const SizedBox(height: AppSizes.lg),

                  // ── Hidden capture field ───────────────────────────────
                  SizedBox(
                    width: 0,
                    height: 0,
                    child: TextField(
                      controller: _otpController,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 6,
                      onChanged: _handleOtpChanged,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                  ),

                  // ── Animated hexagon OTP field ─────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _requestKeyboard,
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedHexagonOtpField(
                        otp: _otp,
                        isOtpComplete: _otp.length == 6,
                        isVerifying: isLoading,
                        isSuccess: _isSuccess,
                        hasError: _hasError,
                        onShakeCompleted: _handleResetShake,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSizes.lg),

                  _buildResend(),
                  const SizedBox(height: AppSizes.sm),
                  _buildWrongEmailButton(),
                  const SizedBox(height: AppSizes.lg),

                  SwipeConfirmButton(
                    label: _isSuccess
                        ? 'Verified ✓'
                        : (isLoading ? 'Verifying...' : 'Verify OTP'),
                    isLoading: isLoading,
                    isDeactivated: _otp.length != 6 || _isSuccess,
                    isAutoSlide: _otp.length == 6 && !_isSuccess,
                    onConfirmed: _verify,
                  ),
                  const SizedBox(height: AppSizes.xl),

                  _buildMessageBox(),
                  const SizedBox(height: AppSizes.xxxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() => GestureDetector(
        onTap: _goBack,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary, size: 16),
        ),
      );

  Widget _buildHeader() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFF1E5E52), Color(0xFF2D7A6E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(b),
            child: const Text(
              'Verify your email',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            widget.email.isNotEmpty
                ? 'Code sent to ${widget.email}'
                : 'Enter the 6-digit code sent to your email',
            style: const TextStyle(color: Color(0xFF4A6B62), fontSize: 14),
          ),
        ],
      );

  Widget _buildResend() => Center(
        child: _canResend
            ? TextButton(
                onPressed: _resend,
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: const Text('Resend OTP',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              )
            : RichText(
                text: TextSpan(
                  style: const TextStyle(color: Color(0xFF4A6B62), fontSize: 14),
                  children: [
                    const TextSpan(text: 'Resend code in '),
                    TextSpan(
                      text: '${_secondsLeft}s',
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
      );

  Widget _buildWrongEmailButton() => Center(
        child: TextButton(
          onPressed: _goBack,
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF4A6B62)),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_rounded, size: 14),
              SizedBox(width: 6),
              Text(
                'Incorrect email? Use a different address',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline),
              ),
            ],
          ),
        ),
      );

  Widget _buildMessageBox() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F4F1).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.mark_email_unread_rounded, size: 32, color: AppColors.primary),
            SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Check your inbox',
                      style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  SizedBox(height: 2),
                  Text(
                    "We've sent a 6-digit verification code. It should arrive shortly.",
                    style: TextStyle(color: Color(0xFF4A6B62), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Animated Hexagon OTP Node Field with Neon Rotating Edges
// ═══════════════════════════════════════════════════════════════════════════════
class AnimatedHexagonOtpField extends StatefulWidget {
  final String otp;
  final bool isOtpComplete;
  final bool isVerifying;
  final bool isSuccess;
  final bool hasError;
  final VoidCallback onShakeCompleted;

  const AnimatedHexagonOtpField({
    super.key,
    required this.otp,
    required this.isOtpComplete,
    required this.isVerifying,
    required this.isSuccess,
    required this.hasError,
    required this.onShakeCompleted,
  });

  @override
  State<AnimatedHexagonOtpField> createState() => _AnimatedHexagonOtpFieldState();
}

class _AnimatedHexagonOtpFieldState extends State<AnimatedHexagonOtpField>
    with TickerProviderStateMixin {
  // ── Stage animations ──────────────────────────────────────────────────────
  late AnimationController _layoutCtrl;
  late AnimationController _edgeCtrl;
  late AnimationController _loaderCtrl;
  late AnimationController _collapseCtrl;
  late AnimationController _shakeCtrl;

  late Animation<double> _layoutAnim;
  late Animation<double> _edgeAnim;
  late Animation<double> _loaderAnim;
  late Animation<double> _collapseAnim;

  // ── Per-digit pop animations (one per node) ────────────────────────────────
  late List<AnimationController> _popCtrls;
  late List<Animation<double>>   _popAnims;

  int _prevOtpLength = 0;

  @override
  void initState() {
    super.initState();

    _layoutCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _layoutAnim = CurvedAnimation(parent: _layoutCtrl, curve: Curves.easeInOutBack);

    _edgeCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _edgeAnim   = CurvedAnimation(parent: _edgeCtrl, curve: Curves.easeInOutCubic);

    _loaderCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _loaderAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_loaderCtrl);

    _collapseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _collapseAnim = CurvedAnimation(parent: _collapseCtrl, curve: Curves.easeInOutCubic);

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

    // Per-digit pop controllers
    _popCtrls = List.generate(6, (_) =>
        AnimationController(vsync: this, duration: const Duration(milliseconds: 200)));
    _popAnims = _popCtrls.map((c) =>
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0),  weight: 1),
        ]).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
    ).toList();

    for (final c in [_layoutCtrl, _edgeCtrl, _loaderCtrl, _collapseCtrl, _shakeCtrl, ..._popCtrls]) {
      c.addListener(() => setState(() {}));
    }

    _shakeCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onShakeCompleted();
        _shakeCtrl.reset();
      }
    });
  }

  @override
  void dispose() {
    _layoutCtrl.dispose();
    _edgeCtrl.dispose();
    _loaderCtrl.dispose();
    _collapseCtrl.dispose();
    _shakeCtrl.dispose();
    for (final c in _popCtrls) { c.dispose(); }

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnimatedHexagonOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ── Digit pop punch ───────────────────────────────────────────────────────
    final newLen = widget.otp.length;
    final oldLen = _prevOtpLength;
    if (newLen > oldLen && newLen <= 6) {
      _popCtrls[newLen - 1].forward(from: 0.0);
    }
    _prevOtpLength = newLen;

    // ── Arrange into hexagon on 6th digit or when verifying ──────────────────
    final shouldBeInHexagon = widget.isOtpComplete || widget.isVerifying;
    if (shouldBeInHexagon && !_layoutCtrl.isCompleted && !_layoutCtrl.isAnimating && !widget.hasError) {
      _layoutCtrl.forward().then((_) {
        _edgeCtrl.forward().then((_) {
          if (widget.isVerifying || widget.isOtpComplete) {
            _loaderCtrl.repeat();
          }
        });
      });
    } else if (widget.isVerifying && !_loaderCtrl.isAnimating && _edgeCtrl.isCompleted) {
      _loaderCtrl.repeat();
    }

    // ── Success: stop rotation, collapse into green checkmark ─────────────────
    if (widget.isSuccess && !oldWidget.isSuccess) {
      _loaderCtrl.stop();
      _edgeCtrl.reset();
      _collapseCtrl.forward();
    }

    // ── Error: stop, shake, and reverse back to horizontal row ────────────────
    if (widget.hasError && !oldWidget.hasError) {
      _loaderCtrl.stop();
      _shakeCtrl.forward(from: 0.0).then((_) {
        _layoutCtrl.reverse();
        _edgeCtrl.reset();
        _collapseCtrl.reset();
      });
    }

    // ── Reset when cleared ───────────────────────────────────────────────────
    if (!widget.isOtpComplete && oldWidget.hasError) {
      _layoutCtrl.reset();
      _edgeCtrl.reset();
      _loaderCtrl.reset();
      _collapseCtrl.reset();
      _prevOtpLength = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    const double centerX   = 150.0;
    const double centerY   = 100.0;
    const double hexRadius = 60.0;

    final List<Offset> positions = List.generate(6, (i) {
      final double gridX = 25.0 + i * 50.0;
      const double gridY = 100.0;

      final double angle = -math.pi / 2 + i * (2 * math.pi / 6);
      final double hexX  = centerX + hexRadius * math.cos(angle);
      final double hexY  = centerY + hexRadius * math.sin(angle);

      double cx = gridX + (hexX - gridX) * _layoutAnim.value;
      double cy = gridY + (hexY - gridY) * _layoutAnim.value;

      cx = cx + (centerX - cx) * _collapseAnim.value;
      cy = cy + (centerY - cy) * _collapseAnim.value;

      return Offset(cx, cy);
    });

    final Animation<double> shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0,   end: 12.0),  weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12.0,  end: -12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 8.0),   weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0,   end: -8.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0,  end: 0.0),   weight: 1),
    ]).animate(_shakeCtrl);

    final isVerifyingActive = widget.isVerifying || _loaderCtrl.isAnimating;

    return SizedBox(
      width: 300,
      height: 200,
      child: Transform.translate(
        offset: Offset(shakeOffset.value, 0.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Connecting Hexagon Edges with Rotating Neon Highlighting ──
            Positioned.fill(
              child: CustomPaint(
                painter: _OtpNetworkPainter(
                  positions: positions,
                  edgeProgress: _edgeAnim.value,
                  drawEdges: _layoutCtrl.value > 0.4,
                  loaderProgress: _loaderAnim.value,
                  isVerifying: isVerifyingActive && !widget.isSuccess,
                  hasError: widget.hasError,
                ),
              ),
            ),

            // ── 6 Digit Node Boxes ──────────────────────────────────────────
            if (!widget.isSuccess || !_collapseCtrl.isCompleted)
              ...List.generate(6, (i) {
                final pos       = positions[i];
                final digit     = widget.otp.length > i ? widget.otp[i] : '';
                final isCurrent = widget.otp.length == i;
                final isFilled  = widget.otp.length > i;
                final collapseScale = (1.0 - _collapseAnim.value).clamp(0.0, 1.0);
                final nodeScale = _popAnims[i].value * collapseScale;

                final Color nodeBorder = widget.hasError
                    ? AppColors.error
                    : isCurrent
                        ? AppColors.primary
                        : isFilled
                            ? AppColors.primary.withValues(alpha: 0.55)
                            : AppColors.primary.withValues(alpha: 0.25);

                return Positioned(
                  left: pos.dx - 21.0,
                  top:  pos.dy - 21.0,
                  child: Transform.scale(
                    scale: nodeScale,
                    child: Container(
                      width:  42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: nodeBorder,
                          width: isCurrent ? 2.2 : 1.4,
                        ),
                        boxShadow: [
                          if (isCurrent)
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.22),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          if (isFilled && !isCurrent && !widget.hasError)
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 6,
                            ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Rotating neon outline around each box when verifying
                          if (isVerifyingActive && _edgeCtrl.isCompleted && !widget.isSuccess)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _NeonOutlinePainter(_loaderAnim.value),
                              ),
                            ),
                          // Digit number text
                          Center(
                            child: Text(
                              digit,
                              style: TextStyle(
                                color: widget.hasError
                                    ? AppColors.error
                                    : const Color(0xFF1A1A1A),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            // ── Single Green Success Checkmark Node ─────────────────────────
            if (widget.isSuccess && _collapseCtrl.isCompleted)
              Positioned(
                left: centerX - 25.0,
                top:  centerY - 25.0,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(parent: _collapseCtrl, curve: Curves.elasticOut),
                  ),
                  child: Container(
                    width:  50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C853).withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.check_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CustomPainter: Hexagon Connecting Edges with Clockwise Rotating Neon Tracer
// ═══════════════════════════════════════════════════════════════════════════════
class _OtpNetworkPainter extends CustomPainter {
  final List<Offset> positions;
  final double edgeProgress;
  final bool drawEdges;
  final double loaderProgress;
  final bool isVerifying;
  final bool hasError;

  _OtpNetworkPainter({
    required this.positions,
    required this.edgeProgress,
    required this.drawEdges,
    required this.loaderProgress,
    required this.isVerifying,
    this.hasError = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!drawEdges || positions.length < 6) return;

    // 1. Draw base hexagon perimeter lines (0->1, 1->2, 2->3, 3->4, 4->5, 5->0)
    final basePaint = Paint()
      ..color = hasError
          ? AppColors.error.withValues(alpha: 0.4)
          : const Color(0xFF1E5E52).withValues(alpha: 0.28)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const totalSegments  = 6;
    const progressPerSeg = 1.0 / totalSegments;

    for (int i = 0; i < totalSegments; i++) {
      final startCenter = positions[i];
      final endCenter   = positions[(i + 1) % totalSegments];
      final dir = endCenter - startCenter;
      final dist = dir.distance;
      if (dist <= 46.0) continue; // In horizontal row or collapsing, do not draw
      final unit = dir / dist;
      // Start and end 23px from node center so lines NEVER touch or go behind the 42x42 box
      final startPos = startCenter + unit * 23.0;
      final endPos   = endCenter - unit * 23.0;
      final segStart = i * progressPerSeg;

      if (edgeProgress > segStart) {
        final segProgress =
            ((edgeProgress - segStart) / progressPerSeg).clamp(0.0, 1.0);
        final currentEnd = Offset.lerp(startPos, endPos, segProgress)!;
        canvas.drawLine(startPos, currentEnd, basePaint);
      }
    }

    // 2. Highlighting rotating edge in clockwise sequence!
    // "suppose the highlight edge in between node 1 and 2, after rotating it should be between 2 and 3 then 3 and 4, similarly."
    if (isVerifying && edgeProgress >= 0.8) {
      final double activePos = (loaderProgress * totalSegments) % totalSegments;
      final int activeIndex  = activePos.floor() % totalSegments;
      final double segFrac   = activePos - activeIndex; // 0.0 to 1.0 along current edge

      final startCenter = positions[activeIndex];
      final endCenter   = positions[(activeIndex + 1) % totalSegments];
      final dir = endCenter - startCenter;
      final dist = dir.distance;
      if (dist > 46.0) {
        final unit = dir / dist;
        final startPos = startCenter + unit * 23.0;
        final endPos   = endCenter - unit * 23.0;

        // Outer glowing neon blur on active segment
        final glowPaint = Paint()
          ..color = const Color(0xFFFF9100).withValues(alpha: 0.55)
          ..strokeWidth = 7.5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

        // Bright neon orange line for active segment
        final activeEdgePaint = Paint()
          ..color = const Color(0xFFFF9100)
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(startPos, endPos, glowPaint);
        canvas.drawLine(startPos, endPos, activeEdgePaint);

        // High-intensity white/gold tracer traveling along the active edge
        final head = Offset.lerp(startPos, endPos, segFrac)!;
        final tail = Offset.lerp(startPos, endPos, (segFrac - 0.4).clamp(0.0, 1.0))!;
        final tracerPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 4.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(tail, head, tracerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_OtpNetworkPainter old) =>
      old.edgeProgress   != edgeProgress   ||
      old.drawEdges      != drawEdges      ||
      old.loaderProgress != loaderProgress ||
      old.isVerifying    != isVerifying    ||
      old.hasError       != hasError       ||
      old.positions      != positions;
}

// ═══════════════════════════════════════════════════════════════════════════════
// CustomPainter: Neon Orange Tracer Rotating Around Each Box Outline
// ═══════════════════════════════════════════════════════════════════════════════
class _NeonOutlinePainter extends CustomPainter {
  final double rotation;
  _NeonOutlinePainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF9100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final rect    = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect   = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    final path    = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();

    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final len    = metric.length;
      final start  = (rotation * len) % len;
      final sweep  = len * 0.38;
      final end    = (start + sweep) % len;

      final Path extract;
      if (end > start) {
        extract = metric.extractPath(start, end);
      } else {
        final p1 = metric.extractPath(start, len);
        final p2 = metric.extractPath(0, end);
        extract  = p1..addPath(p2, Offset.zero);
      }

      // Outer neon blur glow
      canvas.drawPath(
        extract,
        Paint()
          ..color = const Color(0xFFFF9100).withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
      );
      canvas.drawPath(extract, paint);
    }
  }

  @override
  bool shouldRepaint(_NeonOutlinePainter old) => old.rotation != rotation;
}
