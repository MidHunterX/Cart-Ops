import 'package:flutter/material.dart';

class SettingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? control;
  final Widget? bigControl;
  final Widget? wireframe;
  final VoidCallback? onTap;

  const SettingCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.control,
    this.bigControl,
    this.wireframe,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  control != null ? control! : const SizedBox.shrink(),
                  if (onTap != null && control == null)
                    Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                ],
              ),
              bigControl != null ? bigControl! : const SizedBox.shrink(),
              if (wireframe != null) const SizedBox(height: 12),
              if (wireframe != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(bottom: 10, top: 10),
                    color: colorScheme.surfaceContainerHighest,
                    child: wireframe,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
