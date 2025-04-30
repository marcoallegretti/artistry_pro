import 'package:flutter/material.dart';
import '../services/app_state.dart';

/// Vertical toolbar with drawing tools
class ToolBar extends StatelessWidget {
  final ToolType currentTool;
  final Function(ToolType) onToolChanged;
  final VoidCallback onToggleColorPicker;

  const ToolBar({
    super.key,
    required this.currentTool,
    required this.onToolChanged,
    required this.onToggleColorPicker,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[850] : Colors.grey[100];
    final accentColor = Theme.of(context).colorScheme.primary;

    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          _buildToolButton(
            context: context,
            icon: Icons.brush,
            tooltip: 'Brush Tool',
            isSelected: currentTool == ToolType.BRUSH,
            onPressed: () => onToolChanged(ToolType.BRUSH),
            accentColor: accentColor,
          ),

          _buildToolButton(
            context: context,
            icon: Icons.colorize,
            tooltip: 'Eyedropper Tool',
            isSelected: currentTool == ToolType.EYEDROPPER,
            onPressed: () => onToolChanged(ToolType.EYEDROPPER),
            accentColor: accentColor,
          ),
          _buildToolButton(
            context: context,
            icon: Icons.select_all,
            tooltip: 'Selection Tool',
            isSelected: currentTool == ToolType.SELECTION,
            onPressed: () => onToolChanged(ToolType.SELECTION),
            accentColor: accentColor,
          ),
          _buildToolButton(
            context: context,
            icon: Icons.open_with,
            tooltip: 'Move Tool',
            isSelected: currentTool == ToolType.MOVE,
            onPressed: () => onToolChanged(ToolType.MOVE),
            accentColor: accentColor,
          ),
          _buildToolButton(
            context: context,
            icon: Icons.format_color_fill,
            tooltip: 'Fill Tool',
            isSelected: currentTool == ToolType.FILL,
            onPressed: () => onToolChanged(ToolType.FILL),
            accentColor: accentColor,
          ),
          _buildToolButton(
            context: context,
            icon: Icons.text_fields,
            tooltip: 'Text Tool',
            isSelected: currentTool == ToolType.TEXT,
            onPressed: () => onToolChanged(ToolType.TEXT),
            accentColor: accentColor,
          ),
          _buildToolButton(
            context: context,
            icon: Icons.category,
            tooltip: 'Shape Tool',
            isSelected: currentTool == ToolType.SHAPE,
            onPressed: () => onToolChanged(ToolType.SHAPE),
            accentColor: accentColor,
          ),
          _buildToolButton(
            context: context,
            icon: Icons.crop,
            tooltip: 'Crop Tool',
            isSelected: currentTool == ToolType.CROP,
            onPressed: () => onToolChanged(ToolType.CROP),
            accentColor: accentColor,
          ),
          _buildToolButton(
            context: context,
            icon: Icons.pan_tool_alt,
            tooltip: 'Hand Tool',
            isSelected: currentTool == ToolType.HAND,
            onPressed: () => onToolChanged(ToolType.HAND),
            accentColor: accentColor,
          ),
          _buildToolButton(
            context: context,
            icon: Icons.zoom_in,
            tooltip: 'Zoom Tool',
            isSelected: currentTool == ToolType.ZOOM,
            onPressed: () => onToolChanged(ToolType.ZOOM),
            accentColor: accentColor,
          ),

          const Divider(height: 16, thickness: 1),

          // Color swatch button
          IconButton(
            onPressed: onToggleColorPicker,
            icon: Icon(Icons.palette,
                color: Theme.of(context).colorScheme.onSurface),
            tooltip: 'Color Picker',
          ),

          const Spacer(),

          // Settings button at bottom
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.settings,
                color: Theme.of(context).colorScheme.onSurface),
            tooltip: 'Settings',
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onPressed,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: isSelected
          ? BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isSelected ? accentColor : Theme.of(context).iconTheme.color,
        ),
        tooltip: tooltip,
      ),
    );
  }
}
