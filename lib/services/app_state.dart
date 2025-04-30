import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/painting_models.dart';
import 'canvas_engine.dart';
import 'brush_engine.dart';
import 'animation_service.dart';
import 'color_service.dart';
import 'file_service.dart';

/// Enum for the different tools available in the app
enum ToolType {
  BRUSH,
  ERASER,
  EYEDROPPER,
  SELECTION,
  MOVE,
  FILL,
  TEXT,
  SHAPE,
  CROP,
  HAND,
  ZOOM,
}

/// Manages the state of the entire app
class AppState extends ChangeNotifier {
  static const Uuid _uuid = Uuid(); // Fixed declaration
  final FileService _fileService = FileService();

  // Core services
  late CanvasEngine _canvasEngine;
  late BrushEngine _brushEngine;
  late AnimationService _animationService;
  late ColorService _colorService;

  // App state variables
  UserPreferences _preferences = UserPreferences();
  CanvasDocument? _currentDocument;
  ToolType _currentTool = ToolType.BRUSH;
  bool _isAnimationMode = false;
  double _zoomLevel = 1.0;
  Offset _canvasOffset = Offset.zero;
  bool _isUiCollapsed = false;
  List<String> _recentFiles = [];
  final int _currentLayerIndex = 0; // Non-nullable, default to 0

  /// Initialize the app state
  AppState() {
    _loadPreferences();
    _initializeNewDocument();
  }

  /// Create a new document
  void _initializeNewDocument() {
    final newEngine = CanvasEngine.newDocument(
      name: 'Untitled',
      size: const Size(1920, 1080),
      resolution: 300.0,
      colorMode: ColorMode.RGB,
    );

    _canvasEngine = newEngine;
    _currentDocument = newEngine.document;
    _brushEngine = BrushEngine();
    _animationService = AnimationService.withInitialFrame(_currentDocument!);
    _colorService = ColorService();

    notifyListeners();
  }

  /// Load preferences from local storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsString = prefs.getString('userPreferences');

      if (prefsString != null) {
        _preferences = UserPreferences.fromMap(
          Map<String, dynamic>.from({
            'darkMode': prefs.getBool('darkMode') ?? false,
            'showGrid': prefs.getBool('showGrid') ?? false,
            'snapToGrid': prefs.getBool('snapToGrid') ?? false,
            'gridSize': prefs.getDouble('gridSize') ?? 10.0,
            'lastOpenedFile': prefs.getString('lastOpenedFile'),
            'recentFiles': prefs.getStringList('recentFiles') ?? [],
            'shortcuts': {}, // Shortcuts would need more complex logic
            'uiLayout': prefs.getString('uiLayout') ?? 'default',
          }),
        );

        _recentFiles = prefs.getStringList('recentFiles') ?? [];
      }

      notifyListeners();
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  /// Save preferences to local storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsMap = _preferences.toMap();

