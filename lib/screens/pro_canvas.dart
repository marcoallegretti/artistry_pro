import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image/image.dart' as img;

import '../models/layer.dart';
import '../models/canvas_settings.dart';
import '../services/layer_manager.dart';
import '../widgets/background_panel.dart';
import '../widgets/canvas_size_dialog.dart';

class ProCanvasScreen extends StatefulWidget {
  const ProCanvasScreen({Key? key}) : super(key: key);

  @override
  _ProCanvasScreenState createState() => _ProCanvasScreenState();
}

class _ProCanvasScreenState extends State<ProCanvasScreen> {
  // Layer management
  late final LayerManager _layerManager;

  // Tool settings
  Color _selectedColor = Colors.black;
  double _strokeWidth = 5.0;
  StrokeCap _strokeCap = StrokeCap.round;
  BlendMode _blendMode = BlendMode.srcOver;

  // Eraser settings
  double _eraserTolerance =
      10.0; // Tolerance for smart eraser (distance threshold)
      
  // Image manipulation settings
  bool _isImageSelected = false;
  int? _selectedImageLayerIndex;
  Offset? _imageInitialPosition;
  Offset? _dragStartPosition;
  
  // Canvas background tap detection
  bool _canDeselectOnTap = true;

  // Brush types
  BrushType _brushType = BrushType.pen;
  
  // Tool modes
  ToolMode _toolMode = ToolMode.draw;

  // Canvas settings
  late CanvasSettings _canvasSettings;
  double _zoomLevel = 1.0;
  Offset _canvasOffset = Offset.zero;
  bool _isPanning = false;
  Color _backgroundColor = Colors.white;

  // Undo/Redo handled by LayerManager

  // UI state
  bool _showColorPicker = false;
  bool _showLayersPanel = false;
  bool _showBrushSettings = false;

  // Add image picker instance
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _layerManager = LayerManager(baseLayerName: 'Background');
    _canvasSettings = CanvasSettings.defaultSettings;
    
