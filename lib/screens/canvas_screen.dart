import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/painting_models.dart';
import '../services/app_state.dart';
import '../widgets/canvas_painter.dart';
import '../widgets/tool_bar.dart';
import '../widgets/layer_panel.dart';
import '../widgets/properties_panel.dart';
import '../widgets/timeline_panel.dart';
import '../widgets/color_picker_panel.dart';
import '../widgets/brush_settings_panel.dart';
import '../widgets/menu_bar.dart' as app_menu;

class CanvasScreen extends StatefulWidget {
  const CanvasScreen({Key? key}) : super(key: key);

  @override
  _CanvasScreenState createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _rightPanelTabController;
  final List<PressurePoint> _currentStroke = [];
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  // Panel visibility states
  bool _showLeftPanel = true;
  bool _showRightPanel = true;
  bool _showBottomPanel = false;
  bool _showColorPickerPanel = false;
  bool _showBrushSettingsPanel = false;

  @override
  void initState() {
    super.initState();
    _rightPanelTabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Center the canvas initially with proper zoom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.currentDocument != null) {
        // Calculate appropriate initial zoom to fit document on screen
        final size = MediaQuery.of(context).size;
        final docWidth = appState.currentDocument!.size.width;
        final docHeight = appState.currentDocument!.size.height;

        final scaleX = (size.width * 0.7) / docWidth;
        final scaleY = (size.height * 0.7) / docHeight;
        final scale = math.min(scaleX, scaleY);

        // Set initial transform
        final matrix = Matrix4.identity()
          ..translate(size.width / 4, size.height / 6)
          ..scale(scale);

        _transformationController.value = matrix;
        appState.setZoomLevel(scale);
      }

      // Make sure default tool is Brush
      appState.setCurrentTool(ToolType.BRUSH);

