import 'package:flutter/material.dart';

/// Centralized color palette for Smart Shop Manager.
/// Deep indigo primary with teal accents — professional dark theme.
class AppColors {
  AppColors._();

  // ── Primary ──
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42DB);

  // ── Accent ──
  static const Color accent = Color(0xFF00D9A6);
  static const Color accentLight = Color(0xFF5CFFDA);
  static const Color accentDark = Color(0xFF00A67E);

  // ── Surface / Background ──
  static const Color background = Color(0xFF0F1123);
  static const Color surface = Color(0xFF1A1D3A);
  static const Color surfaceLight = Color(0xFF252A4A);
  static const Color surfaceCard = Color(0xFF1E2240);

  // ── Text ──
  static const Color textPrimary = Color(0xFFEAEAF6);
  static const Color textSecondary = Color(0xFF9E9EB8);
  static const Color textHint = Color(0xFF6B6B8D);

  // ── Status ──
  static const Color success = Color(0xFF2ED47A);
  static const Color warning = Color(0xFFFFB946);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF4DA6FF);

  // ── Borders / Dividers ──
  static const Color border = Color(0xFF2D3154);
  static const Color divider = Color(0xFF252850);

  // ── Payment Mode Colors ──
  static const Color cash = Color(0xFF2ED47A);
  static const Color upi = Color(0xFF6C63FF);
  static const Color card = Color(0xFFFFB946);

  // ── Sidebar ──
  static const Color sidebarBg = Color(0xFF141633);
  static const Color sidebarSelected = Color(0xFF6C63FF);
}
