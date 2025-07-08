import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';
import '../models/bottom_menu_item.dart';

class AppStateProvider extends ChangeNotifier {
  String _currentUrl = EnvConfig.webUrl;
  int _currentTabIndex = 0;
  List<BottomMenuItem> _bottomMenuItems = [];
  bool _isLoading = false;
  bool _isSplashVisible = true;
  bool _isChatbotVisible = false;
  bool _isAppInBackground = false;

  // Getters
  String get currentUrl => _currentUrl;
  int get currentTabIndex => _currentTabIndex;
  List<BottomMenuItem> get bottomMenuItems => _bottomMenuItems;
  bool get isLoading => _isLoading;
  bool get isSplashVisible => _isSplashVisible;
  bool get isChatbotVisible => _isChatbotVisible;
  bool get isAppInBackground => _isAppInBackground;

  AppStateProvider() {
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadBottomMenuItems();
    await _loadSavedUrl();
    _hideSplashAfterDelay();
  }

  Future<void> _loadBottomMenuItems() async {
    try {
      _bottomMenuItems = BottomMenuItem.fromJsonString(
        EnvConfig.bottommenuItems,
      );
      if (_bottomMenuItems.isNotEmpty) {
        _currentUrl = _bottomMenuItems[0].url;
      }
      notifyListeners();
    } catch (e) {
      print('Error loading bottom menu items: $e');
      // Fallback to default items
      _bottomMenuItems = [
        BottomMenuItem(
          label: 'Home',
          icon: MenuIcon(type: 'preset', name: 'home_outlined'),
          url: EnvConfig.webUrl,
        ),
      ];
      notifyListeners();
    }
  }

  Future<void> _loadSavedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('last_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _currentUrl = savedUrl;
        // Find the corresponding tab index
        for (int i = 0; i < _bottomMenuItems.length; i++) {
          if (_bottomMenuItems[i].url == savedUrl) {
            _currentTabIndex = i;
            break;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading saved URL: $e');
    }
  }

  Future<void> _saveCurrentUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_url', _currentUrl);
    } catch (e) {
      print('Error saving URL: $e');
    }
  }

  void _hideSplashAfterDelay() {
    if (EnvConfig.isSplash) {
      final duration = int.tryParse(EnvConfig.splashDuration) ?? 4;
      Future.delayed(Duration(seconds: duration), () {
        _isSplashVisible = false;
        notifyListeners();
      });
    } else {
      _isSplashVisible = false;
      notifyListeners();
    }
  }

  // Methods
  void setCurrentUrl(String url) {
    _currentUrl = url;
    _saveCurrentUrl();
    notifyListeners();
  }

  void setCurrentTabIndex(int index) {
    if (index >= 0 && index < _bottomMenuItems.length) {
      _currentTabIndex = index;
      _currentUrl = _bottomMenuItems[index].url;
      _saveCurrentUrl();
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void toggleChatbot() {
    _isChatbotVisible = !_isChatbotVisible;
    notifyListeners();
  }

  void hideChatbot() {
    _isChatbotVisible = false;
    notifyListeners();
  }

  void showChatbot() {
    _isChatbotVisible = true;
    notifyListeners();
  }

  void navigateToUrl(String url) {
    _currentUrl = url;
    _saveCurrentUrl();
    notifyListeners();
  }

  void refreshCurrentPage() {
    // This will trigger a refresh in the WebView
    notifyListeners();
  }

  // Helper methods
  bool isCurrentUrl(String url) {
    return _currentUrl == url;
  }

  BottomMenuItem? getCurrentMenuItem() {
    if (_currentTabIndex >= 0 && _currentTabIndex < _bottomMenuItems.length) {
      return _bottomMenuItems[_currentTabIndex];
    }
    return null;
  }

  void updateBottomMenuItems(List<BottomMenuItem> items) {
    _bottomMenuItems = items;
    if (_bottomMenuItems.isNotEmpty &&
        _currentTabIndex >= _bottomMenuItems.length) {
      _currentTabIndex = 0;
      _currentUrl = _bottomMenuItems[0].url;
    }
    notifyListeners();
  }

  // Notification handling methods
  void updateCurrentUrl(String url) {
    _currentUrl = url;
    _saveCurrentUrl();
    notifyListeners();
  }

  void setAppInBackground(bool inBackground) {
    _isAppInBackground = inBackground;
    notifyListeners();
  }

  void bringAppToForeground() {
    _isAppInBackground = false;
    notifyListeners();
  }
}
