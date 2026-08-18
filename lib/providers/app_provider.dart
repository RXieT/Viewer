import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AppProvider extends ChangeNotifier {
  final StorageService storageService;
  late final ApiService apiService;
  late AppSettings settings;

  bool _isTestingDomain = false;
  String? _domainTestResult;
  bool _domainTestSuccess = false;

  AppProvider({required this.storageService}) {
    settings = storageService.loadSettings();
    apiService = ApiService(baseUrl: settings.cleanBaseUrl);
  }

  bool get isTestingDomain => _isTestingDomain;
  String? get domainTestResult => _domainTestResult;
  bool get domainTestSuccess => _domainTestSuccess;
  String get currentBaseUrl => settings.cleanBaseUrl;

  ThemeMode get themeMode {
    switch (settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
      case 'amoled':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  bool get isAmoled => settings.themeMode == 'amoled';

  Future<void> updateBaseUrl(String newUrl) async {
    var url = newUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    settings.baseUrl = url;
    if (!settings.savedDomains.contains(url)) {
      settings.savedDomains.insert(0, url);
    }
    apiService.setBaseUrl(url);
    await storageService.saveSettings(settings);
    notifyListeners();
  }

  Future<void> removeDomain(String domain) async {
    settings.savedDomains.remove(domain);
    await storageService.saveSettings(settings);
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    settings.themeMode = mode;
    await storageService.saveSettings(settings);
    notifyListeners();
  }

  Future<void> setUseThumbnails(bool value) async {
    settings.useThumbnails = value;
    await storageService.saveSettings(settings);
    notifyListeners();
  }

  Future<void> testCurrentDomain([String? customUrl]) async {
    _isTestingDomain = true;
    _domainTestResult = '正在检测域名连接状态...';
    _domainTestSuccess = false;
    notifyListeners();

    final testUrl = customUrl ?? settings.cleanBaseUrl;
    final res = await apiService.testConnection(testUrl);

    _isTestingDomain = false;
    _domainTestSuccess = res.isSuccess;
    if (res.isSuccess) {
      _domainTestResult = '✅ 连接成功！API 响应正常 (200 OK)';
    } else if (res.isCloudflareChallenge) {
      _domainTestResult = '⚠️ 触发 Cloudflare 防护 (${res.statusCode})，可使用内置网页验证';
    } else {
      _domainTestResult = '❌ 连接失败: ${res.error ?? '无法访问'}';
    }
    notifyListeners();
  }
}
