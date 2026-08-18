import 'package:flutter/material.dart';

class AppColors {
  // Brand / Theme Accents
  static const Color primary = Color(0xFFE58A2B); // Kemono amber/orange
  static const Color primaryLight = Color(0xFFFFB74D);
  static const Color primaryDark = Color(0xFFC76C12);
  static const Color accent = Color(0xFF64B5F6);

  // Dark Theme Backgrounds
  static const Color darkBackground = Color(0xFF121316);
  static const Color darkSurface = Color(0xFF1C1E24);
  static const Color darkCard = Color(0xFF242730);
  static const Color darkBorder = Color(0xFF2E323E);
  
  // AMOLED Backgrounds
  static const Color amoledBackground = Color(0xFF000000);
  static const Color amoledSurface = Color(0xFF0D0E11);
  static const Color amoledCard = Color(0xFF16171B);

  // Light Theme
  static const Color lightBackground = Color(0xFFF5F6F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E6EE);

  // Service Brand Colors
  static const Color patreon = Color(0xFFFF424D);
  static const Color fanbox = Color(0xFF0096FA);
  static const Color fantia = Color(0xFFFF4081);
  static const Color boosty = Color(0xFFF15F2C);
  static const Color gumroad = Color(0xFFFF90E8);
  static const Color discord = Color(0xFF5865F2);
  static const Color subscribestar = Color(0xFF2ECC71);
  static const Color afdian = Color(0xFF9466FF);
  static const Color onlyfans = Color(0xFF00AFF0);
  static const Color candfans = Color(0xFFE91E63);

  static Color getServiceColor(String? service) {
    if (service == null) return Colors.grey;
    switch (service.toLowerCase()) {
      case 'patreon':
        return patreon;
      case 'fanbox':
        return fanbox;
      case 'fantia':
        return fantia;
      case 'boosty':
        return boosty;
      case 'gumroad':
        return gumroad;
      case 'discord':
        return discord;
      case 'subscribestar':
        return subscribestar;
      case 'afdian':
        return afdian;
      case 'onlyfans':
        return onlyfans;
      case 'candfans':
        return candfans;
      default:
        return primary;
    }
  }

  static String getServiceDisplayName(String? service) {
    if (service == null) return '未知';
    switch (service.toLowerCase()) {
      case 'patreon':
        return 'Patreon';
      case 'fanbox':
        return 'Pixiv Fanbox';
      case 'fantia':
        return 'Fantia';
      case 'boosty':
        return 'Boosty';
      case 'gumroad':
        return 'Gumroad';
      case 'discord':
        return 'Discord';
      case 'subscribestar':
        return 'SubscribeStar';
      case 'afdian':
        return '爱发电 (Afdian)';
      case 'onlyfans':
        return 'OnlyFans';
      case 'candfans':
        return 'CandFans';
      default:
        return service.toUpperCase();
    }
  }
}