      // Set initial UI panel states
      setState(() {
        _showLeftPanel = true;
        _showRightPanel = true;
        _showBrushSettingsPanel = true;
      });
    });
  }

  @override
  void dispose() {
    _rightPanelTabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _resetTransform() {
    _animationController.reset();
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animation!.addListener(() {
      _transformationController.value = _animation!.value;
    });
    _animationController.forward();
  }

  void _zoomIn() {
    final appState = Provider.of<AppState>(context, listen: false);
    final newZoom = appState.zoomLevel * 1.2;
    appState.setZoomLevel(newZoom);

    // Apply the zoom to the transformation controller
    final Matrix4 matrix = Matrix4.identity()
      ..translate(_transformationController.value.getTranslation().x,
          _transformationController.value.getTranslation().y)
      ..scale(newZoom);
    _transformationController.value = matrix;
  }

  void _zoomOut() {
    final appState = Provider.of<AppState>(context, listen: false);
    final newZoom = appState.zoomLevel / 1.2;
    appState.setZoomLevel(newZoom);

    // Apply the zoom to the transformation controller
    final Matrix4 matrix = Matrix4.identity()
      ..translate(_transformationController.value.getTranslation().x,
          _transformationController.value.getTranslation().y)
      ..scale(newZoom);
    _transformationController.value = matrix;
  }

  // Handle pointer events for drawing
  void _onPointerDown(PointerDownEvent event) {
    final appState = Provider.of<AppState>(context, listen: false);
    if ((appState.currentTool == ToolType.BRUSH ||
            appState.currentTool == ToolType.ERASER) &&
        appState.currentLayer?.contentType == 'drawing') {
      _currentStroke.clear();
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final localPosition = renderBox.globalToLocal(event.position);

      // Adjust for zoom and pan
      final adjustedPosition = _getAdjustedPosition(localPosition);

      // Add pressure information
      _currentStroke
          .add(PressurePoint(adjustedPosition, pressure: event.pressure));
      setState(() {});
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    final appState = Provider.of<AppState>(context, listen: false);
    if ((appState.currentTool == ToolType.BRUSH ||
            appState.currentTool == ToolType.ERASER) &&
        _currentStroke.isNotEmpty &&
        appState.currentLayer?.contentType == 'drawing') {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final localPosition = renderBox.globalToLocal(event.position);

      // Adjust for zoom and pan
      final adjustedPosition = _getAdjustedPosition(localPosition);

      // Add pressure information
      _currentStroke
          .add(PressurePoint(adjustedPosition, pressure: event.pressure));
      setState(() {});
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    final appState = Provider.of<AppState>(context, listen: false);
    if ((appState.currentTool == ToolType.BRUSH ||
            appState.currentTool == ToolType.ERASER) &&
        _currentStroke.isNotEmpty &&
        appState.currentLayer?.contentType == 'drawing') {
      // Apply the stroke to the canvas
      appState.applyBrushStroke(_currentStroke);
      _currentStroke.clear();
    }
  }

  // Calculate the adjusted position based on zoom and pan
  Offset _getAdjustedPosition(Offset localPosition) {
    final appState = Provider.of<AppState>(context, listen: false);
    final canvasOffset = appState.canvasOffset;
    final zoomLevel = appState.zoomLevel;

    // Calculate the adjusted position
    return (localPosition - canvasOffset) / zoomLevel;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, appState, child) {
      return Scaffold(
        body: Column(
          children: [
            // Menu bar
            app_menu.MenuBar(
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
                onResetView: _resetTransform),

            // Main content
            Expanded(
              child: Row(
                children: [
                  // Left toolbar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _showLeftPanel ? 60 : 0,
                    curve: Curves.easeInOut,
                    child: _showLeftPanel
                        ? ToolBar(
                            currentTool: appState.currentTool,
                            onToolChanged: (tool) {
                              appState.setCurrentTool(tool);
                              if (tool == ToolType.BRUSH) {
                                setState(() {
                                  _showBrushSettingsPanel = true;
                                });
                              } else {
                                setState(() {
                                  _showBrushSettingsPanel = false;
                                });
                              }
                            },
                            onToggleColorPicker: () {
                              setState(() {
                                _showColorPickerPanel = !_showColorPickerPanel;
                              });
                            },
                          )
                        : null,
                  ),

                  // Center canvas area
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        // Canvas
                        Listener(
                          onPointerDown: _onPointerDown,
                          onPointerMove: _onPointerMove,
                          onPointerUp: _onPointerUp,
                          child: Stack(
                            children: [
                              Container(
                                color: appState.preferences.darkMode
                                    ? Colors.grey[900]
                                    : Colors.grey[300],
                                child: Center(
                                  child: InteractiveViewer(
                                    transformationController:
                                        _transformationController,
                                    minScale: 0.1,
                                    maxScale: 10.0,
                                    onInteractionEnd: (details) {
                                      // Update app state with new zoom and pan values
                                      final scale = _transformationController
                                          .value
                                          .getMaxScaleOnAxis();
                                      final translation =
                                          _transformationController.value
                                              .getTranslation();
                                      appState.setZoomLevel(scale);
                                      appState.setCanvasOffset(
                                          Offset(translation.x, translation.y));
                                    },
                                    child: Container(
                                      width:
                                          appState.currentDocument?.size.width,
                                      height:
                                          appState.currentDocument?.size.height,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRect(
                                        child: CustomPaint(
                                          painter: CanvasPainter(
                                            document: appState.currentDocument!,
                                            currentStroke: _currentStroke,
                                            brushEngine: appState.brushEngine,
                                            isAnimationMode:
                                                appState.isAnimationMode,
                                            animationService:
                                                appState.animationService,
                                            showGrid:
                                                appState.preferences.showGrid,
                                            gridSize:
                                                appState.preferences.gridSize,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Status bar at bottom of canvas
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  height: 24,
                                  color: appState.preferences.darkMode
                                      ? Colors.grey[850]
                                      : Colors.grey[200],
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Zoom: ${(appState.zoomLevel * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      SizedBox(width: 16),
                                      Text(
                                        'Dimensions: ${appState.currentDocument?.size.width.toInt()} × ${appState.currentDocument?.size.height.toInt()}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      SizedBox(width: 16),
                                      Text(
                                        'Current Layer: ${appState.canvasEngine.currentLayer.name}',
                                        style: TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Panel toggle buttons
                        Positioned(
                          top: 8,
                          left: 8,
                          child: IconButton(
                            icon: Icon(_showLeftPanel
                                ? Icons.chevron_left
                                : Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                _showLeftPanel = !_showLeftPanel;
                              });
                            },
                            tooltip:
                                _showLeftPanel ? 'Hide Tools' : 'Show Tools',
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(0.8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: Icon(_showRightPanel
                                ? Icons.chevron_right
                                : Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                _showRightPanel = !_showRightPanel;
                              });
                            },
                            tooltip:
                                _showRightPanel ? 'Hide Panels' : 'Show Panels',
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(0.8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),

                        // Animation mode toggle
                        Positioned(
                          bottom: 40,
                          right: 8,
                          child: FloatingActionButton.small(
                            onPressed: () {
                              appState.toggleAnimationMode();
                              setState(() {
                                _showBottomPanel = appState.isAnimationMode;
                              });
                            },
                            tooltip: appState.isAnimationMode
                                ? 'Exit Animation Mode'
                                : 'Enter Animation Mode',
                            child: Icon(appState.isAnimationMode
                                ? Icons.stop
                                : Icons.animation),
                          ),
                        ),
                        // Color picker panel overlay
                        if (_showColorPickerPanel)
                          Positioned(
                            right: _showRightPanel ? 300 : 20,
                            top: 20,
                            child: Container(
                              width: 300,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ColorPickerPanel(
                                currentColor: appState.brushEngine.currentColor,
                                onColorChanged: (color) {
                                  appState.setBrushColor(color);
                                },
                                onClose: () {
                                  setState(() {
                                    _showColorPickerPanel = false;
                                  });
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Right panel (Layers and Properties)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _showRightPanel ? 280 : 0,
                    curve: Curves.easeInOut,
                    child: _showRightPanel
                        ? Column(
                            children: [
                              // Tab bar for panel sections
                              TabBar(
                                controller: _rightPanelTabController,
                                tabs: [
                                  Tab(
                                      text: 'Layers',
                                      icon: Icon(Icons.layers, size: 16)),
                                  Tab(
                                      text: 'Properties',
                                      icon: Icon(Icons.tune, size: 16)),
                                ],
                                labelColor:
                                    Theme.of(context).colorScheme.primary,
                                indicatorSize: TabBarIndicatorSize.label,
                              ),

                              // Tab content
                              Expanded(
                                child: TabBarView(
                                  controller: _rightPanelTabController,
                                  children: [
                                    // Layers panel
                                    LayerPanel(
                                      layers:
                                          appState.currentDocument?.layers ??
                                              [],
                                      currentLayerIndex:
                                          appState.canvasEngine.currentLayer.id,
                                      onLayerTap: (index) {
                                        appState.canvasEngine
                                            .setCurrentLayerById(index);
                                        setState(() {});
                                      },
                                      onLayerVisibilityChanged:
                                          (index, isVisible) {
                                        appState.canvasEngine
                                            .setLayerVisibility(
                                                appState.canvasEngine.document
                                                    .layers
                                                    .indexWhere((layer) =>
                                                        layer.id == index),
                                                isVisible);
                                      },
                                      onAddLayer: () {
                                        appState.addNewLayer();
                                      },
                                      onDeleteLayer: () {
                                        appState.deleteCurrentLayer();
                                      },
                                    ),

                                    // Properties panel
                                    PropertiesPanel(
                                      currentLayer:
                                          appState.canvasEngine.currentLayer,
                                      onOpacityChanged: (value) {
                                        appState.canvasEngine.setLayerOpacity(
                                            appState
                                                .canvasEngine.document.layers
                                                .indexOf(appState
                                                    .canvasEngine.currentLayer),
                                            value);
                                      },
                                      onBlendModeChanged: (mode) {
                                        appState.canvasEngine.setLayerBlendMode(
                                            appState
                                                .canvasEngine.document.layers
                                                .indexOf(appState
                                                    .canvasEngine.currentLayer),
                                            mode);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ],
              ),
            ),

            // Bottom animation timeline panel
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showBottomPanel ? 160 : 0,
              curve: Curves.easeInOut,
              child: _showBottomPanel
                  ? TimelinePanel(
                      animationService: appState.animationService,
                      onAddFrame: () {
                        appState.addNewFrame();
                      },
                      onFrameSelected: (index) {
                        appState.animationService.currentFrameIndex = index;
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ],
        ),

        // Floating panels
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Color picker panel
            if (_showColorPickerPanel)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ColorPickerPanel(
                  currentColor: appState.colorService.currentColor,
                  onColorChanged: (color) {
                    appState.colorService.currentColor = color;
                    appState.brushEngine.currentColor = color;
                  },
                  onClose: () {
                    setState(() {
                      _showColorPickerPanel = false;
                    });
                  },
                ),
              ),

            // Brush settings panel
            if (_showBrushSettingsPanel)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: BrushSettingsPanel(
                  brushEngine: appState.brushEngine,
                  onBrushTypeChanged: (type) {
                    appState.brushEngine.currentBrushType = type;
                  },
                  onSettingsChanged: (settings) {
                    appState.brushEngine.updateSettings(settings);
                  },
                  onClose: () {
                    setState(() {
                      _showBrushSettingsPanel = false;
                    });
                  },
                ),
              ),
          ],
        ),
      );
    });
  }
}
