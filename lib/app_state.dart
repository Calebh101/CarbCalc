import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  Map<String, dynamic> cache = {};

  void setCache(value) {
    cache = value;
    notifyListeners();  // Notify listeners (widgets) that the state has changed
  }
}