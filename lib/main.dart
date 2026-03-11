import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'repositories/food_repository.dart';
import 'services/food_ai_service.dart';
import 'services/nutrition_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final storageService = StorageService();
  await storageService.initialize();

  final aiService = FoodAiService();
  try {
    await aiService.loadModel();
  } catch (_) {
    // App still starts; scan flow handles model errors with UI feedback/fallback.
  }

  runApp(
    FoodScannerApp(
      storageService: storageService,
      aiService: aiService,
    ),
  );
}

class FoodScannerApp extends StatelessWidget {
  const FoodScannerApp({
    super.key,
    required this.storageService,
    required this.aiService,
  });

  final StorageService storageService;
  final FoodAiService aiService;

  @override
  Widget build(BuildContext context) {
    final repository = FoodRepositoryImpl(
      aiService: aiService,
      nutritionService: NutritionService(),
      storageService: storageService,
    );

    return MultiProvider(
      providers: [
        Provider<FoodRepository>.value(value: repository),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Food Scanner',
        themeMode: ThemeMode.system,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
