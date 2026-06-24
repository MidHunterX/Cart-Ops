import 'package:flutter/material.dart';

class ThemeModeSelector extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const ThemeModeSelector({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode)),
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(Icons.settings_brightness),
        ),
        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
      ],
      selected: {currentThemeMode},
      onSelectionChanged: (set) => onThemeModeChanged(set.first),
    );
  }
}
