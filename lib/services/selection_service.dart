import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Types of selections available
enum SelectionType {
  RECTANGULAR,
  ELLIPTICAL,
  LASSO,
  MAGIC_WAND,
  COLOR_RANGE,
  POLYGON,
}

/// Service for handling selections on the canvas
class SelectionService {
  Rect? _rectangularSelection;
  Path? _selectionPath;
  SelectionType _selectionType = SelectionType.RECTANGULAR;
  double _tolerance = 32.0; // For magic wand/color selection
  bool _feather = false;
  double _featherRadius = 2.0;
  
  /// Current selection type
  SelectionType get selectionType => _selectionType;
  set selectionType(SelectionType type) {
    _selectionType = type;
  }
  
  /// Check if there is an active selection
  bool get hasSelection => _selectionPath != null || _rectangularSelection != null;
  
  /// Get the current selection path
  Path? get selectionPath => _selectionPath;
  
  /// Get the current rectangular selection
  Rect? get rectangularSelection => _rectangularSelection;
  
  /// Feathering settings
  bool get feather => _feather;
  set feather(bool value) {
    _feather = value;
  }
  
  double get featherRadius => _featherRadius;
  set featherRadius(double value) {
    _featherRadius = value;
  }
  
  /// Tolerance for color-based selections
  double get tolerance => _tolerance;
  set tolerance(double value) {
    _tolerance = value;
  }
  
  /// Clear the current selection
  void clearSelection() {
    _rectangularSelection = null;
    _selectionPath = null;
  }
  
  /// Create a rectangular selection
  void createRectangularSelection(Offset start, Offset end) {
    _selectionType = SelectionType.RECTANGULAR;
    
    final left = math.min(start.dx, end.dx);
    final top = math.min(start.dy, end.dy);
    final right = math.max(start.dx, end.dx);
    final bottom = math.max(start.dy, end.dy);
    
    _rectangularSelection = Rect.fromLTRB(left, top, right, bottom);
    
    // Also update the path for consistent API
    _selectionPath = Path()..addRect(_rectangularSelection!);
  }
  
  /// Create an elliptical selection
  void createEllipticalSelection(Offset center, Offset radius) {
    _selectionType = SelectionType.ELLIPTICAL;
    
    final rx = (center.dx - radius.dx).abs();
    final ry = (center.dy - radius.dy).abs();
    
    _rectangularSelection = Rect.fromCenter(
      center: center,
      width: rx * 2,
      height: ry * 2,
    );
    
    _selectionPath = Path()..addOval(_rectangularSelection!);
  }
  
  /// Start a lasso selection
  void startLassoSelection(Offset point) {
    _selectionType = SelectionType.LASSO;
    _selectionPath = Path()..moveTo(point.dx, point.dy);
  }
  
  /// Add a point to the lasso selection
  void addLassoPoint(Offset point) {
    if (_selectionType != SelectionType.LASSO || _selectionPath == null) {
      startLassoSelection(point);
      return;
    }
    
    _selectionPath!.lineTo(point.dx, point.dy);
  }
  
  /// Complete a lasso selection by closing the path
  void completeLassoSelection() {
    if (_selectionType != SelectionType.LASSO || _selectionPath == null) {
      return;
    }
    
    _selectionPath!.close();
    
    // Update rectangular bounds
    _rectangularSelection = _selectionPath!.getBounds();
  }
  
  /// Magic wand selection based on color similarity
  Future<void> createMagicWandSelection(
    Offset point,
    ui.Image image,
  ) async {
    _selectionType = SelectionType.MAGIC_WAND;
    
    // Implementation would require image pixel data
    // This is a placeholder for future implementation
    
    // For now, create a simple circular selection around the point
    final radius = 50.0;  // Default radius for demonstration
    
    _selectionPath = Path()
      ..addOval(Rect.fromCircle(
        center: point,
        radius: radius,
      ));
    
    _rectangularSelection = _selectionPath!.getBounds();
  }
  
  /// Create a selection based on a specific color range
  Future<void> createColorRangeSelection(
    Color targetColor,
    ui.Image image,
    double tolerance,
  ) async {
    _selectionType = SelectionType.COLOR_RANGE;
    _tolerance = tolerance;
    
    // Implementation would require image pixel data
    // This is a placeholder for future implementation
    
    // For now, we'll just create a dummy selection covering 25% of the image
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    
    _rectangularSelection = Rect.fromLTWH(
      width * 0.25,
      height * 0.25,
      width * 0.5,
      height * 0.5,
    );
    
    _selectionPath = Path()..addRect(_rectangularSelection!);
  }
  
