import 'package:flutter/material.dart';

class AppColors {
  static const Color backgroundColor = Color(0xFFFCFCFC);
  static const Color cardColor = Color(0xFFFFFFFF);

  static const Color primaryColor = Color(0xFF1297FD);
  static const Color secondaryColor = Color(0xFF40AAF8);
  static const Color lightBlue = Color(0xFF8BCAF9);

  static const Color borderLight = Color(0xFFE3E4E6);
  static const Color borderDark = Color(0xFFC3C3C5);

  static const Color whiteColor = Color(0xFFFFFFFF);

  static const Color blackTextColor = Color(0xFF1F2937);
  static const Color greyTextColor = Color(0xFF6B7280);
}

class ApiConstants {
  static const String baseUrl = 'http://192.168.29.141:8000/api';
  static const String login = '$baseUrl/login';
  static const String register = '$baseUrl/register-student';
}
