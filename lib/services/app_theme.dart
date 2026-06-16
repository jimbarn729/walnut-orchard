import 'dart:ui';
import 'package:flutter/material.dart';

class AppTheme {
  static const Color bg = Color(0xFF0A0F0A);
  static const Color panel = Color(0xFF162016);
  static const Color panelBorder = Color(0xFF2A3A2A);
  static const Color text = Color(0xFFE0E0E0);
  static const Color muted = Color(0xFFA8B8A8);
  static const Color gold = Color(0xFFFFD740);
  static const List<Color> neutralGradient = [Color(0xFF1A2A1A), Color(0xFF0D140D)];

  static ThemeData get lightTheme => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bg,
        canvasColor: panel,
        colorScheme: const ColorScheme.dark(primary: Color(0xFF7CFC6E), surface: panel, onSurface: text),
        textTheme: ThemeData.dark().textTheme.apply(bodyColor: text, displayColor: text),
      );

  static ThemeData get darkTheme => lightTheme;

  static List<BoxShadow> neonGlow(Color color, {double blur = 12}) {
    return [BoxShadow(color: color.withOpacity(0.4), blurRadius: blur, spreadRadius: 1.5)];
  }

  static BoxDecoration glassDecoration({Color color = Colors.black54}) {
    return BoxDecoration(
      color: color.withOpacity(0.25),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white24, width: 1.0),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8))],
      gradient: LinearGradient(
        colors: [color.withOpacity(0.22), color.withOpacity(0.10)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}
