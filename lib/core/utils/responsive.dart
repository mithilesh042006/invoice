import 'package:flutter/material.dart';

/// Responsive layout helpers for Smart Shop Manager.
/// Uses a single breakpoint at 600px to differentiate mobile vs desktop.
class Responsive {
  Responsive._();

  /// Mobile breakpoint width in logical pixels.
  static const double mobileBreakpoint = 600;

  /// Returns true if the screen width is below [mobileBreakpoint].
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Returns adaptive padding: 12 on mobile, 24 on desktop.
  static EdgeInsets screenPadding(BuildContext context) =>
      EdgeInsets.all(isMobile(context) ? 12 : 24);
}
