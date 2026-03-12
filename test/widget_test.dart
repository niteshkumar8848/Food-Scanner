import 'package:flutter_test/flutter_test.dart';
import 'package:food_scanner/services/nutrition_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NutritionService', () {
    test('matches labels with underscores and casing from the model', () async {
      final service = NutritionService();

      final profile = await service.fetchProfile('Smoothie_Bowl');

      expect(profile.label, 'Smoothie_Bowl');
    });

    test('normalizes separators when resolving profiles', () async {
      final service = NutritionService();

      final profile = await service.fetchProfile('sweet potato');

      expect(profile.label, 'sweet_potato');
    });

    test('returns the safe default when no reasonable match exists', () async {
      final service = NutritionService();

      final profile = await service.fetchProfile('definitely_not_a_real_food_label');

      expect(profile.label, 'Unknown Food');
    });
  });
}