  /// Create a polygon selection from a list of points
  void createPolygonSelection(List<Offset> points) {
    if (points.isEmpty) return;
    
    _selectionType = SelectionType.POLYGON;
    
    _selectionPath = Path()..moveTo(points.first.dx, points.first.dy);
    
    for (int i = 1; i < points.length; i++) {
      _selectionPath!.lineTo(points[i].dx, points[i].dy);
    }
    
    _selectionPath!.close();
    _rectangularSelection = _selectionPath!.getBounds();
  }
  
  /// Expand the current selection by a number of pixels
  void expandSelection(double pixels) {
    if (!hasSelection) return;
    
    if (_selectionPath != null) {
      // Create a dilated path
      // This is a simplified approach - a proper implementation would use
      // more sophisticated path manipulation
      final bounds = _selectionPath!.getBounds();
      final expandedBounds = Rect.fromLTRB(
        bounds.left - pixels,
        bounds.top - pixels,
        bounds.right + pixels,
        bounds.bottom + pixels,
      );
      
      _rectangularSelection = expandedBounds;
      
      if (_selectionType == SelectionType.RECTANGULAR) {
        _selectionPath = Path()..addRect(expandedBounds);
      } else if (_selectionType == SelectionType.ELLIPTICAL) {
        _selectionPath = Path()..addOval(expandedBounds);
      }
      // For other selection types, we'd need more complex path manipulation
    }
  }
  
  /// Contract the current selection by a number of pixels
  void contractSelection(double pixels) {
    if (!hasSelection) return;
    
    if (_selectionPath != null) {
      // Create a contracted path
      // This is a simplified approach
      final bounds = _selectionPath!.getBounds();
      final contractedBounds = Rect.fromLTRB(
        bounds.left + pixels,
        bounds.top + pixels,
        bounds.right - pixels,
        bounds.bottom - pixels,
      );
      
      // Check if contraction would make selection too small
      if (contractedBounds.width <= 1 || contractedBounds.height <= 1) {
        return;
      }
      
      _rectangularSelection = contractedBounds;
      
      if (_selectionType == SelectionType.RECTANGULAR) {
        _selectionPath = Path()..addRect(contractedBounds);
      } else if (_selectionType == SelectionType.ELLIPTICAL) {
        _selectionPath = Path()..addOval(contractedBounds);
      }
      // For other selection types, we'd need more complex path manipulation
    }
  }
  
  /// Create a mask image from the current selection
  Future<ui.Image> createSelectionMask(Size canvasSize) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    // Fill with transparent (unselected areas)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      Paint()..color = Colors.transparent,
    );
    
    if (_selectionPath != null) {
      final paint = Paint()
        ..color = Colors.white  // White represents selected areas
        ..style = PaintingStyle.fill;
      
      canvas.drawPath(_selectionPath!, paint);
    }
    
    final picture = pictureRecorder.endRecording();
    return await picture.toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt(),
    );
  }
  
  /// Invert the current selection
  void invertSelection(Size canvasSize) {
    if (!hasSelection) {
      // If no selection, select everything
      _rectangularSelection = Rect.fromLTWH(
        0, 0, canvasSize.width, canvasSize.height);
      _selectionPath = Path()..addRect(_rectangularSelection!);
      return;
    }
    
    final fullCanvas = Path()
      ..addRect(Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height));
    
    // Create a path representing the inverse of the current selection
    if (_selectionType == SelectionType.RECTANGULAR || 
        _selectionType == SelectionType.ELLIPTICAL) {
      _selectionPath = Path.combine(
        PathOperation.difference,
        fullCanvas,
        _selectionPath!,
      );
    } else {
      // For complex paths, we simply invert using the bounding rectangle
      _selectionPath = Path.combine(
        PathOperation.difference,
        fullCanvas,
        _selectionPath!,
      );
    }
    
    _rectangularSelection = _selectionPath!.getBounds();
  }
}

// Helper for math operations
class math {
  static double min(double a, double b) => a < b ? a : b;
  static double max(double a, double b) => a > b ? a : b;
}
