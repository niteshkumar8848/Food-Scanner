import 'package:flutter/material.dart';

import '../models/food_scan_result.dart';
import '../services/nutrition_service.dart';
import '../utils/health_score_calculator.dart';
import '../widgets/health_score_meter.dart';
import '../widgets/nutrition_card.dart';
import '../widgets/result_summary.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.result});

  final FoodScanResult result;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late FoodScanResult _current;
  bool _isUpdating = false;
  String? _predictionError;
  final NutritionService _nutritionService = NutritionService();

  @override
  void initState() {
    super.initState();
    _current = widget.result;
  }

  Future<void> _selectPrediction(PredictionCandidate candidate) async {
    if (_isUpdating) return;
    if (_current.foodName.toLowerCase() == candidate.label.toLowerCase()) return;

    setState(() {
      _isUpdating = true;
      _predictionError = null;
    });

    try {
      final profile = await _nutritionService.fetchProfile(candidate.label);
      final warnings = HealthScoreCalculator.evaluate(profile.nutrition).warnings;
      setState(() {
        _current = _current.copyWith(
          foodName: profile.label,
          confidence: candidate.confidence,
          nutrition: profile.nutrition,
          healthScore: profile.healthScore,
          avoidFor: profile.avoidFor,
          recommendedIntake: HealthScoreCalculator.recommendation(profile.healthScore),
          riskWarnings: warnings,
        );
      });
    } catch (_) {
      setState(() {
        _predictionError = 'Failed to update nutrition for selected prediction.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF334155)]
                : [const Color(0xFF10B981), const Color(0xFF14B8A6), const Color(0xFF06B6D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                floating: true,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                ),
                title: const Text(
                  'Scan Result',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                centerTitle: true,
              ),
              
              // Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Result Summary
                    ResultSummary(
                      foodName: _current.foodName,
                      confidence: _current.confidence,
                      recommendation: _current.recommendedIntake,
                    ),
                    const SizedBox(height: 16),
                    
                    // Health Score
                    HealthScoreMeter(score: _current.healthScore),
                    const SizedBox(height: 16),
                    
                    // Top Predictions
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.psychology_rounded,
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Top Predictions',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ..._current.topPredictions.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _isUpdating ? null : () => _selectPrediction(item),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: item.label.toLowerCase() == _current.foodName.toLowerCase()
                                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : Colors.grey.shade50),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: item.label.toLowerCase() == _current.foodName.toLowerCase()
                                          ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.label,
                                          style: TextStyle(
                                            fontWeight: item.label.toLowerCase() ==
                                                    _current.foodName.toLowerCase()
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${(item.confidence * 100).toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_isUpdating)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: LinearProgressIndicator(minHeight: 4),
                            ),
                          if (_predictionError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Theme.of(context).colorScheme.error,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _predictionError!,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.error,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_current.topPredictions.isEmpty)
                            Text(
                              'No additional predictions available.',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Who Should Avoid
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.health_and_safety_outlined,
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Who Should Avoid This Food',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_current.avoidFor.isEmpty)
                            Text(
                              'No specific restrictions listed.',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                              ),
                            ),
                          ..._current.avoidFor.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(
                                      e,
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Nutrition Analysis Header
                    Text(
                      'Nutrition Analysis (per 100g)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    
                    // Nutrition Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: MediaQuery.sizeOf(context).width > 650 ? 3 : 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        NutritionCard(
                          title: 'Calories',
                          value: _current.nutrition.calories.toStringAsFixed(0),
                          unit: 'kcal',
                          icon: Icons.local_fire_department_rounded,
                        ),
                        NutritionCard(
                          title: 'Sugar',
                          value: _current.nutrition.sugar.toStringAsFixed(1),
                          unit: 'g',
                          icon: Icons.cake_rounded,
                        ),
                        NutritionCard(
                          title: 'Fat',
                          value: _current.nutrition.fat.toStringAsFixed(1),
                          unit: 'g',
                          icon: Icons.opacity_rounded,
                        ),
                        NutritionCard(
                          title: 'Protein',
                          value: _current.nutrition.protein.toStringAsFixed(1),
                          unit: 'g',
                          icon: Icons.fitness_center_rounded,
                        ),
                        NutritionCard(
                          title: 'Fiber',
                          value: _current.nutrition.fiber.toStringAsFixed(1),
                          unit: 'g',
                          icon: Icons.grain_rounded,
                        ),
                        NutritionCard(
                          title: 'Sodium',
                          value: (_current.nutrition.sodium * 1000).toStringAsFixed(0),
                          unit: 'mg',
                          icon: Icons.water_drop_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
