import 'package:flutter/material.dart';
import '../models/painting_models.dart' as painting_models;

/// Panel for layer properties
class PropertiesPanel extends StatelessWidget {
  final painting_models.Layer currentLayer;
  final Function(double) onOpacityChanged;
  final Function(painting_models.CustomBlendMode) onBlendModeChanged;

  const PropertiesPanel({
    super.key,
    required this.currentLayer,
    required this.onOpacityChanged,
    required this.onBlendModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Layer Properties',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),

            // Layer name
            Text(
              'Name: ${currentLayer.name}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 20),

            // Opacity slider
            Text(
              'Opacity: ${(currentLayer.opacity * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Slider(
              value: currentLayer.opacity,
              min: 0.0,
              max: 1.0,
              divisions: 100,
              label: '${(currentLayer.opacity * 100).toInt()}%',
              onChanged: onOpacityChanged,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),

            // Blend mode dropdown
            Text(
              'Blend Mode:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<painting_models.CustomBlendMode>(
              value: currentLayer.blendMode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: painting_models.CustomBlendMode.values.map((mode) {
                return DropdownMenuItem<painting_models.CustomBlendMode>(
                  value: mode,
                  child: Text(
                    mode.toString().split('.').last,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onBlendModeChanged(value);
                }
              },
            ),

            const SizedBox(height: 20),

            // Additional properties (expandable)
            ExpansionTile(
              title: const Text('Advanced Properties'),
              children: [
                ListTile(
                  title: const Text('Layer Mask'),
                  subtitle: Text(currentLayer.isMask ? 'Enabled' : 'None'),
                  trailing: const Icon(Icons.add_circle_outline),
                  dense: true,
                  onTap: () {
                    // Add layer mask functionality
                  },
                ),
                ListTile(
                  title: const Text('Effects'),
                  subtitle: const Text('None'),
                  trailing: const Icon(Icons.add_circle_outline),
                  dense: true,
                  onTap: () {
                    // Add layer effects functionality
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
