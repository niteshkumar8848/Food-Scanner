import 'package:flutter/material.dart';

import '../models/food_scan_result.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/result_screen.dart';
import '../screens/scan_screen.dart';

class AppRoutes {
  static const home = '/';
  static const scan = '/scan';
  static const result = '/result';
  static const history = '/history';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case scan:
        return MaterialPageRoute(builder: (_) => const ScanScreen());
      case history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case result:
        final data = settings.arguments;
        if (data is! FoodScanResult) {
          return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
        return MaterialPageRoute(builder: (_) => ResultScreen(result: data));
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}
