import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../repositories/food_repository.dart';
import '../widgets/food_card.dart';
import 'viewmodels/history_view_model.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final vm = HistoryViewModel(repository: context.read<FoodRepository>());
        vm.loadHistory();
        return vm;
      },
      child: const _HistoryScreenBody(),
    );
  }
}

class _HistoryScreenBody extends StatelessWidget {
  const _HistoryScreenBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Scan History',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: vm.setQuery,
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: 'Search food...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Filter chips
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: vm.filter == HistoryFilter.all,
                          onTap: () => vm.setFilter(HistoryFilter.all),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Healthy',
                          isSelected: vm.filter == HistoryFilter.healthy,
                          onTap: () => vm.setFilter(HistoryFilter.healthy),
                          isDark: isDark,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Risky',
                          isSelected: vm.filter == HistoryFilter.risky,
                          onTap: () => vm.setFilter(HistoryFilter.risky),
                          isDark: isDark,
                          color: const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // History list
            Expanded(
              child: vm.isLoading
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const CircularProgressIndicator(),
                      ),
                    )
                  : vm.items.isEmpty
                      ? _EmptyState(isDark: isDark)
                      : ListView.builder(
                          itemCount: vm.items.length,
                          itemBuilder: (context, index) {
                            final item = vm.items[index];
                            return FoodCard(
                              item: item,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.result,
                                arguments: item,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? const Color(0xFF10B981);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? chipColor.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? chipColor
                : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? chipColor
                : (isDark ? Colors.white60 : Colors.grey.shade600),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 48,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No matching history found',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning food to build your history',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