      await prefs.setBool('darkMode', prefsMap['darkMode']);
      await prefs.setBool('showGrid', prefsMap['showGrid']);
      await prefs.setBool('snapToGrid', prefsMap['snapToGrid']);
      await prefs.setDouble('gridSize', prefsMap['gridSize']);
      await prefs.setString('lastOpenedFile', prefsMap['lastOpenedFile'] ?? '');
      await prefs.setStringList('recentFiles', _recentFiles);
      await prefs.setString('uiLayout', prefsMap['uiLayout']);
    } catch (e) {
      print('Error saving preferences: $e');
    }
  }

  /// Create a new document
  void createNewDocument({
    required String name,
    required Size size,
    double resolution = 300.0,
    ColorMode colorMode = ColorMode.RGB,
  }) {
    final newEngine = CanvasEngine.newDocument(
      name: name,
      size: size,
      resolution: resolution,
      colorMode: colorMode,
    );

    _canvasEngine = newEngine;
    _currentDocument = newEngine.document;
    _animationService = AnimationService.withInitialFrame(_currentDocument!);

    // Make sure brush engine is initialized with default settings
    _brushEngine = BrushEngine();
    _brushEngine.currentBrushType =
        BrushType.BRUSH; // Ensure brush tool is selected

    // Reset tool selection
    _currentTool = ToolType.BRUSH;

    // Reset view settings
    _zoomLevel = 1.0;
    _canvasOffset = Offset.zero;

    notifyListeners();
  }

  /// Save the current document
  Future<String?> saveCurrentDocument() async {
    if (_currentDocument == null) {
      return null;
    }

    final filePath = await _fileService.saveProject(_currentDocument!);
    if (filePath != null) {
      _currentDocument = _currentDocument!.copyWith(filePath: filePath);
      _addToRecentFiles(filePath);
    }

    notifyListeners();
    return filePath;
  }

  /// Export the current document to a specific format
  Future<String?> exportCurrentDocument(String format,
      {int jpegQuality = 90, String? fileName}) async {
    if (_currentDocument == null) {
      return null;
    }

    final name = fileName ?? _currentDocument!.name;

    String? filePath;
    switch (format.toLowerCase()) {
      case 'png':
        filePath =
            await _fileService.saveAsPng(_currentDocument!, fileName: name);
        break;
      case 'jpg':
      case 'jpeg':
        filePath = await _fileService.saveAsJpeg(_currentDocument!,
            quality: jpegQuality, fileName: name);
        break;
      case 'webp':
        filePath =
            await _fileService.saveAsWebp(_currentDocument!, fileName: name);
        break;
      case 'psd':
        filePath =
            await _fileService.saveAsPsd(_currentDocument!, fileName: name);
        break;
      case 'gif':
      case 'mp4':
      case 'video':
        if (_isAnimationMode) {
          final frames =
              await _animationService.renderAllFrames(_currentDocument!.size);
          filePath = await _fileService.exportAnimationAsVideo(
            frames,
            _animationService.settings,
            name,
            format: format.toLowerCase(),
          );
        }
        break;
    }

    return filePath;
  }

  /// Load a document from a file
  Future<bool> loadDocument(String filePath) async {
    final loadedDocument = await _fileService.loadProject(filePath);
    if (loadedDocument != null) {
      _currentDocument = loadedDocument;

      // Recreate services with loaded document
      _canvasEngine = CanvasEngine.newDocument(
        name: loadedDocument.name,
        size: loadedDocument.size,
        resolution: loadedDocument.resolution,
        colorMode: loadedDocument.colorMode,
      );

      // Update layers
      for (int i = 0; i < loadedDocument.layers.length; i++) {
        if (i == 0) {
          // Replace the first layer
          _canvasEngine.document = _canvasEngine.document.copyWith(
            layers: [loadedDocument.layers[0]],
          );
        } else {
          // Add additional layers
          _canvasEngine.addNewLayer(
            name: loadedDocument.layers[i].name,
            blendMode: loadedDocument.layers[i].blendMode,
            opacity: loadedDocument.layers[i].opacity,
            isMask: loadedDocument.layers[i].isMask,
            parentLayerId: loadedDocument.layers[i].parentLayerId,
          );

          // Set the layer image
          final layer = _canvasEngine.document.layers[i];
          _canvasEngine.document.layers[i] = layer.copyWith(
            image: loadedDocument.layers[i].image,
            visible: loadedDocument.layers[i].visible,
          );
        }
      }

      _animationService = AnimationService.withInitialFrame(_currentDocument!);
      _addToRecentFiles(filePath);

      notifyListeners();
      return true;
    }

    return false;
  }

  /// Add a file to recent files list
  void _addToRecentFiles(String filePath) {
    // Remove if already exists
    _recentFiles.remove(filePath);

    // Add to the beginning of the list
    _recentFiles.insert(0, filePath);

    // Limit to 10 recent files
    if (_recentFiles.length > 10) {
      _recentFiles.removeLast();
    }

    // Update preferences
    _preferences = _preferences.copyWith(
      lastOpenedFile: filePath,
      recentFiles: _recentFiles,
    );

    _savePreferences();
  }

  /// Apply a brush stroke to the canvas
  Future<void> applyBrushStroke(List<PressurePoint> points) async {
    if (_currentTool == ToolType.BRUSH || _currentTool == ToolType.ERASER) {
      // Set brush type based on tool
      if (_currentTool == ToolType.ERASER) {
        _brushEngine.currentBrushType = BrushType.ERASER;
      }

      // Create a stroke with current brush settings
      final interpolatedPoints = _brushEngine.interpolatePoints(points);
      final stroke = _brushEngine.createStroke(interpolatedPoints);

      // Apply to current layer
      await _canvasEngine.applyBrushStroke(stroke);

      notifyListeners();
    }
  }

  /// Add a new layer to the canvas
  void addNewLayer({
    String? name,
    BlendMode blendMode = BlendMode.NORMAL,
    double opacity = 1.0,
  }) {
    _canvasEngine.addNewLayer(
      name: name,
      blendMode: blendMode,
      opacity: opacity,
    );

    notifyListeners();
  }

  /// Delete the current layer
  void deleteCurrentLayer() {
    _canvasEngine.deleteCurrentLayer();
    notifyListeners();
  }

  /// Toggle animation mode
  void toggleAnimationMode() {
    _isAnimationMode = !_isAnimationMode;
    notifyListeners();
  }

  /// Add a new animation frame
  void addNewFrame() {
    if (!_isAnimationMode) return;

    _animationService.addNewFrame();
    notifyListeners();
  }

  /// Toggle dark mode
  void toggleDarkMode() {
    _preferences = _preferences.copyWith(darkMode: !_preferences.darkMode);
    _savePreferences();
    notifyListeners();
  }

  /// Set current tool
  void setCurrentTool(ToolType tool) {
    _currentTool = tool;
    notifyListeners();
  }

  /// Set brush color
  void setBrushColor(Color color) {
    _brushEngine.currentColor = color;
    _colorService.currentColor = color;
    notifyListeners();
  }

  /// Update brush type if needed
  void _updateBrushType(ToolType tool) {
    if (tool == ToolType.ERASER) {
      _brushEngine.currentBrushType = BrushType.ERASER;
    } else if (tool == ToolType.BRUSH) {
      _brushEngine.currentBrushType = BrushType.BRUSH;
    }
    notifyListeners();
  }

  /// Update zoom level
  void setZoomLevel(double zoom) {
    _zoomLevel = zoom.clamp(0.1, 10.0);
    notifyListeners();
  }

  /// Update canvas offset (for panning)
  void setCanvasOffset(Offset offset) {
    _canvasOffset = offset;
    notifyListeners();
  }

  /// Toggle UI collapsed state
  void toggleUiCollapsed() {
    _isUiCollapsed = !_isUiCollapsed;
    notifyListeners();
  }

  // Getters for app state
  CanvasDocument? get currentDocument => _currentDocument;
  CanvasEngine get canvasEngine => _canvasEngine;
  BrushEngine get brushEngine => _brushEngine;
  AnimationService get animationService => _animationService;
  ColorService get colorService => _colorService;
  UserPreferences get preferences => _preferences;
  ToolType get currentTool => _currentTool;
  bool get isAnimationMode => _isAnimationMode;
  double get zoomLevel => _zoomLevel;
  Offset get canvasOffset => _canvasOffset;
  bool get isUiCollapsed => _isUiCollapsed;
  List<String> get recentFiles => _recentFiles;
  Layer? get currentLayer {
    if (_currentDocument == null || _currentDocument!.layers.isEmpty) {
      return null;
    }
    if (_currentLayerIndex < 0 ||
        _currentLayerIndex >= _currentDocument!.layers.length) {
      return null; // Or handle out-of-bounds, e.g., clamp index
    }
    return _currentDocument!.layers[_currentLayerIndex];
  }
}
