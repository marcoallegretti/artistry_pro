import 'package:flutter/material.dart';
import '../models/painting_models.dart';
import '../services/app_state.dart';
import '../services/brush_engine.dart';
import '../services/selection_service.dart';

/// Panel showing options for the currently selected tool
class ToolOptionsPanel extends StatelessWidget {
  final ToolType currentTool;
  final BrushEngine brushEngine;
  final SelectionService? selectionService;
  final Function(BrushType) onBrushTypeChanged;
  final Function(BrushSettings) onBrushSettingsChanged;
  final Function(SelectionType) onSelectionTypeChanged;
  final Function(double) onSelectionToleranceChanged;
  final Function(bool) onFeatherSelectionChanged;
  final Function(double) onFeatherRadiusChanged;

  const ToolOptionsPanel({
    Key? key,
    required this.currentTool,
    required this.brushEngine,
    this.selectionService,
    required this.onBrushTypeChanged,
    required this.onBrushSettingsChanged,
    required this.onSelectionTypeChanged,
    required this.onSelectionToleranceChanged,
    required this.onFeatherSelectionChanged,
    required this.onFeatherRadiusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tool Options',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Divider(),

          // Show different options based on the current tool
          _buildToolOptions(context),
        ],
      ),
    );
  }

  Widget _buildToolOptions(BuildContext context) {
    switch (currentTool) {
      case ToolType.BRUSH:
        return _buildBrushOptions(context);
      case ToolType.ERASER:
        return _buildEraserOptions(context);
      case ToolType.SELECTION:
        return _buildSelectionOptions(context);
      case ToolType.EYEDROPPER:
        return _buildEyedropperOptions(context);
      case ToolType.FILL:
        return _buildFillOptions(context);
      case ToolType.TEXT:
        return _buildTextOptions(context);
      case ToolType.SHAPE:
        return _buildShapeOptions(context);
      case ToolType.CROP:
        return _buildCropOptions(context);
      default:
        return const Center(
          child: Text('No options available for this tool'),
        );
    }
  }

  Widget _buildBrushOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brush Type Selector
        Text('Brush Type', style: Theme.of(context).textTheme.titleSmall),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: BrushType.values
                .where((type) => type != BrushType.ERASER) // Exclude eraser
                .map((brushType) => _buildBrushTypeButton(context, brushType))
                .toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Brush Size
        Text('Size: ${brushEngine.settings.size.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.bodyMedium),
        Slider(
          value: brushEngine.settings.size,
          min: 1.0,
          max: 100.0,
          divisions: 99,
          label: brushEngine.settings.size.toStringAsFixed(1),
          onChanged: (value) {
            onBrushSettingsChanged(
              brushEngine.settings.copyWith(size: value),
            );
          },
        ),

        // Brush Opacity
        Text('Opacity: ${(brushEngine.settings.opacity * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodyMedium),
        Slider(
          value: brushEngine.settings.opacity,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          label: '${(brushEngine.settings.opacity * 100).toInt()}%',
          onChanged: (value) {
            onBrushSettingsChanged(
              brushEngine.settings.copyWith(opacity: value),
            );
          },
        ),

        // Brush Flow
        Text('Flow: ${(brushEngine.settings.flow * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodyMedium),
        Slider(
          value: brushEngine.settings.flow,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          label: '${(brushEngine.settings.flow * 100).toInt()}%',
          onChanged: (value) {
            onBrushSettingsChanged(
              brushEngine.settings.copyWith(flow: value),
            );
          },
        ),

        // Brush Hardness
        Text('Hardness: ${(brushEngine.settings.hardness * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodyMedium),
        Slider(
          value: brushEngine.settings.hardness,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          label: '${(brushEngine.settings.hardness * 100).toInt()}%',
          onChanged: (value) {
            onBrushSettingsChanged(
              brushEngine.settings.copyWith(hardness: value),
            );
          },
        ),

        // Pressure Sensitivity
        Row(
          children: [
            Checkbox(
              value: brushEngine.settings.pressureSensitive,
              onChanged: (value) {
                onBrushSettingsChanged(
                  brushEngine.settings
                      .copyWith(pressureSensitive: value ?? true),
                );
              },
            ),
            Text('Pressure Sensitivity',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildEraserOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Eraser Size
        Text('Size: ${brushEngine.settings.size.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.bodyMedium),
        Slider(
          value: brushEngine.settings.size,
          min: 1.0,
          max: 100.0,
          divisions: 99,
          label: brushEngine.settings.size.toStringAsFixed(1),
          onChanged: (value) {
            onBrushSettingsChanged(
              brushEngine.settings.copyWith(size: value),
            );
          },
        ),

        // Eraser Hardness
        Text('Hardness: ${(brushEngine.settings.hardness * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodyMedium),
        Slider(
          value: brushEngine.settings.hardness,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          label: '${(brushEngine.settings.hardness * 100).toInt()}%',
          onChanged: (value) {
            onBrushSettingsChanged(
              brushEngine.settings.copyWith(hardness: value),
            );
          },
        ),

        // Pressure Sensitivity
        Row(
          children: [
            Checkbox(
              value: brushEngine.settings.pressureSensitive,
              onChanged: (value) {
                onBrushSettingsChanged(
                  brushEngine.settings
                      .copyWith(pressureSensitive: value ?? true),
                );
              },
            ),
            Text('Pressure Sensitivity',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionOptions(BuildContext context) {
    if (selectionService == null) {
      return const Center(child: Text('Selection service not available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selection Type
        Text('Selection Type', style: Theme.of(context).textTheme.titleSmall),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: SelectionType.values
                .map((type) => _buildSelectionTypeButton(context, type))
                .toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Magic Wand / Color Range Tolerance (only show for relevant selection types)
        if (selectionService!.selectionType == SelectionType.MAGIC_WAND ||
            selectionService!.selectionType == SelectionType.COLOR_RANGE)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Tolerance: ${selectionService!.tolerance.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodyMedium),
              Slider(
                value: selectionService!.tolerance,
                min: 0.0,
                max: 100.0,
                divisions: 100,
                label: selectionService!.tolerance.toStringAsFixed(1),
                onChanged: onSelectionToleranceChanged,
              ),
            ],
          ),

        // Feather Selection
        Row(
          children: [
            Checkbox(
              value: selectionService!.feather,
              onChanged: (value) {
                onFeatherSelectionChanged(value ?? false);
              },
            ),
            Text('Feather Selection',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),

        // Feather Radius (only show if feathering is enabled)
        if (selectionService!.feather)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Feather Radius: ${selectionService!.featherRadius.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodyMedium),
              Slider(
                value: selectionService!.featherRadius,
                min: 0.5,
                max: 50.0,
                divisions: 99,
                label: selectionService!.featherRadius.toStringAsFixed(1),
                onChanged: onFeatherRadiusChanged,
              ),
            ],
          ),

        const SizedBox(height: 16),

        // Selection Operation Buttons
        Wrap(
          spacing: 8.0,
          children: [
            OutlinedButton(
              onPressed: selectionService!.hasSelection
                  ? () => selectionService!.clearSelection()
                  : null,
              child: const Text('Clear'),
            ),
            OutlinedButton(
              onPressed: selectionService!.hasSelection
                  ? () =>
                      selectionService!.invertSelection(const Size(1920, 1080))
                  : null,
              child: const Text('Invert'),
            ),
            OutlinedButton(
              onPressed: selectionService!.hasSelection
                  ? () => selectionService!.expandSelection(5.0)
                  : null,
              child: const Text('Expand'),
            ),
            OutlinedButton(
              onPressed: selectionService!.hasSelection
                  ? () => selectionService!.contractSelection(5.0)
                  : null,
              child: const Text('Contract'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEyedropperOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sample Size', style: Theme.of(context).textTheme.titleSmall),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('Point')),
            ButtonSegment(value: 3, label: Text('3×3')),
            ButtonSegment(value: 5, label: Text('5×5')),
          ],
          selected: {1},
          onSelectionChanged: (Set<int> newSelection) {
            // Here you would handle the sample size change
          },
        ),
        const SizedBox(height: 16),
        Text('Sample From', style: Theme.of(context).textTheme.titleSmall),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'current', label: Text('Current Layer')),
            ButtonSegment(value: 'all', label: Text('All Layers')),
          ],
          selected: {'current'},
          onSelectionChanged: (Set<String> newSelection) {
            // Here you would handle the sample source change
          },
        ),
      ],
    );
  }

  Widget _buildFillOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tolerance: 32', style: Theme.of(context).textTheme.bodyMedium),
        Slider(
          value: 32,
          min: 0,
          max: 255,
          divisions: 255,
          label: '32',
          onChanged: (value) {
            // Here you would handle tolerance changes
          },
        ),
        const SizedBox(height: 16),
        Text('Fill Mode', style: Theme.of(context).textTheme.titleSmall),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'color', label: Text('Color')),
            ButtonSegment(value: 'pattern', label: Text('Pattern')),
          ],
          selected: {'color'},
          onSelectionChanged: (Set<String> newSelection) {
            // Here you would handle fill mode changes
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: true,
              onChanged: (value) {
                // Here you would handle contiguous fill setting
              },
            ),
            Text('Contiguous', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildTextOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Font', style: Theme.of(context).textTheme.titleSmall),
        DropdownButton<String>(
          value: 'Arial',
          items:
              ['Arial', 'Times New Roman', 'Courier New', 'Georgia', 'Verdana']
                  .map((font) => DropdownMenuItem(
                        value: font,
                        child: Text(font),
                      ))
                  .toList(),
          onChanged: (value) {
            // Here you would handle font changes
          },
        ),
        const SizedBox(height: 16),
        Text('Size: 24', style: Theme.of(context).textTheme.bodyMedium),
        Slider(
          value: 24,
          min: 8,
          max: 72,
          divisions: 64,
          label: '24',
          onChanged: (value) {
            // Here you would handle font size changes
          },
        ),
        const SizedBox(height: 16),
        Text('Style', style: Theme.of(context).textTheme.titleSmall),
        Wrap(
          spacing: 8.0,
          children: [
            ChoiceChip(
              label: const Text('B'),
              selected: true,
              onSelected: (selected) {
                // Here you would handle bold style
              },
            ),
            ChoiceChip(
              label: const Text('I'),
              selected: false,
              onSelected: (selected) {
                // Here you would handle italic style
              },
            ),
            ChoiceChip(
              label: const Text('U'),
              selected: false,
              onSelected: (selected) {
                // Here you would handle underline style
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Alignment', style: Theme.of(context).textTheme.titleSmall),
        SegmentedButton<TextAlign>(
          segments: const [
            ButtonSegment(
              value: TextAlign.left,
              icon: Icon(Icons.format_align_left),
            ),
            ButtonSegment(
              value: TextAlign.center,
              icon: Icon(Icons.format_align_center),
            ),
            ButtonSegment(
              value: TextAlign.right,
              icon: Icon(Icons.format_align_right),
            ),
            ButtonSegment(
              value: TextAlign.justify,
              icon: Icon(Icons.format_align_justify),
            ),
          ],
          selected: {TextAlign.left},
          onSelectionChanged: (Set<TextAlign> newSelection) {
            // Here you would handle alignment changes
          },
        ),
      ],
    );
  }

  Widget _buildShapeOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shape Type', style: Theme.of(context).textTheme.titleSmall),
        Wrap(
          spacing: 8.0,
          children: [
            ChoiceChip(
              label: const Text('Rectangle'),
              selected: true,
              onSelected: (selected) {
                // Here you would handle shape type selection
              },
            ),
            ChoiceChip(
              label: const Text('Ellipse'),
              selected: false,
              onSelected: (selected) {
                // Here you would handle shape type selection
              },
            ),
            ChoiceChip(
              label: const Text('Polygon'),
              selected: false,
              onSelected: (selected) {
                // Here you would handle shape type selection
              },
            ),
            ChoiceChip(
              label: const Text('Star'),
              selected: false,
              onSelected: (selected) {
                // Here you would handle shape type selection
              },
            ),
            ChoiceChip(
              label: const Text('Line'),
              selected: false,
              onSelected: (selected) {
                // Here you would handle shape type selection
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Fill & Stroke', style: Theme.of(context).textTheme.titleSmall),
        Row(
          children: [
            Checkbox(
              value: true,
              onChanged: (value) {
                // Here you would handle fill setting
              },
            ),
            Text('Fill', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 16),
            Checkbox(
              value: true,
              onChanged: (value) {
                // Here you would handle stroke setting
              },
            ),
            Text('Stroke', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 16),
        Text('Stroke Width: 2.0',
            style: Theme.of(context).textTheme.bodyMedium),
        Slider(
          value: 2.0,
          min: 0.5,
          max: 20.0,
          divisions: 39,
          label: '2.0',
          onChanged: (value) {
            // Here you would handle stroke width changes
          },
        ),
      ],
    );
  }

  Widget _buildCropOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aspect Ratio', style: Theme.of(context).textTheme.titleSmall),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'free', label: Text('Free')),
            ButtonSegment(value: '1:1', label: Text('1:1')),
            ButtonSegment(value: '4:3', label: Text('4:3')),
            ButtonSegment(value: '16:9', label: Text('16:9')),
          ],
          selected: {'free'},
          onSelectionChanged: (Set<String> newSelection) {
            // Here you would handle aspect ratio changes
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: false,
              onChanged: (value) {
                // Here you would handle the setting for showing rule of thirds
              },
            ),
            Text('Show Rule of Thirds',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildBrushTypeButton(BuildContext context, BrushType brushType) {
    final isSelected = brushEngine.currentBrushType == brushType;

    IconData icon;
    String tooltip;

    switch (brushType) {
      case BrushType.PENCIL:
        icon = Icons.edit;
        tooltip = 'Pencil';
        break;
      case BrushType.BRUSH:
        icon = Icons.brush;
        tooltip = 'Brush';
        break;
      case BrushType.AIRBRUSH:
        icon = Icons.blur_on;
        tooltip = 'Airbrush';
        break;
      case BrushType.MARKER:
        icon = Icons.edit_attributes;
        tooltip = 'Marker';
        break;
      case BrushType.PEN:
        icon = Icons.create;
        tooltip = 'Pen';
        break;
      case BrushType.ERASER:
        icon = Icons.auto_fix_high;
        tooltip = 'Eraser';
        break;
      case BrushType.SMUDGE:
        icon = Icons.blur_circular;
        tooltip = 'Smudge';
        break;
      case BrushType.WATERCOLOR:
        icon = Icons.water_drop;
        tooltip = 'Watercolor';
        break;
      case BrushType.TEXTURE:
        icon = Icons.texture;
        tooltip = 'Texture';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onBrushTypeChanged(brushType),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionTypeButton(
      BuildContext context, SelectionType selectionType) {
    final isSelected = selectionService?.selectionType == selectionType;

    IconData icon;
    String tooltip;

    switch (selectionType) {
      case SelectionType.RECTANGULAR:
        icon = Icons.crop_square;
        tooltip = 'Rectangular Selection';
        break;
      case SelectionType.ELLIPTICAL:
        icon = Icons.panorama_fish_eye;
        tooltip = 'Elliptical Selection';
        break;
      case SelectionType.LASSO:
        icon = Icons.gesture;
        tooltip = 'Lasso Selection';
        break;
      case SelectionType.MAGIC_WAND:
        icon = Icons.auto_fix_high;
        tooltip = 'Magic Wand';
        break;
      case SelectionType.COLOR_RANGE:
        icon = Icons.colorize;
        tooltip = 'Color Range';
        break;
      case SelectionType.POLYGON:
        icon = Icons.star_border;
        tooltip = 'Polygon Selection';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isSelected == true
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onSelectionTypeChanged(selectionType),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              icon,
              color: isSelected == true
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
