import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF7F56D9);
  static const Color primaryLight = Color(0xFF9E77ED);
  static const Color primaryDark = Color(0xFF6941C6);
  static const Color background = Color(0xFFF9FAFB);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF667085);
  static const Color border = Color(0xFFEAECF0);
  static const Color success = Color(0xFF12B76A);
  static const Color warning = Color(0xFFF79009);
  static const Color error = Color(0xFFF04438);
}

class ApiConstants {
  // Replace with actual local IP or production URL.
  // For Android emulator pointing to local host use 10.0.2.2. For iOS emulator use 127.0.0.1.
  static const String baseUrl = 'http://192.168.1.38:8080'; // Updated to local network IP
}
