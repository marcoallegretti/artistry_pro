import 'package:flutter/material.dart';
import '../models/painting_models.dart';

/// Panel for managing layers
class LayerPanel extends StatelessWidget {
  final List<Layer> layers;
  final String currentLayerIndex;
  final Function(String) onLayerTap;
  final Function(String, bool) onLayerVisibilityChanged;
  final VoidCallback onAddLayer;
  final VoidCallback onDeleteLayer;

  const LayerPanel({
    super.key,
    required this.layers,
    required this.currentLayerIndex,
    required this.onLayerTap,
    required this.onLayerVisibilityChanged,
    required this.onAddLayer,
    required this.onDeleteLayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Layer actions toolbar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Layers', style: Theme.of(context).textTheme.titleMedium),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: onAddLayer,
                      tooltip: 'Add Layer',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      tooltip: 'Layer Options',
                      onSelected: (value) {
                        switch (value) {
                          case 'duplicate':
                            // Duplicate layer functionality would go here
                            break;
                          case 'merge':
                            // Merge layers functionality would go here
                            break;
                          case 'group':
                            // Group layers functionality would go here
                            break;
                          case 'flatten':
                            // Flatten layers functionality would go here
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 16),
                              SizedBox(width: 8),
                              Text('Duplicate Layer'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'merge',
                          child: Row(
                            children: [
                              Icon(Icons.merge_type, size: 16),
                              SizedBox(width: 8),
                              Text('Merge Down'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'group',
                          child: Row(
                            children: [
                              Icon(Icons.folder, size: 16),
                              SizedBox(width: 8),
                              Text('Group Layers'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'flatten',
                          child: Row(
                            children: [
                              Icon(Icons.layers_clear, size: 16),
                              SizedBox(width: 8),
                              Text('Flatten All'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: layers.length > 1 ? onDeleteLayer : null,
                      tooltip: 'Delete Layer',
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Layer list
          Expanded(
            child: ListView.builder(
              itemCount: layers.length,
              itemBuilder: (context, index) {
                final layer = layers[layers.length -
                    1 -
                    index]; // Reverse order to match painting
                final isSelected = layer.id == currentLayerIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: ListTile(
                    dense: true,
                    leading: IconButton(
                      icon: Icon(
                        layer.visible ? Icons.visibility : Icons.visibility_off,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () =>
                          onLayerVisibilityChanged(layer.id, !layer.visible),
                      tooltip: layer.visible ? 'Hide Layer' : 'Show Layer',
                    ),
                    title: Text(
                      layer.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Opacity: ${(layer.opacity * 100).toInt()}% | ${layer.blendMode.toString().split('.').last}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () => onLayerTap(layer.id),
                    trailing: layer.isMask
                        ? Icon(Icons.filter_alt,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
