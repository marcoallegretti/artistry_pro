import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/layer.dart';
import '../screens/pro_canvas.dart'; // Added import for DrawingPoint type

/// Centralised manager for handling canvas layers.
///
/// The class purposely extends [ChangeNotifier] so that the UI can easily
/// listen for updates via `AnimatedBuilder`, `ValueListenableBuilder`, Provider
/// or Riverpod without having to manually call `setState` everywhere.
class LayerManager extends ChangeNotifier {
  LayerManager({String? baseLayerName}) {
    // Always start with a single base layer.
    _layers.add(
      Layer(
        id: const Uuid().v4(),
        name: baseLayerName ?? 'Background',
        contentType: ContentType.drawing,
        opacity: 1.0,
        visible: true,
        blendMode: ui.BlendMode.srcOver,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------
  List<Layer> _layers = [];
  int _currentLayerIndex = 0;

  // Undo/Redo stacks and methods
  List<Map<String, dynamic>> _undoStack = [];
  List<Map<String, dynamic>> _redoStack = [];
  
  /// Public method to save the current state to the undo stack
  void saveState() {
    _saveState();
  }
  
  void _saveState() {
    // Make a copy of the current state
    final layersCopy = <Layer>[];
    
    for (var layer in _layers) {
      if (layer.contentType == ContentType.drawing && layer.payload is List) {
        // Deep clone drawing points for drawing layers
        final List<DrawingPoint?> pointsCopy = [];
        final points = layer.payload as List;
        
        for (var point in points) {
          if (point == null) {
            pointsCopy.add(null);
          } else if (point is DrawingPoint) {
            final Paint newPaint = Paint()
              ..color = point.paint.color
              ..strokeWidth = point.paint.strokeWidth
              ..strokeCap = point.paint.strokeCap
              ..blendMode = point.paint.blendMode;
              
            pointsCopy.add(DrawingPoint(point.point, newPaint, isEraser: point.isEraser));
          }
        }
        
        layersCopy.add(layer.copyWith(payload: pointsCopy));
      } else {
        // For other layer types, make a shallow copy
        layersCopy.add(layer.copyWith());
      }
    }
    
    _undoStack.add({
      'layers': layersCopy,
      'index': _currentLayerIndex
    });
    
    debugPrint('State saved to undo stack. Stack size: ${_undoStack.length}');
  }
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  void undo() {
    if (canUndo) {
      print('LayerManager: Undo called. Current undo stack size: ${_undoStack.length}, restoring state.');
      
      // Save current state to redo stack first
      final currentState = <Layer>[];
      for (var layer in _layers) {
        if (layer.contentType == ContentType.drawing && layer.payload is List) {
          // Deep clone drawing points
          final List<DrawingPoint?> pointsCopy = [];
          final points = layer.payload as List;
          
          for (var point in points) {
            if (point == null) {
              pointsCopy.add(null);
            } else if (point is DrawingPoint) {
              final Paint newPaint = Paint()
                ..color = point.paint.color
                ..strokeWidth = point.paint.strokeWidth
                ..strokeCap = point.paint.strokeCap
                ..blendMode = point.paint.blendMode;
                
              pointsCopy.add(DrawingPoint(point.point, newPaint, isEraser: point.isEraser));
            }
          }
          
          currentState.add(layer.copyWith(payload: pointsCopy));
        } else {
          currentState.add(layer.copyWith());
        }
      }
      
      _redoStack.add({
        'layers': currentState,
        'index': _currentLayerIndex
      });
      
      // Now restore the previous state from undo stack
      var state = _undoStack.removeLast();
      _layers.clear();
      
      // Direct copy of the layers from saved state - no need for conversion as we saved them correctly
      final savedLayers = state['layers'] as List<Layer>;
      _layers.addAll(savedLayers);
      
      _currentLayerIndex = state['index'] as int;
      print('LayerManager: Undo applied. New undo stack size: ${_undoStack.length}, redo stack size: ${_redoStack.length}');
      notifyListeners();
    } else {
      print('LayerManager: Undo attempted but no states to undo.');
    }
  }
  void redo() {
    if (canRedo) {
      print('LayerManager: Redo called. Current redo stack size: ${_redoStack.length}, restoring state.');
      
      // Save current state to undo stack first
      final currentState = <Layer>[];
      for (var layer in _layers) {
        if (layer.contentType == ContentType.drawing && layer.payload is List) {
          // Deep clone drawing points
          final List<DrawingPoint?> pointsCopy = [];
          final points = layer.payload as List;
          
          for (var point in points) {
            if (point == null) {
              pointsCopy.add(null);
            } else if (point is DrawingPoint) {
              final Paint newPaint = Paint()
                ..color = point.paint.color
                ..strokeWidth = point.paint.strokeWidth
                ..strokeCap = point.paint.strokeCap
                ..blendMode = point.paint.blendMode;
                
              pointsCopy.add(DrawingPoint(point.point, newPaint, isEraser: point.isEraser));
            }
          }
          
          currentState.add(layer.copyWith(payload: pointsCopy));
        } else {
          currentState.add(layer.copyWith());
        }
      }
      
      _undoStack.add({
        'layers': currentState,
        'index': _currentLayerIndex
      });
      
      // Now restore the next state from redo stack
      var state = _redoStack.removeLast();
      _layers.clear();
      
      // Direct copy of the layers from saved state - no need for conversion as we saved them correctly
      final savedLayers = state['layers'] as List<Layer>;
      _layers.addAll(savedLayers);
      
      _currentLayerIndex = state['index'] as int;
      print('LayerManager: Redo applied. New undo stack size: ${_undoStack.length}, redo stack size: ${_redoStack.length}');
      notifyListeners();
    } else {
      print('LayerManager: Redo attempted but no states to redo.');
    }
  }

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------
  List<Layer> get layers => List.unmodifiable(_layers);
  int get currentLayerIndex => _currentLayerIndex;
  Layer get currentLayer => _layers[_currentLayerIndex];

  // ---------------------------------------------------------------------------
  // Layer CRUD
  // ---------------------------------------------------------------------------

  /// Adds a new, empty raster layer above the current one.
  void addLayer({String? name}) {
    _saveState();
    _redoStack.clear();
    final newLayer = Layer(
      id: const Uuid().v4(),
      name: name ?? 'Layer ${_layers.length + 1}',
      contentType: ContentType.drawing,
      opacity: 1.0,
      visible: true,
    );
    _layers.insert(_currentLayerIndex + 1, newLayer);
    _currentLayerIndex++;
    notifyListeners();
  }

  /// Removes a layer by index. Prevents deleting the last remaining layer.
  void deleteLayer(int index) {
    if (_layers.length <= 1) return;
    _saveState();
    _redoStack.clear();
    _layers.removeAt(index);
    _currentLayerIndex = min(_currentLayerIndex, _layers.length - 1);
    notifyListeners();
  }

  /// Reorders layers (drag & drop style).
  void reorderLayer(int oldIndex, int newIndex) {
    if (oldIndex != newIndex) {
      _saveState();
      _redoStack.clear();
      if (oldIndex < newIndex) newIndex--;
      final layer = _layers.removeAt(oldIndex);
      _layers.insert(newIndex, layer);
      if (_currentLayerIndex == oldIndex) _currentLayerIndex = newIndex;
      else if (_currentLayerIndex > oldIndex && _currentLayerIndex <= newIndex) _currentLayerIndex--;
      else if (_currentLayerIndex < oldIndex && _currentLayerIndex >= newIndex) _currentLayerIndex++;
      notifyListeners();
    }
  }

  /// Selects the active editing layer.
  void selectLayer(int index) {
    if (index < 0 || index >= _layers.length) return;
    if (index == _currentLayerIndex) return;
    _currentLayerIndex = index;
    notifyListeners();
  }

  /// Toggles layer visibility.
  void toggleVisibility(int index) {
    _saveState();
    _redoStack.clear();
    _layers[index].visible = !_layers[index].visible;
    notifyListeners();
  }

  /// Updates layer opacity.
  void setOpacity(int index, double opacity) {
    _saveState();
    _redoStack.clear();
    _layers[index].opacity = opacity.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Locks / unlocks a layer.
  void toggleLock(int index) {
    _saveState();
    _redoStack.clear();
    _layers[index].locked = !_layers[index].locked;
    notifyListeners();
  }

  /// Replaces the runtime payload of a layer – e.g. the actual drawing data.
  /// If saveState is true, the current state will be saved to the undo stack.
  /// Set saveState to false during continuous updates like drawing to avoid
  /// filling the undo stack with every small change.
  void setPayload(int index, dynamic payload, {bool saveState = true}) {
    if (saveState) {
      print('LayerManager: Saving state before setting payload for layer index $index');
      _saveState();
      _redoStack.clear();
    }
    
    _layers[index].payload = payload;
    
    if (saveState) {
      print('LayerManager: Payload set for layer index $index. Undo stack size: ${_undoStack.length}, Redo stack size: ${_redoStack.length}');
    }
    
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Layer updates
  // -------------------------------------------------------------------------

  /// Sets the content type of a layer.
  void setContentType(int index, ContentType contentType) {
    _saveState();
    _redoStack.clear();
    _layers[index].contentType = contentType;
    notifyListeners();
  }
}
