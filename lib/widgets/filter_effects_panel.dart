import 'package:flutter/material.dart';
import '../services/filter_service.dart';

/// Panel for applying filters and effects to layers
class FilterEffectsPanel extends StatefulWidget {
  final FilterType? currentFilter;
  final double intensity;
  final Function(FilterType, double) onApplyFilter;
  final VoidCallback onResetFilters;

  const FilterEffectsPanel({
    super.key,
    this.currentFilter,
    this.intensity = 1.0,
    required this.onApplyFilter,
    required this.onResetFilters,
  });

  @override
  State<FilterEffectsPanel> createState() => _FilterEffectsPanelState();
}

class _FilterEffectsPanelState extends State<FilterEffectsPanel> {
  late FilterType _selectedFilter;
  late double _intensity;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.currentFilter ?? FilterType.NONE;
    _intensity = widget.intensity;
  }

  @override
  void didUpdateWidget(FilterEffectsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentFilter != oldWidget.currentFilter) {
      _selectedFilter = widget.currentFilter ?? FilterType.NONE;
    }
    if (widget.intensity != oldWidget.intensity) {
      _intensity = widget.intensity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters & Effects',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Divider(),

          // Filter categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterCategoryButton(context, 'Adjust', Icons.tune),
                _buildFilterCategoryButton(context, 'Artistic', Icons.brush),
                _buildFilterCategoryButton(context, 'Blur', Icons.blur_on),
                _buildFilterCategoryButton(context, 'Distort', Icons.waves),
                _buildFilterCategoryButton(context, 'Stylize', Icons.style),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Filter grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: _buildFilterGrid(),
            ),
          ),

          const SizedBox(height: 16),

          // Filter intensity slider
          if (_selectedFilter != FilterType.NONE) ...[
            Text(
              'Intensity: ${(_intensity * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _intensity,
              min: 0.0,
              max: 1.0,
              divisions: 100,
              label: '${(_intensity * 100).toInt()}%',
              onChanged: (value) {
                setState(() {
                  _intensity = value;
                });
              },
            ),
          ],

          const SizedBox(height: 16),

          // Apply and Reset buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: widget.onResetFilters,
                child: const Text('Reset'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _selectedFilter != FilterType.NONE
                    ? () => widget.onApplyFilter(_selectedFilter, _intensity)
                    : null,
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCategoryButton(
      BuildContext context, String label, IconData icon) {
    // In a real implementation, this would depend on which category is active
    // For now, we'll just set it to true for the first button
    final isSelected = label == 'Adjust';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          // Switch filter category
        },
      ),
    );
  }

  List<Widget> _buildFilterGrid() {
    // This would show different filters based on the selected category
    // For now, we'll show a sample of common filters

    final filterTypes = [
      FilterType.NONE,
      FilterType.GRAYSCALE,
      FilterType.SEPIA,
      FilterType.INVERT,
      FilterType.BRIGHTNESS,
      FilterType.CONTRAST,
      FilterType.SATURATION,
      FilterType.HUE_ROTATE,
      FilterType.BLUR,
      FilterType.SHARPEN,
      FilterType.EMBOSS,
      FilterType.NOISE,
      FilterType.VIGNETTE,
      FilterType.PIXELATE,
      FilterType.THRESHOLD,
      FilterType.POSTERIZE,
      FilterType.EDGE_DETECT,
      FilterType.SKETCH,
      FilterType.VINTAGE,
      FilterType.DUOTONE,
    ];

    return filterTypes.map((filter) {
      return _buildFilterTile(filter);
    }).toList();
  }

  Widget _buildFilterTile(FilterType filter) {
    final isSelected = _selectedFilter == filter;
    final String filterName =
        filter.toString().split('.').last.replaceAll('_', ' ');

    // In a real implementation, these would be actual thumbnail previews
    // of the filter applied to the current image
    Widget previewWidget;
    switch (filter) {
      case FilterType.NONE:
        previewWidget = Container(
          color: Colors.white,
          child: const Center(child: Text('Original')),
        );
        break;
      case FilterType.GRAYSCALE:
        previewWidget = ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: Image.asset('assets/images/filter_preview.jpg',
              fit: BoxFit.cover),
        );
        break;
      case FilterType.SEPIA:
        previewWidget = ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.393,
            0.769,
            0.189,
            0,
            0,
            0.349,
            0.686,
            0.168,
            0,
            0,
            0.272,
            0.534,
            0.131,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: Image.asset('assets/images/filter_preview.jpg',
              fit: BoxFit.cover),
        );
        break;
      default:
        // For simplicity, we're using colored containers for most filters
        // In a real app, you'd render actual filter previews
        previewWidget = Container(
          color: _getFilterPreviewColor(filter),
          child: Center(
            child: Text(
              filterName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: previewWidget),
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                filterName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFilterPreviewColor(FilterType filter) {
    // Placeholder colors for filter previews
    switch (filter) {
      case FilterType.BRIGHTNESS:
        return Colors.amber.shade300;
      case FilterType.CONTRAST:
        return Colors.blueGrey.shade600;
      case FilterType.SATURATION:
        return Colors.deepPurple.shade400;
      case FilterType.HUE_ROTATE:
        return Colors.teal.shade400;
      case FilterType.BLUR:
        return Colors.blue.shade300;
      case FilterType.SHARPEN:
        return Colors.lightBlue.shade700;
      case FilterType.EMBOSS:
        return Colors.brown.shade500;
      case FilterType.NOISE:
        return Colors.grey.shade600;
      case FilterType.VIGNETTE:
        return Colors.indigo.shade400;
      case FilterType.PIXELATE:
        return Colors.lime.shade700;
      case FilterType.THRESHOLD:
        return Colors.orange.shade800;
      case FilterType.POSTERIZE:
        return Colors.deepOrange.shade400;
      case FilterType.EDGE_DETECT:
        return Colors.cyan.shade700;
      case FilterType.SKETCH:
        return Colors.blueGrey.shade400;
      case FilterType.VINTAGE:
        return Colors.brown.shade300;
      case FilterType.DUOTONE:
        return Colors.deepPurple.shade300;
      case FilterType.INVERT:
        return Colors.pink.shade300;
      default:
        return Colors.grey;
    }
  }
}
