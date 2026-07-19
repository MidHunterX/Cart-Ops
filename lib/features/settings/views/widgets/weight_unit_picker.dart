import 'package:flutter/material.dart';
import 'package:shopping_assist/features/settings/providers/settings_provider.dart';
import '../../data/settings_data.dart';

class WeightUnitPicker extends StatelessWidget {
  const WeightUnitPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text('Select Weight Unit', style: Theme.of(context).textTheme.titleLarge),
          ),
          ...weightUnitOptions.map((option) {
            return ListTile(
              title: Text('${option.name} (${option.unit})'),
              subtitle: Text(option.system),
              trailing: context.weightUnit == option.unit
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                context.settingsRead.setWeightUnit(option.unit);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
