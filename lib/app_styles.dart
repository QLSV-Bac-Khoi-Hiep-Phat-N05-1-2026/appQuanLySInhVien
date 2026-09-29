import 'package:flutter/material.dart';

class AppStyles {
  AppStyles._();

  static const Color primaryBlue = Color(0xFF0D47A1);
  static const Color accentBlue = Color(0xFF1976D2);
  static const Color softBlue = Color(0xFFD6E7FF);
  static const Color shadowBlue = Color(0x330D47A1);

  static const double cardRadius = 28;

  static const LinearGradient universityCardGradient = LinearGradient(
    colors: [primaryBlue, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<BoxShadow> universityCardShadow = [
    BoxShadow(color: shadowBlue, blurRadius: 18, offset: Offset(0, 9)),
  ];

  static const TextStyle universityName = TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle universitySubtitle = TextStyle(
    color: softBlue,
    fontSize: 14,
  );

  static const TextStyle studentInfoTitle = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle studentInfoText = TextStyle(color: Colors.white);

  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: Colors.white,
    minimumSize: const Size(0, 48),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}
