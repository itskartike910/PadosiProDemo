import 'package:flutter/material.dart';
import 'swipe_confirm_button.dart';

/// Reusable signature pill confirm button matching the Login & OTP action style.
/// Supports tap, drag-to-confirm, and loading states.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SwipeConfirmButton(
      label: label,
      isLoading: isLoading,
      isDeactivated: onPressed == null,
      onConfirmed: () {
        if (onPressed != null) {
          onPressed!();
        }
      },
    );
  }
}
