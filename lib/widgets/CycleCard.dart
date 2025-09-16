import 'package:cash_cache/model/Cycle.dart';
import 'package:flutter/material.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

class CycleCard extends StatelessWidget {
  const CycleCard({
    super.key,
    required this.currentCycle,
  });

  final Cycle currentCycle;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              currentCycle.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '₹${currentCycle.totalSpent.toStringAsFixed(2)} / ₹${currentCycle.budget.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: currentCycle.totalSpent > currentCycle.budget
                        ? Colors.red
                        : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 16),
            StepProgressIndicator(
              totalSteps: currentCycle.budget.toInt(),
              currentStep: currentCycle.totalSpent > currentCycle.budget
                  ? currentCycle.budget.toInt()
                  : currentCycle.totalSpent.toInt(),
              size: 12,
              padding: 0,
              selectedColor: currentCycle.totalSpent > currentCycle.budget
                  ? Colors.red
                  : Colors.yellow,
              unselectedColor: Colors.grey.shade300,
              roundedEdges: const Radius.circular(12),
              selectedGradientColor:
                  currentCycle.totalSpent > currentCycle.budget
                      ? const LinearGradient(
                          colors: [Colors.red, Colors.redAccent],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.yellowAccent, Colors.deepOrange],
                        ),
              unselectedGradientColor: LinearGradient(
                colors: [Colors.grey.shade200, Colors.grey.shade400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
