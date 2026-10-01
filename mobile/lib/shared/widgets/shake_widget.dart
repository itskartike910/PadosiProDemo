import 'package:flutter/material.dart';

/// Widget that shakes horizontally when [shake()] is called.
/// Adapted from Classy Professional Service.
class ShakeWidget extends StatefulWidget {
  final Widget child;
  const ShakeWidget({super.key, required this.child});

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void shake() => _ctrl.forward(from: 0.0);

  @override
  Widget build(BuildContext context) {
    final Animation<double> offset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -10.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 6.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Transform.translate(
        offset: Offset(offset.value, 0.0),
        child: child,
      ),
      child: widget.child,
    );
  }
}