    // Show canvas size dialog after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCanvasSizeDialog();
    });
  }
  
  // Show background settings dialog
  Future<void> _showBackgroundSettingsDialog() async {
    Color selectedColor = _canvasSettings.backgroundColor;
    bool isTransparent = _canvasSettings.isTransparent;
    double checkerPatternOpacity = _canvasSettings.checkerPatternOpacity;
    double checkerSquareSize = _canvasSettings.checkerSquareSize;
    
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Background Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transparent background toggle
                  SwitchListTile(
                    title: const Text('Transparent Background'),
                    value: isTransparent,
                    onChanged: (value) {
                      setState(() {
                        isTransparent = value;
                      });
                    },
                  ),
                  
                  const Divider(),
                  
                  // Background color picker (only visible when not transparent)
                  if (!isTransparent) ...[                    
                    const Text('Background Color:'),
                    const SizedBox(height: 8),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final Color? color = await showColorPicker(
                          context: context,
                          initialColor: selectedColor,
                        );
                        if (color != null) {
                          setState(() {
                            selectedColor = color;
                          });
                        }
                      },
                      child: const Text('Choose Color'),
                    ),
                  ],
                  
                  // Checker pattern settings (only visible when transparent)
                  if (isTransparent) ...[                    
                    const Text('Checker Pattern Opacity:'),
                    Slider(
                      value: checkerPatternOpacity,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      label: checkerPatternOpacity.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          checkerPatternOpacity = value;
                        });
                      },
                    ),
                    
                    const Text('Checker Square Size:'),
                    Slider(
                      value: checkerSquareSize,
                      min: 5.0,
                      max: 30.0,
                      divisions: 25,
                      label: '${checkerSquareSize.toInt()} px',
                      onChanged: (value) {
                        setState(() {
                          checkerSquareSize = value;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Apply the new settings
                  this.setState(() {
                    _canvasSettings = _canvasSettings.copyWith(
                      backgroundColor: selectedColor,
                      isTransparent: isTransparent,
                      checkerPatternOpacity: checkerPatternOpacity,
                      checkerSquareSize: checkerSquareSize,
                    );
                    _backgroundColor = selectedColor;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Helper method to show color picker
  Future<Color?> showColorPicker({
    required BuildContext context,
    required Color initialColor,
  }) async {
    Color selectedColor = initialColor;
    
    return showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                selectedColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: true,
              displayThumbColor: true,
              showLabel: true,
              paletteType: PaletteType.hsv,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Select'),
              onPressed: () {
                Navigator.of(context).pop(selectedColor);
              },
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _showCanvasSizeDialog() async {
    final Size? newSize = await showDialog<Size>(
      context: context,
      barrierDismissible: false, // User must choose a size
      builder: (context) => CanvasSizeDialog(
        initialSize: _canvasSettings.size,
      ),
    );
    
    if (newSize != null) {
      setState(() {
        _canvasSettings = _canvasSettings.copyWith(size: newSize);
        _backgroundColor = _canvasSettings.backgroundColor;
        // Reset zoom and position to fit the new canvas
        _resetZoom();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final toolbarWidth = mediaQuery.size.width > 600 ? 80.0 : 70.0; // Responsive width
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0), // Increased height for better touch targets
        child: AppBar(
          title: const Text('Artistry Pro'),
          actions: [
            IconButton(
              icon: const Icon(Icons.aspect_ratio),
              tooltip: 'Canvas Size',
              onPressed: _showCanvasSizeDialog,
            ),
            IconButton(
              icon: const Icon(Icons.format_color_fill),
              tooltip: 'Background Settings',
              onPressed: _showBackgroundSettingsDialog,
            ),
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: () => _layerManager.undo(),
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Redo',
              onPressed: () => _layerManager.redo(),
            ),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Image',
              onPressed: _saveImage,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Clear Canvas',
              onPressed: _clearCanvas,
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Canvas area with zoom and pan
              Positioned(
                left: toolbarWidth,
                top: 0.0,
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  onScaleEnd: _handleScaleEnd,
                  child: Container(
                    color: Color.fromRGBO(
                      _backgroundColor.red,
                      _backgroundColor.green,
                      _backgroundColor.blue,
                      _backgroundColor.alpha / 255.0,
                    ),
                    width: double.infinity,
                    height: double.infinity,
                    child: ClipRect(
                      child: CustomPaint(
                        painter: MultiLayerPainter(
                          _layerManager.layers,
                          _zoomLevel,
                          _canvasOffset,
                          canvasSize: _canvasSettings.size,
                          backgroundColor: _backgroundColor,
                          isTransparent: _canvasSettings.isTransparent,
                          checkerPatternOpacity: _canvasSettings.checkerPatternOpacity,
                          checkerSquareSize: _canvasSettings.checkerSquareSize,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),

              // Toolbar on the left
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: toolbarWidth,
                child: Container(
                  color: Color.fromRGBO(
                    Theme.of(context).colorScheme.surface.red,
                    Theme.of(context).colorScheme.surface.green,
                    Theme.of(context).colorScheme.surface.blue,
                    0.9,
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Drawing tools section
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Drawing tools
                                _buildToolButton(
                                  icon: Icons.brush,
                                  isSelected: _brushType == BrushType.pen,
                                  onPressed: () => _setBrushType(BrushType.pen),
                                  tooltip: 'Pen',
                                ),
                                _buildToolButton(
                                  icon: Icons.create,
                                  isSelected: _brushType == BrushType.pencil,
                                  onPressed: () => _setBrushType(BrushType.pencil),
                                  tooltip: 'Pencil',
                                ),
                                _buildToolButton(
                                  icon: Icons.blur_on,
                                  isSelected: _brushType == BrushType.airbrush,
                                  onPressed: () => _setBrushType(BrushType.airbrush),
                                  tooltip: 'Airbrush',
                                ),
                                _buildToolButton(
                                  icon: Icons.format_paint,
                                  isSelected: _brushType == BrushType.marker,
                                  onPressed: () => _setBrushType(BrushType.marker),
                                  tooltip: 'Marker',
                                ),
                                _buildToolButton(
                                  icon: Icons.cleaning_services,
                                  isSelected: _brushType == BrushType.smartEraser,
                                  onPressed: () => _setBrushType(BrushType.smartEraser),
                                  tooltip: 'Eraser',
                                ),
                                const Divider(height: 8),
                                
                                // Panel toggles
                                _buildToolButton(
                                  icon: Icons.color_lens,
                                  isSelected: _showColorPicker,
                                  onPressed: _toggleColorPicker,
                                  tooltip: 'Color Picker',
                                ),
                                _buildToolButton(
                                  icon: Icons.tune,
                                  isSelected: _showBrushSettings,
                                  onPressed: _toggleBrushSettings,
                                  tooltip: 'Brush Settings',
                                ),
                                _buildToolButton(
                                  icon: Icons.layers,
                                  isSelected: _showLayersPanel,
                                  onPressed: _toggleLayersPanel,
                                  tooltip: 'Layers',
                                ),
                                const Divider(height: 8),
                                
                                // Image tools
                                _buildToolButton(
                                  icon: Icons.image,
                                  isSelected: false,
                                  onPressed: _importImage,
                                  tooltip: 'Import Image',
                                ),
                                _buildToolButton(
                                  icon: Icons.touch_app,
                                  isSelected: _toolMode == ToolMode.selectImage,
                                  onPressed: () => _setToolMode(ToolMode.selectImage),
                                  tooltip: 'Select/Deselect Image',
                                ),
                                _buildToolButton(
                                  icon: Icons.open_with,
                                  isSelected: _toolMode == ToolMode.moveImage,
                                  onPressed: () => _setToolMode(ToolMode.moveImage),
                                  tooltip: 'Move Image',
                                ),
                                _buildToolButton(
                                  icon: Icons.cancel,
                                  isSelected: false,
                                  onPressed: _isImageSelected ? () => _deselectCurrentImage() : () {},
                                  tooltip: 'Deselect Image',
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Zoom controls at the bottom
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Divider(height: 8),
                            _buildToolButton(
                              icon: Icons.zoom_in,
                              isSelected: false,
                              onPressed: _zoomIn,
                              tooltip: 'Zoom In',
                            ),
                            _buildToolButton(
                              icon: Icons.zoom_out,
                              isSelected: false,
                              onPressed: _zoomOut,
                              tooltip: 'Zoom Out',
                            ),
                            _buildToolButton(
                              icon: Icons.fit_screen,
                              isSelected: false,
                              onPressed: _resetZoom,
                              tooltip: 'Reset Zoom',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Color picker panel
              if (_showColorPicker)
                Positioned(
                  left: toolbarWidth,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 250,
                    color: Color.fromRGBO(
                      Theme.of(context).colorScheme.surface.red,
                      Theme.of(context).colorScheme.surface.green,
                      Theme.of(context).colorScheme.surface.blue,
                      0.9,
                    ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Color',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildColorPalette(),
                    const SizedBox(height: 24),
                    Text(
                      'Recent Colors',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    _buildRecentColors(),
                    const Spacer(),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(
                          _selectedColor.red,
                          _selectedColor.green,
                          _selectedColor.blue,
                          _selectedColor.alpha / 255.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

              // Brush settings panel
              if (_showBrushSettings)
                Positioned(
                  left: toolbarWidth,
                  top: 56.0,
                  bottom: 0,
                  child: Container(
                    width: 250,
                    color: Color.fromRGBO(
                      Theme.of(context).colorScheme.surface.red,
                      Theme.of(context).colorScheme.surface.green,
                      Theme.of(context).colorScheme.surface.blue,
                      0.8,
                    ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Brush Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    ExpansionTile(
                      title: Text(_brushType == BrushType.smartEraser
                          ? 'Eraser Size'
                          : 'Brush Size'),
                      children: [
                        Slider(
                          value: _strokeWidth,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label: _strokeWidth.round().toString(),
                          onChanged: (value) {
                            setState(() {
                              _strokeWidth = value;
                            });
                          },
                        ),
                        if (_brushType == BrushType.smartEraser) ...[
                          const SizedBox(height: 16),
                          Text(
                              'Eraser Tolerance: ${_eraserTolerance.toStringAsFixed(1)}'),
                          Slider(
                            value: _eraserTolerance,
                            min: 1,
                            max: 20,
                            divisions: 19,
                            label: _eraserTolerance.toStringAsFixed(1),
                            onChanged: (value) {
                              setState(() {
                                _eraserTolerance = value;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                        'Opacity: ${(_brushOpacity * 100).toStringAsFixed(0)}%'),
                    Slider(
                      value: _brushOpacity,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      label: (_brushOpacity * 100).round().toString() + '%',
                      onChanged: (value) {
                        setState(() {
                          _brushOpacity = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Brush Shape'),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStrokeCapButton(StrokeCap.round, 'Round'),
                        _buildStrokeCapButton(StrokeCap.square, 'Square'),
                        _buildStrokeCapButton(StrokeCap.butt, 'Flat'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Blend Mode'),
                    const SizedBox(height: 8),
                    DropdownButton<BlendMode>(
                      value: _blendMode,
                      isExpanded: true,
                      onChanged: (BlendMode? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _blendMode = newValue;
                          });
                        }
                      },
                      items: [
                        BlendMode.srcOver,
                        BlendMode.multiply,
                        BlendMode.screen,
                        BlendMode.overlay,
                        BlendMode.darken,
                        BlendMode.lighten,
                      ].map<DropdownMenuItem<BlendMode>>((BlendMode value) {
                        return DropdownMenuItem<BlendMode>(
                          value: value,
                          child: Text(value.toString().split('.').last),
                        );
                      }).toList(),
                    ),
                    const Spacer(),
                    // Brush preview
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: BrushPreviewPainter(
                            color: _selectedColor,
                            strokeWidth: _strokeWidth,
                            strokeCap: _strokeCap,
                            opacity: _brushOpacity,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Layers panel
          if (_showLayersPanel)
            Positioned(
              left: toolbarWidth,
              top: 56.0,
              bottom: 0,
              child: Container(
                width: 250,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(
                    Theme.of(context).colorScheme.surface.red,
                    Theme.of(context).colorScheme.surface.green,
                    Theme.of(context).colorScheme.surface.blue,
                    0.8,
                  ),
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Layers',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: 'Add Layer',
                          onPressed: _addLayer,
                        ),
                      ],
                    ),
                    const Divider(),
                    BackgroundPanel(
                      backgroundColor: _backgroundColor,
                      onBackgroundColorChanged: (color) =>
                          setState(() => _backgroundColor = color),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _layerManager.layers.length,
                        itemBuilder: (context, index) {
                          final reversedIndex =
                              _layerManager.layers.length - 1 - index;
                          return _buildLayerTile(reversedIndex);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ],
          );
        },
      ),
    );
  }

  // Brush opacity - separate from color opacity for more control
  double _brushOpacity = 1.0;

  Widget _buildToolButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      preferBelow: false, // Show tooltip above to avoid overflow
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: double.infinity, // Full width to adapt to parent container
            height: 50, // Fixed height for consistent spacing
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 4,
                ),
              ),
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                  : Colors.transparent,
            ),
            child: Center(
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                size: 24, // Slightly smaller icons
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPalette() {
    // A grid of common colors
    final colors = [
      Colors.black,
      Colors.white,
      Colors.grey,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
    ];

    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        return InkWell(
          onTap: () => setState(() => _selectedColor = color),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: _selectedColor == color
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                width: _selectedColor == color ? 3 : 1,
              ),
              boxShadow: _selectedColor == color
                  ? [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentColors() {
    // For simplicity, just showing a few colors
    // In a real app, you'd track recently used colors
    final recentColors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.blue,
      Colors.green,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: recentColors.map((color) {
        return InkWell(
          onTap: () => setState(() => _selectedColor = color),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey,
                width: 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStrokeCapButton(StrokeCap cap, String label) {
    return InkWell(
      onTap: () => setState(() => _strokeCap = cap),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _strokeCap == cap
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _strokeCap == cap
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _strokeCap == cap
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: _strokeCap == cap ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLayerTile(int index) {
    final layer = _layerManager.layers[index];
    final isSelected = index == _layerManager.currentLayerIndex;

    return ListTile(
      title: Text(layer.name),
      selected: isSelected,
      tileColor:
          isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      leading: Icon(
        Icons.layers,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(layer.visible ? Icons.visibility : Icons.visibility_off),
            onPressed: () =>
                setState(() => _layerManager.toggleVisibility(index)),
          ),
          if (_layerManager.layers.length > 1)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => setState(() => _layerManager.deleteLayer(index)),
            ),
        ],
      ),
      onTap: () => setState(() => _layerManager.selectLayer(index)),
    );
  }

  void _setBrushType(BrushType type) {
    setState(() {
      _brushType = type;
      _toolMode = ToolMode.draw; // Switch to drawing mode when selecting a brush

      // Adjust settings based on brush type
      switch (type) {
        case BrushType.pen:
          _strokeWidth = 3.0;
          _brushOpacity = 1.0;
          _strokeCap = StrokeCap.round;
          _blendMode = BlendMode.srcOver;
          break;
        case BrushType.pencil:
          _strokeWidth = 1.0;
          _brushOpacity = 0.8;
          _strokeCap = StrokeCap.round;
          _blendMode = BlendMode.srcOver;
          break;
        case BrushType.airbrush:
          _strokeWidth = 15.0;
          _brushOpacity = 0.3;
          _strokeCap = StrokeCap.round;
          _blendMode = BlendMode.srcOver;
          break;
        case BrushType.marker:
          _strokeWidth = 10.0;
          _brushOpacity = 0.7;
          _strokeCap = StrokeCap.square;
          _blendMode = BlendMode.srcOver;
          break;
        case BrushType.smartEraser:
          _strokeWidth = 20.0;
          _brushOpacity = 1.0;
          _strokeCap = StrokeCap.round;
          _blendMode = BlendMode.srcOver;
          break;
      }
    });
  }
  
  // Set the current tool mode
  void _setToolMode(ToolMode mode) {
    setState(() {
      // If we're already in this mode and it's an image mode, deselect the current image
      if (_toolMode == mode && (mode == ToolMode.selectImage || mode == ToolMode.moveImage) && _isImageSelected) {
        _deselectCurrentImage();
        return;
      }
      
      _toolMode = mode;
      
      // If switching away from image selection/movement, deselect any selected image
      if (mode == ToolMode.draw && _isImageSelected && _selectedImageLayerIndex != null) {
        _updateImageSelection(_selectedImageLayerIndex!, false);
        _isImageSelected = false;
        _selectedImageLayerIndex = null;
      }
      
      // Show appropriate message based on the selected mode
      switch (mode) {
        case ToolMode.draw:
          _showSnackBarMessage('Drawing mode activated');
          break;
        case ToolMode.selectImage:
          _showSnackBarMessage('Image selection mode activated. Tap on an image to select it, or tap again to deselect.');
          break;
        case ToolMode.moveImage:
          if (_isImageSelected) {
            _showSnackBarMessage('Image move mode activated. Drag the selected image to move it. Tap elsewhere to deselect.');
          } else {
            _showSnackBarMessage('First select an image to move it.');
            _toolMode = ToolMode.selectImage; // Revert to selection mode if no image is selected
          }
          break;
      }
    });
  }

  void _toggleColorPicker() {
    setState(() {
      _showColorPicker = !_showColorPicker;
      _showBrushSettings = false;
      _showLayersPanel = false;
    });
  }

  void _toggleBrushSettings() {
    setState(() {
      _showBrushSettings = !_showBrushSettings;
      _showColorPicker = false;
      _showLayersPanel = false;
    });
  }

  void _toggleLayersPanel() {
    setState(() {
      _showLayersPanel = !_showLayersPanel;
      _showColorPicker = false;
      _showBrushSettings = false;
    });
  }

  void _addLayer() {
    setState(() {
      _layerManager.addLayer();
    });
  }

  void _clearCanvas() {
    setState(() {
      // Create a new layer manager with a single empty layer
      _layerManager = LayerManager(baseLayerName: 'Background');
    });
  }

  void _saveImage() {
    // This would save the image in a real app
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image saved (simulated)')),
    );
  }
  
  // Helper method to show snackbar messages
  void _showSnackBarMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  // Handle image selection and interaction
  void _handleImageInteraction(Offset position) {
    // Check all layers for images and see if the position is within any image
    bool foundImage = false;
    
    for (int i = 0; i < _layerManager.layers.length; i++) {
      final layer = _layerManager.layers[i];
      
      if (layer.contentType == ContentType.image && layer.visible && !layer.locked) {
        if (layer.payload is Map) {
          final Map imageData = layer.payload as Map;
          final ui.Image? img = imageData['image'] as ui.Image?;
          final Offset imgPosition = imageData['position'] as Offset;
          final double scale = imageData['scale'] as double;
          
          if (img != null) {
            // Calculate image bounds
            final Rect imageBounds = Rect.fromLTWH(
              imgPosition.dx,
              imgPosition.dy,
              img.width.toDouble() * scale,
              img.height.toDouble() * scale
            );
            
            // Check if position is within image bounds
            if (imageBounds.contains(position)) {
              // Check if we're clicking on the same image that's already selected
              if (_isImageSelected && _selectedImageLayerIndex == i) {
                // Toggle selection off if clicking the same image again
                setState(() {
                  _deselectCurrentImage();
                  _showSnackBarMessage('Image deselected');
                });
              } else {
                setState(() {
                  // Deselect any previously selected image
                  if (_isImageSelected && _selectedImageLayerIndex != null) {
                    _updateImageSelection(_selectedImageLayerIndex!, false);
                  }
                  
                  // Select this image
                  _isImageSelected = true;
                  _selectedImageLayerIndex = i;
                  _updateImageSelection(i, true);
                  _toolMode = ToolMode.moveImage; // Switch to move mode automatically
                  
                  _showSnackBarMessage('Image selected. You can now move it.');
                });
              }
              
              foundImage = true;
              break;
            }
          }
        }
      }
    }
    
    // If no image was found at the position, deselect any selected image
    if (!foundImage && _isImageSelected && _canDeselectOnTap) {
      _deselectCurrentImage();
    }
  }
  
  // Helper method to deselect the current image
  void _deselectCurrentImage() {
    setState(() {
      if (_selectedImageLayerIndex != null) {
        _updateImageSelection(_selectedImageLayerIndex!, false);
      }
      _isImageSelected = false;
      _selectedImageLayerIndex = null;
      
      // Return to drawing mode instead of staying in selection mode
      _toolMode = ToolMode.draw;
      _showSnackBarMessage('Returned to drawing mode');
    });
  }
  
  // Update the selection state of an image
  void _updateImageSelection(int layerIndex, bool isSelected) {
    final layer = _layerManager.layers[layerIndex];
    
    if (layer.contentType == ContentType.image && layer.payload is Map) {
      final Map imageData = Map.from(layer.payload as Map);
      imageData['isSelected'] = isSelected;
      _layerManager.setPayload(layerIndex, imageData);
    }
  }
  
  // Get the current position of an image in a layer
  Offset _getImagePosition(int layerIndex) {
    final layer = _layerManager.layers[layerIndex];
    
    if (layer.contentType == ContentType.image && layer.payload is Map) {
      final Map imageData = layer.payload as Map;
      return imageData['position'] as Offset;
    }
    
    return Offset.zero; // Fallback
  }
  
  // Update the position of an image in a layer
  void _updateImagePosition(int layerIndex, Offset newPosition) {
    final layer = _layerManager.layers[layerIndex];
    
    if (layer.contentType == ContentType.image && layer.payload is Map) {
      final Map imageData = Map.from(layer.payload as Map);
      imageData['position'] = newPosition;
      _layerManager.setPayload(layerIndex, imageData);
    }
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = math.min(_zoomLevel + 0.25, 5.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = math.max(_zoomLevel - 0.25, 0.5);
    });
  }

  void _resetZoom() {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width - 60; // Account for toolbar
    final double screenHeight = screenSize.height - 48; // Account for AppBar
    
    // Calculate zoom to fit canvas on screen with some padding
    final double widthRatio = (screenWidth - 40) / _canvasSettings.size.width;
    final double heightRatio = (screenHeight - 40) / _canvasSettings.size.height;
    final double fitZoom = math.min(widthRatio, heightRatio);
    
    setState(() {
      _zoomLevel = math.min(1.0, fitZoom); // Don't zoom in more than 100%
      
      // Center the canvas
      final double centeredX = (screenWidth - (_canvasSettings.size.width * _zoomLevel)) / 2 + 60;
      final double centeredY = (screenHeight - (_canvasSettings.size.height * _zoomLevel)) / 2;
      _canvasOffset = Offset(centeredX, centeredY);
    });
  }

  Offset? _lastFocalPoint;

  void _handleScaleStart(ScaleStartDetails details) {
    final localPosition = details.localFocalPoint;
    final adjustedPosition = (localPosition - _canvasOffset) / _zoomLevel;
    _lastFocalPoint = details.focalPoint;  // Ensure focal point is set for continuous updates
    
    // Check if the point is within canvas boundaries
    final canvasBounds = Rect.fromLTWH(0, 0, _canvasSettings.size.width, _canvasSettings.size.height);
    final isWithinCanvas = canvasBounds.contains(adjustedPosition);
    
    debugPrint('ScaleStart: local=$localPosition, adjusted=$adjustedPosition, zoom=$_zoomLevel, brushType=$_brushType, withinCanvas=$isWithinCanvas');
    
    // Check if we're in image selection mode and trying to interact with an image
    if (_toolMode == ToolMode.selectImage) {
      _handleImageInteraction(adjustedPosition);
      return;
    }
    
    // If we're in image move mode and have a selected image
    if (_toolMode == ToolMode.moveImage && _isImageSelected && _selectedImageLayerIndex != null) {
      _dragStartPosition = adjustedPosition;
      _imageInitialPosition = _getImagePosition(_selectedImageLayerIndex!);
      _canDeselectOnTap = false; // Prevent deselection during drag operation
      return;
    }
    
    // If we tap on the canvas (not on an image) in any mode, deselect any selected image
    if (isWithinCanvas && _isImageSelected && _canDeselectOnTap) {
      _deselectCurrentImage();
    }
    
    if (!isWithinCanvas && _brushType != BrushType.smartEraser) {
      // Don't draw outside canvas boundaries (except for eraser which can erase outside)
      return;
    }
    
    setState(() {
      // Use non-final variable so we can reassign it if needed
      var currentLayer = _layerManager.currentLayer;
      
      // Handle drawing based on layer content type
      if (currentLayer.contentType == ContentType.image) {
        // If the layer contains an image, convert it to a drawing layer first
        // Create a new drawing layer with the same properties
        _layerManager.addLayer(name: '${currentLayer.name} Drawing');
        _layerManager.setPayload(_layerManager.currentLayerIndex, <DrawingPoint?>[]);
        currentLayer = _layerManager.currentLayer; // Get the new current layer
      }
      
      if (currentLayer.payload == null) {
        _layerManager.setPayload(_layerManager.currentLayerIndex, <DrawingPoint?>[]);
      }
      
      // Now we can safely cast to List<DrawingPoint?>
      final points = currentLayer.payload as List<DrawingPoint?>;
      
      if (_brushType == BrushType.smartEraser) {
        debugPrint('Eraser mode: removing points within tolerance $_strokeWidth');
        points.removeWhere((p) => p != null && !p.isEraser && (p.point - adjustedPosition).distance <= _strokeWidth);
      } else {
        debugPrint('Drawing mode: adding point at $adjustedPosition');
        points.add(
          DrawingPoint(
            adjustedPosition,
            Paint()
              ..color = Color.fromRGBO(
                _selectedColor.red,
                _selectedColor.green,
                _selectedColor.blue,
                _selectedColor.alpha / 255.0,
              )
              ..strokeWidth = _strokeWidth
              ..strokeCap = _strokeCap
              ..blendMode = _blendMode,
            isEraser: false,
          ),
        );
      }
      _layerManager.setPayload(_layerManager.currentLayerIndex, points);
    });
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    debugPrint('ScaleUpdate called: scale=${details.scale}, isPanning=$_isPanning, lastFocalPoint=$_lastFocalPoint');
    
    // Handle image movement if in move mode and an image is selected
    if (_toolMode == ToolMode.moveImage && _isImageSelected && _selectedImageLayerIndex != null && _dragStartPosition != null && _imageInitialPosition != null) {
      final localPosition = details.localFocalPoint;
      final adjustedPosition = (localPosition - _canvasOffset) / _zoomLevel;
      final delta = adjustedPosition - _dragStartPosition!;
      
      setState(() {
        _updateImagePosition(_selectedImageLayerIndex!, _imageInitialPosition! + delta);
      });
      return;
    }
    
    if (_isPanning && _lastFocalPoint != null) {
      // Handle panning logic remains unchanged
      final deltaScreen = details.focalPoint - _lastFocalPoint!;
      debugPrint('Pan deltaScreen=$deltaScreen');
      final deltaCanvas = deltaScreen;
      setState(() {
        _canvasOffset += deltaCanvas;
        debugPrint('Pan deltaCanvas=$deltaCanvas newOffset=$_canvasOffset');
        _lastFocalPoint = details.focalPoint;
      });
    } else if (details.scale != 1.0) {
      // Handle zooming logic remains unchanged
      final focal = details.localFocalPoint;
      final canvasFocalBefore = (focal - _canvasOffset) / _zoomLevel;
      final newZoom = (_zoomLevel * details.scale).clamp(0.5, 5.0);
      final newOffset = focal - canvasFocalBefore * newZoom;
      debugPrint('Zoom: focal=$focal oldZoom=$_zoomLevel newZoom=$newZoom oldOffset=$_canvasOffset newOffset=$newOffset');
      setState(() {
        _zoomLevel = newZoom;
        _canvasOffset = newOffset;
        _lastFocalPoint = details.focalPoint;
      });
    } else if (!_isPanning && _lastFocalPoint != null) {
      final localPosition = details.localFocalPoint;
      final adjustedPosition = (localPosition - _canvasOffset) / _zoomLevel;
      
      // Check if the point is within canvas boundaries
      final canvasBounds = Rect.fromLTWH(0, 0, _canvasSettings.size.width, _canvasSettings.size.height);
      final isWithinCanvas = canvasBounds.contains(adjustedPosition);
      
      debugPrint('Drawing update: adding point at $adjustedPosition, withinCanvas=$isWithinCanvas');
      
      if (!isWithinCanvas && _brushType != BrushType.smartEraser) {
        // Don't draw outside canvas boundaries (except for eraser which can erase outside)
        return;
      }
      
      setState(() {
        final currentLayer = _layerManager.currentLayer;
        
        // Skip update if this is an image layer and we haven't converted it yet
        if (currentLayer.contentType == ContentType.image) {
          // This shouldn't happen if _handleScaleStart is working correctly,
          // but we'll handle it just in case
          return;
        }
        
        // Now we can safely cast to List<DrawingPoint?>
        final points = currentLayer.payload as List<DrawingPoint?>;
        
        if (_brushType == BrushType.smartEraser) {
          debugPrint('Eraser mode update: removing points within tolerance $_strokeWidth');
          points.removeWhere((p) => p != null && !p.isEraser && (p.point - adjustedPosition).distance <= _strokeWidth);
        } else {
          debugPrint('Drawing mode update: adding point at $adjustedPosition');
          points.add(
            DrawingPoint(
              adjustedPosition,
              Paint()
                ..color = Color.fromRGBO(
                  _selectedColor.red,
                  _selectedColor.green,
                  _selectedColor.blue,
                  _selectedColor.alpha / 255.0,
                )
                ..strokeWidth = _strokeWidth
                ..strokeCap = _strokeCap
                ..blendMode = _blendMode,
              isEraser: false,
            ),
          );
        }
        _layerManager.setPayload(_layerManager.currentLayerIndex, points);
        _lastFocalPoint = details.focalPoint;
      });
    } else {
      debugPrint('ScaleUpdate skipped: conditions not met');
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    setState(() {
      // Reset image drag tracking variables
      if (_toolMode == ToolMode.moveImage) {
        _dragStartPosition = null;
        _imageInitialPosition = null;
        _canDeselectOnTap = true; // Re-enable deselection after drag operation
      }
      
      _isPanning = false;
      _lastFocalPoint = null;

      // Add null to mark the end of a stroke if we were drawing
      if (!_isPanning && _toolMode == ToolMode.draw) {
        // Get current layer
        final currentLayer = _layerManager.currentLayer;

        // Get the points from the current layer's payload
        if (currentLayer.payload != null) {
          final points = currentLayer.payload as List<DrawingPoint?>;

          // Add null to mark the end of a stroke
          points.add(null);

          // Update the layer's payload
          _layerManager.setPayload(_layerManager.currentLayerIndex, points);
        }
      }
    });
  }

  // Method to import image and add to current layer
  Future<void> _importImage() async {
    final XFile? imageFile = await _picker.pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final img.Image originalImage = img.decodeImage(bytes)!; // Get original image to pass dimensions
      // Show dialog for size options with defaults
      final sizeOptions = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => SizeSelectionDialog(
          originalWidth: originalImage.width.toDouble(),
          originalHeight: originalImage.height.toDouble(),
        ),
      );

      if (sizeOptions != null) {
        img.Image resizedImage;
        double width = sizeOptions['width'];
        double height = sizeOptions['height'];
        String unit = sizeOptions['unit'];

        if (unit == 'percentage') {
          final scaleFactor = width / 100; // Use width percentage, maintain aspect ratio if needed, but user specifies both
          resizedImage = img.copyResize(originalImage, width: (originalImage.width * scaleFactor).round(), height: (originalImage.height * scaleFactor).round());
        } else { // pixels
          resizedImage = img.copyResize(originalImage, width: width.round(), height: height.round());
        }

        final resizedBytes = img.encodePng(resizedImage);
        final codec = await ui.instantiateImageCodec(Uint8List.fromList(resizedBytes));
        final frameInfo = await codec.getNextFrame();
        final ui.Image resizedUiImage = frameInfo.image;
        
        // Calculate the position to center the image on the canvas
        final imageWidth = resizedUiImage.width.toDouble();
        final imageHeight = resizedUiImage.height.toDouble();
        
        // Scale the image to fit within the canvas if needed
        double scaleFactor = 1.0;
        if (imageWidth > _canvasSettings.size.width || imageHeight > _canvasSettings.size.height) {
          final widthRatio = _canvasSettings.size.width / imageWidth;
          final heightRatio = _canvasSettings.size.height / imageHeight;
          scaleFactor = math.min(widthRatio, heightRatio) * 0.9; // 90% of the max size to leave some margin
        }
        
        // Update current layer, ensuring it's an image layer
        _layerManager.setContentType(_layerManager.currentLayerIndex, ContentType.image);
        _layerManager.setPayload(_layerManager.currentLayerIndex, {
          'image': resizedUiImage,
          'position': Offset(
            (_canvasSettings.size.width - imageWidth * scaleFactor) / 2,
            (_canvasSettings.size.height - imageHeight * scaleFactor) / 2
          ),
          'scale': scaleFactor,
          'isDraggable': true, // Add this flag to indicate the image can be dragged
          'isSelected': false // Track selection state
        });
        
        // Automatically switch to image selection mode after inserting an image
        setState(() {
          _toolMode = ToolMode.selectImage;
          _showSnackBarMessage('Image inserted. You can now select and move it.');
        });
      }
    }
  }
}

// Brush types
enum BrushType {
  pen,
  pencil,
  airbrush,
  marker,
  smartEraser, // New pro-grade eraser that preserves background
}

// Tool modes
enum ToolMode {
  draw,
  selectImage,
  moveImage,
}

// Drawing point class
class DrawingPoint {
  final Offset point;
  final Paint paint;
  final bool isEraser;

  DrawingPoint(this.point, this.paint, {this.isEraser = false});
}

// Painter for multiple layers
class MultiLayerPainter extends CustomPainter {
  final List<Layer> layers;
  final double zoomLevel;
  final Offset offset;
  final Size canvasSize;
  final Color backgroundColor;
  final bool isTransparent;
  final double checkerPatternOpacity;
  final double checkerSquareSize;

  MultiLayerPainter(
    this.layers, 
    this.zoomLevel, 
    this.offset, {
    this.canvasSize = const Size(1080, 1080),
    this.backgroundColor = Colors.white,
    this.isTransparent = false,
    this.checkerPatternOpacity = 0.2,
    this.checkerSquareSize = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Apply transforms to canvas directly - this is the key change
    // We're applying transforms to the canvas itself rather than
    // to the drawn elements

    // First translate
    canvas.translate(offset.dx, offset.dy);

    // Then scale
    canvas.scale(zoomLevel);
    
    final canvasRect = Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height);
    
    if (isTransparent) {
      // Draw checkered background for transparency within canvas bounds
      final checkerPaint1 = Paint()..color = Colors.white;
      final checkerPaint2 = Paint()..color = Colors.grey.withOpacity(checkerPatternOpacity);
      
      final squareSize = checkerSquareSize;
      final cols = (canvasSize.width / squareSize).ceil();
      final rows = (canvasSize.height / squareSize).ceil();
      
      // First fill the entire canvas with white background
      canvas.drawRect(canvasRect, checkerPaint1);
      
      // Then draw the checker pattern with grey squares
      for (int x = 0; x < cols; x++) {
        for (int y = 0; y < rows; y++) {
          if ((x + y) % 2 == 0) {
            canvas.drawRect(
              Rect.fromLTWH(x * squareSize, y * squareSize, squareSize, squareSize),
              checkerPaint2,
            );
          }
        }
      }
    } else {
      // Draw solid background
      final bgPaint = Paint()..color = backgroundColor;
      canvas.drawRect(canvasRect, bgPaint);
    }
    
    // Draw canvas border
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 / zoomLevel;
    canvas.drawRect(canvasRect, borderPaint);

    // Now draw the layers
    for (final layer in layers) {
      if (!layer.visible) continue; // Skip invisible layers

      // Save canvas state before applying layer-specific settings
      canvas.save();

      // Apply layer opacity if not 1.0
      final layerOpacity = layer.opacity;
      final layerBlendMode = layer.blendMode;

      if (layerOpacity < 1.0) {
        // For partial opacity, we need to use saveLayer
        final layerPaint = Paint()
          ..color = Color.fromRGBO(
            255,
            255,
            255,
            layerOpacity,
          )
          ..blendMode = layerBlendMode;

        canvas.saveLayer(null, layerPaint);
      } else if (layerBlendMode != ui.BlendMode.srcOver) {
        // For just blend mode changes
        canvas.saveLayer(null, Paint()..blendMode = layerBlendMode);
      }

      // Paint the layer content
      if (layer.contentType == ContentType.drawing) {
        if (layer.payload is List<DrawingPoint?>) {
          _paintLayer(canvas, layer.payload as List<DrawingPoint?>);
        }
      } else if (layer.contentType == ContentType.image) {
        if (layer.payload is Map) {
          final Map imageData = layer.payload as Map;
          final ui.Image? img = imageData['image'] as ui.Image?;
          final Offset position = imageData['position'] as Offset;
          final double scale = imageData['scale'] as double;
          
          if (img != null) {
            final bool isSelected = imageData['isSelected'] as bool? ?? false;
            
            // Draw the image at the specified position and scale
            canvas.drawImageRect(
              img,
              Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
              Rect.fromLTWH(
                position.dx, 
                position.dy, 
                img.width.toDouble() * scale, 
                img.height.toDouble() * scale
              ),
              Paint(),
            );
            
            // Draw selection border if the image is selected
            if (isSelected) {
              final selectionPaint = Paint()
                ..color = Colors.blue
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.0 / zoomLevel;
              
              // Draw selection rectangle
              canvas.drawRect(
                Rect.fromLTWH(
                  position.dx - 2 / zoomLevel, 
                  position.dy - 2 / zoomLevel, 
                  img.width.toDouble() * scale + 4 / zoomLevel, 
                  img.height.toDouble() * scale + 4 / zoomLevel
                ),
                selectionPaint,
              );
              
              // Draw handle points at corners for better UX
              final handlePaint = Paint()
                ..color = Colors.white
                ..style = PaintingStyle.fill;
              
              final handleStrokePaint = Paint()
                ..color = Colors.blue
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.0 / zoomLevel;
              
              final handleSize = 8.0 / zoomLevel;
              
              // Draw handles at corners
              final handlePositions = [
                Offset(position.dx, position.dy), // Top-left
                Offset(position.dx + img.width.toDouble() * scale, position.dy), // Top-right
                Offset(position.dx, position.dy + img.height.toDouble() * scale), // Bottom-left
                Offset(position.dx + img.width.toDouble() * scale, position.dy + img.height.toDouble() * scale), // Bottom-right
              ];
              
              for (final handlePos in handlePositions) {
                canvas.drawCircle(handlePos, handleSize, handlePaint);
                canvas.drawCircle(handlePos, handleSize, handleStrokePaint);
              }
            }
          }
        } else if (layer.payload is ui.Image) {
          // Handle legacy format for backward compatibility
          final ui.Image img = layer.payload as ui.Image;
          // Center the image on the canvas
          final double imageWidth = img.width.toDouble();
          final double imageHeight = img.height.toDouble();
          final double x = (canvasSize.width - imageWidth) / 2;
          final double y = (canvasSize.height - imageHeight) / 2;
          
          canvas.drawImageRect(
            img,
            Rect.fromLTWH(0, 0, imageWidth, imageHeight),
            Rect.fromLTWH(x, y, imageWidth, imageHeight),
            Paint(),
          );
        }
      }

      // Restore canvas state
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant MultiLayerPainter oldDelegate) => true;

  void _paintLayer(Canvas canvas, List<DrawingPoint?> points) {
    debugPrint('Painting layer with ${points.length} points');
    final List<List<DrawingPoint>> strokeSegments = [];
    List<DrawingPoint> current = [];
    for (final dp in points) {
      if (dp == null) {
        if (current.isNotEmpty) {
          strokeSegments.add(List.of(current));
          current.clear();
        }
        continue;
      }
      current.add(dp);
    }
    if (current.isNotEmpty) strokeSegments.add(current);
    debugPrint('Found ${strokeSegments.length} stroke segments');
    for (final segment in strokeSegments) {
      if (segment.isEmpty) continue;
      debugPrint('Segment has ${segment.length} points, first point paint: color=${segment[0].paint.color}, opacity=${segment[0].paint.color.opacity}');
      if (segment.length < 2) continue;
      for (int i = 0; i < segment.length - 1; i++) {
        canvas.drawLine(segment[i].point, segment[i + 1].point, segment[i].paint);
      }
    }
  }
}

// Painter for brush preview
class BrushPreviewPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final StrokeCap strokeCap;
  final double opacity;

  BrushPreviewPainter({
    required this.color,
    required this.strokeWidth,
    required this.strokeCap,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw a sample stroke
    final paint = Paint()
      ..color = Color.fromRGBO(
        color.red,
        color.green,
        color.blue,
        opacity,
      )
      ..strokeWidth = strokeWidth
      ..strokeCap = strokeCap
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(center.dx - 30, center.dy),
      Offset(center.dx + 30, center.dy),
      paint,
    );

    // Draw a dot at the end to show the cap style
    canvas.drawPoints(
      ui.PointMode.points,
      [Offset(center.dx + 30, center.dy)],
      paint,
    );
  }

  @override
  bool shouldRepaint(BrushPreviewPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      strokeCap != oldDelegate.strokeCap ||
      opacity != oldDelegate.opacity;
}

class SizeSelectionDialog extends StatefulWidget {
  final double originalWidth;
  final double originalHeight;

  const SizeSelectionDialog({required this.originalWidth, required this.originalHeight});

  @override
  _SizeSelectionDialogState createState() => _SizeSelectionDialogState();
}

class _SizeSelectionDialogState extends State<SizeSelectionDialog> {
  final _formKey = GlobalKey<FormState>();
  late double _width;
  late double _height;
  String _unit = 'pixels'; // Default to pixels

  @override
  void initState() {
    super.initState();
    _width = widget.originalWidth;
    _height = widget.originalHeight;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Image Size Options'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Width'),
              initialValue: _width.toString(),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter width';
                }
                if (double.tryParse(value) == null) {
                  return 'Must be a number';
                }
                return null;
              },
              onSaved: (value) => _width = double.parse(value!),
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Height'),
              initialValue: _height.toString(),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter height';
                }
                if (double.tryParse(value) == null) {
                  return 'Must be a number';
                }
                return null;
              },
              onSaved: (value) => _height = double.parse(value!),
            ),
            DropdownButton<String>(
              value: _unit,
              items: ['pixels', 'percentage'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _unit = newValue!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              Navigator.pop(context, {'width': _width, 'height': _height, 'unit': _unit});
            }
          },
          child: Text('Apply'),
        ),
      ],
    );
  }
}
