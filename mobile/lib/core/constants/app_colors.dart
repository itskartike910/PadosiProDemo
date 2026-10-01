import 'package:flutter/material.dart';

/// PadosiPro color palette — light mode only
/// Inspired by PadosiPro reference site: warm off-white + teal-green
abstract final class AppColors {
  // ── Brand Primary (Pine Teal) ────────────────────────────────────────────
  static const Color primary      = Color(0xFF1E5E52);
  static const Color primaryLight = Color(0xFF2E8575);
  static const Color primaryDark  = Color(0xFF123D35);

  // ── Brand Secondary & Accents (Classy Palette) ───────────────────────────
  static const Color secondary      = Color(0xFF00B4CC); // Electric Cyan
  static const Color secondaryLight = Color(0xFF67EEFF);
  static const Color secondaryDark  = Color(0xFF0090A3);

  static const Color accent       = Color(0xFFFF8C42); // Vivid Orange
  static const Color accentLight  = Color(0xFFFFB078);
  static const Color accentGold   = Color(0xFFFFD700); // Electric Gold
  static const Color accentCoral  = Color(0xFFFF6B8A); // Coral Pink
  static const Color accentGreen  = Color(0xFF05CC78); // Neon Mint
  static const Color accentPurple = Color(0xFF8B5CF6); // Electric Violet

  // ── Background / Surface (Light Mode) ─────────────────────────────────────
  static const Color background   = Color(0xFFF8FAF9);
  static const Color surface      = Colors.white;
  static const Color card         = Colors.white;
  static const Color cardElevated = Color(0xFFF2F6F5);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF080810);
  static const Color textHeading   = Color(0xFF102A24);
  static const Color textSecondary = Color(0xFF5A756E);
  static const Color textMuted     = Color(0xFF8DA39D);
  static const Color textHint      = Color(0xFFA5B7B2);

  // ── Border / Divider ─────────────────────────────────────────────────────
  static const Color divider  = Color(0xFFE2ECE8);
  static const Color border   = Color(0xFFD6E2DE);

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF05CC78);
  static const Color error   = Color(0xFFE53E3E);
  static const Color warning = Color(0xFFFF8C42);
  static const Color info    = Color(0xFF00B4CC);

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E5E52), Color(0xFF123D35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E5E52), Color(0xFF00B4CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C42)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF00B4CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coralGradient = LinearGradient(
    colors: [Color(0xFFFF6B8A), Color(0xFFCC3050)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mintGradient = LinearGradient(
    colors: [Color(0xFF10F99A), Color(0xFF05CC78)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF8FAF9), Color(0xFFF0F5F3)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
