import 'package:flutter/material.dart';
import '../../data/settings_data.dart';

class FabLocationPicker extends StatelessWidget {
  final String currentLocation;
  final Function(String) onChanged;

  const FabLocationPicker({super.key, required this.currentLocation, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final current = currentLocation;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select Dominant Hand',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          _buildLocationOption(
            context,
            value: DominantHand.right,
            current: current,
            label: 'Right',
            icon: Icons.format_align_right,
          ),
          _buildLocationOption(
            context,
            value: DominantHand.left,
            current: current,
            label: 'Left',
            icon: Icons.format_align_left,
          ),
          _buildLocationOption(
            context,
            value: DominantHand.center,
            current: current,
            label: 'Ambidextrous',
            icon: Icons.format_align_center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationOption(
    BuildContext context, {
    required String value,
    required String current,
    required String label,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: current == value
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        onChanged(value);
        Navigator.pop(context);
      },
    );
  }
}
