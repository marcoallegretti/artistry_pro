import 'package:flutter/material.dart';
import '../models/painting_models.dart';
import '../services/brush_engine.dart';

/// Panel for brush settings
class BrushSettingsPanel extends StatefulWidget {
  final BrushEngine brushEngine;
  final Function(BrushType) onBrushTypeChanged;
  final Function(BrushSettings) onSettingsChanged;
  final VoidCallback onClose;

  const BrushSettingsPanel({
    super.key,
    required this.brushEngine,
    required this.onBrushTypeChanged,
    required this.onSettingsChanged,
    required this.onClose,
  });

  @override
  _BrushSettingsPanelState createState() => _BrushSettingsPanelState();
}

class _BrushSettingsPanelState extends State<BrushSettingsPanel> {
  late BrushSettings _settings;
  late BrushType _brushType;

  @override
  void initState() {
    super.initState();
    _settings = widget.brushEngine.settings;
    _brushType = widget.brushEngine.currentBrushType;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Brush Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                    tooltip: 'Close',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ],
              ),
            ),

            // Brush type selection
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Brush Type',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _buildBrushTypeSelector(),
                  const SizedBox(height: 16),

                  // Brush size
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Size'),
                      Text('${_settings.size.toInt()}'),
                    ],
                  ),
                  Slider(
                    value: _settings.size,
                    min: 1.0,
                    max: 100.0,
                    divisions: 99,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(size: value);
                      });
                      widget.onSettingsChanged(_settings);
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),

                  // Opacity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Opacity'),
                      Text('${(_settings.opacity * 100).toInt()}%'),
                    ],
                  ),
                  Slider(
                    value: _settings.opacity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(opacity: value);
                      });
                      widget.onSettingsChanged(_settings);
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),

                  // Flow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Flow'),
                      Text('${(_settings.flow * 100).toInt()}%'),
                    ],
                  ),
                  Slider(
                    value: _settings.flow,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(flow: value);
                      });
                      widget.onSettingsChanged(_settings);
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),

                  // Hardness
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Hardness'),
                      Text('${(_settings.hardness * 100).toInt()}%'),
                    ],
                  ),
                  Slider(
                    value: _settings.hardness,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(hardness: value);
                      });
                      widget.onSettingsChanged(_settings);
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),

                  // Pressure sensitivity
                  Row(
                    children: [
                      Checkbox(
                        value: _settings.pressureSensitive,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _settings =
                                  _settings.copyWith(pressureSensitive: value);
                            });
                            widget.onSettingsChanged(_settings);
                          }
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                      const Text('Pressure Sensitivity'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrushTypeSelector() {
    final brushTypes = [
      BrushType.PENCIL,
      BrushType.BRUSH,
      BrushType.AIRBRUSH,
      BrushType.MARKER,
      BrushType.PEN,
      BrushType.WATERCOLOR,
      BrushType.TEXTURE,
      BrushType.SMUDGE,
      BrushType.ERASER,
    ];

    final brushIcons = {
      BrushType.PENCIL: Icons.edit,
      BrushType.BRUSH: Icons.brush,
      BrushType.AIRBRUSH: Icons.blur_circular,
      BrushType.MARKER: Icons.format_paint,
      BrushType.PEN: Icons.create,
      BrushType.WATERCOLOR: Icons.water_drop,
      BrushType.TEXTURE: Icons.texture,
      BrushType.SMUDGE: Icons.blur_on,
      BrushType.ERASER: Icons.auto_fix_high,
    };

    final brushDescriptions = {
      BrushType.PENCIL: 'Hard-edged sketching tool with precise control',
      BrushType.BRUSH: 'Standard painting brush with natural feel',
      BrushType.AIRBRUSH: 'Soft spray effect with pressure sensitivity',
      BrushType.MARKER: 'Solid, consistent strokes with no pressure variation',
      BrushType.PEN: 'Thin, precise lines for detailed work',
      BrushType.WATERCOLOR: 'Fluid, soft-edged strokes with blending',
      BrushType.TEXTURE: 'Apply patterns and textures to your canvas',
      BrushType.SMUDGE: 'Blend and smear existing colors',
      BrushType.ERASER: 'Remove parts of your artwork',
    };

    final brushNames = {
      BrushType.PENCIL: 'Pencil',
      BrushType.BRUSH: 'Brush',
      BrushType.AIRBRUSH: 'Airbrush',
      BrushType.MARKER: 'Marker',
      BrushType.PEN: 'Pen',
      BrushType.WATERCOLOR: 'Watercolor',
      BrushType.TEXTURE: 'Texture',
      BrushType.SMUDGE: 'Smudge',
      BrushType.ERASER: 'Eraser',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: brushTypes.map((type) {
            final isSelected = type == _brushType;
            return Tooltip(
              message: brushDescriptions[type] ?? '',
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _brushType = type;
                  });
                  widget.onBrushTypeChanged(type);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        brushIcons[type] ?? Icons.brush,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        brushNames[type] ?? 'Brush',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_brushType == BrushType.TEXTURE)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Texture Options',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Would open texture selector dialog
                      },
                      icon: const Icon(Icons.photo_library, size: 16),
                      label: const Text('Select Texture'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (_brushType == BrushType.WATERCOLOR)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Watercolor Options',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Wetness'),
                    Text('${(_settings.flow * 100).toInt()}%'),
                  ],
                ),
                Slider(
                  value: _settings.flow,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(flow: value);
                    });
                    widget.onSettingsChanged(_settings);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Diffusion'),
                    Text('${((_settings.hardness * -1 + 1) * 100).toInt()}%'),
                  ],
                ),
                Slider(
                  value: 1.0 - _settings.hardness,
                  min: 0.0,
                  max: 1.0,
                  divisions: 100,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(hardness: 1.0 - value);
                    });
                    widget.onSettingsChanged(_settings);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
