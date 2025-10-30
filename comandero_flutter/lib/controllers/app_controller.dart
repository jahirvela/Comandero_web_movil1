import 'package:flutter/material.dart';

class AppController extends ChangeNotifier {
  bool _isLoading = false;
  String _currentModule = '';
  int _selectedIndex = 0;

  bool get isLoading => _isLoading;
  String get currentModule => _currentModule;
  int get selectedIndex => _selectedIndex;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setCurrentModule(String module) {
    _currentModule = module;
    notifyListeners();
  }

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  // Métodos para navegación entre módulos
  void navigateToMesero() {
    _currentModule = 'mesero';
    _selectedIndex = 0;
    notifyListeners();
  }

  void navigateToCocinero() {
    _currentModule = 'cocinero';
    _selectedIndex = 1;
    notifyListeners();
  }

  void navigateToCajero() {
    _currentModule = 'cajero';
    _selectedIndex = 2;
    notifyListeners();
  }

  void navigateToCapitan() {
    _currentModule = 'capitan';
    _selectedIndex = 3;
    notifyListeners();
  }

  void navigateToAdmin() {
    _currentModule = 'admin';
    _selectedIndex = 4;
    notifyListeners();
  }
}

