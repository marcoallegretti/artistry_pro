import 'package:flutter/material.dart';
import '../models/painting_models.dart';

/// Panel for layer properties
class PropertiesPanel extends StatelessWidget {
  final Layer currentLayer;
  final Function(double) onOpacityChanged;
  final Function(BlendMode) onBlendModeChanged;
  
  const PropertiesPanel({
    Key? key,
    required this.currentLayer,
    required this.onOpacityChanged,
    required this.onBlendModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Layer Properties',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 20),
            
            // Layer name
            Text(
              'Name: ${currentLayer.name}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: 20),
            
            // Opacity slider
            Text(
              'Opacity: ${(currentLayer.opacity * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 8),
            Slider(
              value: currentLayer.opacity,
              min: 0.0,
              max: 1.0,
              divisions: 100,
              label: '${(currentLayer.opacity * 100).toInt()}%',
              onChanged: onOpacityChanged,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 20),
            
            // Blend mode dropdown
            Text(
              'Blend Mode:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<BlendMode>(
              value: currentLayer.blendMode,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: BlendMode.values.map((mode) {
                return DropdownMenuItem<BlendMode>(
                  value: mode,
                  child: Text(
                    mode.toString().split('.').last,
                    style: TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onBlendModeChanged(value);
                }
              },
            ),
            
            SizedBox(height: 20),
            
            // Additional properties (expandable)
            ExpansionTile(
              title: Text('Advanced Properties'),
              children: [
                ListTile(
                  title: Text('Layer Mask'),
                  subtitle: Text(currentLayer.isMask ? 'Enabled' : 'None'),
                  trailing: Icon(Icons.add_circle_outline),
                  dense: true,
                  onTap: () {
                    // Add layer mask functionality
                  },
                ),
                ListTile(
                  title: Text('Effects'),
                  subtitle: Text('None'),
                  trailing: Icon(Icons.add_circle_outline),
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