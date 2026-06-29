import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('id');
  
  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    _loadLanguage();
  }

  void _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String? langCode = prefs.getString('language_code');
    if (langCode != null) {
      _currentLocale = Locale(langCode);
      notifyListeners();
    }
  }

  void changeLanguage(String langCode) async {
    _currentLocale = Locale(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', langCode);
    notifyListeners();
  }

  String translate(String key) {
    if (_currentLocale.languageCode == 'en') {
      return _en[key] ?? key;
    }
    return _id[key] ?? key;
  }

  static const Map<String, String> _id = {
    'dashboard': 'DASHBOARD',
    'kpi_stats': 'KPI & STATISTIK',
    'users': 'PENGGUNA',
    'products': 'PRODUK',
    'orders': 'PESANAN',
    'processed': 'TERPROSES',
    'unverified_dp': 'MENUNGGU DP',
    'recent_orders': 'PESANAN TERBARU',
    'view_all': 'LIHAT SEMUA',
    'record_masterpiece': 'CATAT KARYA BARU',
    'exit_suite': 'KELUAR SUITE',
    'user_monitoring': 'PEMANTAUAN PENGGUNA',
    'product_monitoring': 'PEMANTAUAN PRODUK',
    'order_monitoring': 'PEMANTAUAN PESANAN',
    'language': 'BAHASA',
    'select_language': 'PILIH BAHASA',
  };

  static const Map<String, String> _en = {
    'dashboard': 'DASHBOARD',
    'kpi_stats': 'KPI & STATISTICS',
    'users': 'USERS',
    'products': 'PRODUCTS',
    'orders': 'ORDERS',
    'processed': 'PROCESSED',
    'unverified_dp': 'WAITING FOR DP',
    'recent_orders': 'RECENT ORDERS',
    'view_all': 'VIEW ALL',
    'record_masterpiece': 'RECORD NEW MASTERPIECE',
    'exit_suite': 'EXIT SUITE',
    'user_monitoring': 'USER MONITORING',
    'product_monitoring': 'PRODUCT MONITORING',
    'order_monitoring': 'ORDER MONITORING',
    'language': 'LANGUAGE',
    'select_language': 'SELECT LANGUAGE',
  };
}
