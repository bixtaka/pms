import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/work_type_state.dart';

class ProcessStepSelector extends StatelessWidget {
  final Function(String) onProcessChanged;
  const ProcessStepSelector({super.key, required this.onProcessChanged});

  @override
  Widget build(BuildContext context) {
    final workTypeState = Provider.of<WorkTypeState>(context);
    final categories = WorkTypeState.categoryList;
    final selectedCategory = workTypeState.selectedCategory;

    return Row(
      children: categories.map((category) {
        final isSelected = category == selectedCategory;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
              foregroundColor: isSelected ? Colors.white : Colors.black87,
              side: BorderSide(
                color: isSelected ? Colors.blue : Colors.grey[400]!,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            onPressed: () {
              if (isSelected) {
                workTypeState.setCategory('');
                onProcessChanged('');
              } else {
                workTypeState.setCategory(category);
                onProcessChanged(category);
              }
            },
            child: Text(category),
          ),
        );
      }).toList(),
    );
  }
}
