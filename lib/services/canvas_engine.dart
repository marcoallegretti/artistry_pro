import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/painting_models.dart';

/// Manages the canvas state and operations
class CanvasEngine {
  static final Uuid _uuid = Uuid(); // Fixed declaration
  late CanvasDocument document;
  late List<Layer> _layers;
  int _currentLayerIndex = 0;
  final List<Map<String, dynamic>> _undoStack = [];
  final List<Map<String, dynamic>> _redoStack = [];
  final int _maxUndoSteps = 30;

  /// Initialize with a new document
  CanvasEngine.newDocument({
    required String name,
    required Size size,
    double resolution = 300.0,
    ColorMode colorMode = ColorMode.RGB,
  }) {
    final baseLayerId = _uuid.v4();
    final baseLayer = Layer(
      id: baseLayerId,
      name: 'Background',
      opacity: 1.0,
      blendMode: BlendMode.NORMAL,
    );

    _layers = [baseLayer];
    document = CanvasDocument(
      id: _uuid.v4(),
      name: name,
      size: size,
      resolution: resolution,
      colorMode: colorMode,
      layers: _layers,
    );
  }

  /// Get the current active layer
  Layer get currentLayer => _layers[_currentLayerIndex];

  /// Set the current active layer by index
  set currentLayerIndex(int index) {
    if (index >= 0 && index < _layers.length) {
      _currentLayerIndex = index;
    }
  }

  /// Set current layer by ID
  void setCurrentLayerById(String id) {
    final index = _layers.indexWhere((layer) => layer.id == id);
    if (index != -1) {
      _currentLayerIndex = index;
    }
  }

  /// Add a new layer
  Layer addNewLayer({
    String? name,
    BlendMode blendMode = BlendMode.NORMAL,
    double opacity = 1.0,
    bool isMask = false,
    String? parentLayerId,
  }) {
    final newLayer = Layer(
      id: _uuid.v4(),
      name: name ?? 'Layer ${_layers.length}',
      visible: true,
      opacity: opacity,
      blendMode: blendMode,
      isMask: isMask,
      parentLayerId: parentLayerId,
    );

    // Add to undo stack
    _pushUndoAction({
      'type': 'addLayer',
      'layer': newLayer,
    });

    _layers.add(newLayer);
    document = document.copyWith(layers: _layers);
    _currentLayerIndex = _layers.length - 1;
    return newLayer;
  }

  /// Delete the current layer
  void deleteCurrentLayer() {
    if (_layers.length <= 1) {
      return; // Prevent deleting the last layer
    }

    // Add to undo stack
    _pushUndoAction({
      'type': 'deleteLayer',
      'layer': _layers[_currentLayerIndex],
      'index': _currentLayerIndex,
    });

    _layers.removeAt(_currentLayerIndex);
    document = document.copyWith(layers: _layers);
    _currentLayerIndex = _currentLayerIndex > 0 ? _currentLayerIndex - 1 : 0;
  }

  /// Move a layer to a new position
  void moveLayer(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _layers.length ||
        newIndex < 0 ||
        newIndex >= _layers.length) {
      return;
    }

    // Add to undo stack
    _pushUndoAction({
      'type': 'moveLayer',
      'oldIndex': oldIndex,
      'newIndex': newIndex,
    });

    final layer = _layers.removeAt(oldIndex);
    _layers.insert(newIndex, layer);
    document = document.copyWith(layers: _layers);

    if (_currentLayerIndex == oldIndex) {
      _currentLayerIndex = newIndex;
    }
  }

  /// Set layer visibility
  void setLayerVisibility(int layerIndex, bool visible) {
    if (layerIndex < 0 || layerIndex >= _layers.length) {
      return;
    }

    // Add to undo stack
    _pushUndoAction({
      'type': 'setVisibility',
      'layerIndex': layerIndex,
      'oldVisibility': _layers[layerIndex].visible,
    });

    final layer = _layers[layerIndex];
    _layers[layerIndex] = layer.copyWith(visible: visible);
    document = document.copyWith(layers: _layers);
  }

  /// Set layer opacity
  void setLayerOpacity(int layerIndex, double opacity) {
    if (layerIndex < 0 || layerIndex >= _layers.length) {
      return;
    }

    // Add to undo stack
    _pushUndoAction({
      'type': 'setOpacity',
      'layerIndex': layerIndex,
      'oldOpacity': _layers[layerIndex].opacity,
    });

    final layer = _layers[layerIndex];
    _layers[layerIndex] = layer.copyWith(opacity: opacity);
    document = document.copyWith(layers: _layers);
  }

  /// Set layer blend mode
  void setLayerBlendMode(int layerIndex, BlendMode blendMode) {
    if (layerIndex < 0 || layerIndex >= _layers.length) {
      return;
    }

    // Add to undo stack
    _pushUndoAction({
      'type': 'setBlendMode',
      'layerIndex': layerIndex,
      'oldBlendMode': _layers[layerIndex].blendMode,
    });

    final layer = _layers[layerIndex];
    _layers[layerIndex] = layer.copyWith(blendMode: blendMode);
    document = document.copyWith(layers: _layers);
  }

  /// Apply a brush stroke to the current layer
  Future<void> applyBrushStroke(BrushStroke stroke) async {
    if (_currentLayerIndex < 0 || _currentLayerIndex >= _layers.length) {
      return;
    }

    final layer = _layers[_currentLayerIndex];
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw the existing layer image if it exists
    if (layer.image != null) {
      canvas.drawImage(layer.image!, Offset.zero, Paint());
    }

    // Draw the new stroke
    if (stroke.points.isNotEmpty) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = stroke.cap
        ..strokeJoin = stroke.join
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(stroke.points.first.point.dx, stroke.points.first.point.dy);

      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].point.dx, stroke.points[i].point.dy);
      }

      canvas.drawPath(path, paint);
    }

    // Convert to an image
    final picture = recorder.endRecording();
    final width = document.size.width.toInt();
    final height = document.size.height.toInt();
    final ui.Image image = await picture.toImage(width, height);

    // Add to undo stack before modifying
    _pushUndoAction({
      'type': 'brushStroke',
      'layerIndex': _currentLayerIndex,
      'oldImage': layer.image,
    });

    // Update layer with new image
    _layers[_currentLayerIndex] = layer.copyWith(image: image);
    document = document.copyWith(layers: _layers);
  }

  /// Merge two layers
  Future<void> mergeLayers(int topLayerIndex, int bottomLayerIndex) async {
    if (topLayerIndex < 0 ||
        topLayerIndex >= _layers.length ||
        bottomLayerIndex < 0 ||
        bottomLayerIndex >= _layers.length) {
      return;
    }

    final topLayer = _layers[topLayerIndex];
    final bottomLayer = _layers[bottomLayerIndex];

    // Skip if either layer doesn't have an image
    if (topLayer.image == null || bottomLayer.image == null) {
      return;
    }

    // Record current state for undo
    _pushUndoAction({
      'type': 'mergeLayers',
      'topLayerIndex': topLayerIndex,
      'bottomLayerIndex': bottomLayerIndex,
      'topLayer': topLayer,
      'bottomLayer': bottomLayer,
    });

    // Create a new merged image
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw bottom layer
    final bottomPaint = Paint();
    canvas.drawImage(bottomLayer.image!, Offset.zero, bottomPaint);

    // Draw top layer with blend mode
    final topPaint = Paint()
      ..blendMode = mapBlendMode(topLayer.blendMode)
      ..colorFilter = ColorFilter.mode(
          Colors.white.withOpacity(topLayer.opacity), ui.BlendMode.dstIn);
    canvas.drawImage(topLayer.image!, Offset.zero, topPaint);

    // Convert to an image
    final picture = recorder.endRecording();
    final width = document.size.width.toInt();
    final height = document.size.height.toInt();
    final ui.Image mergedImage = await picture.toImage(width, height);

    // Update bottom layer with merged image
    _layers[bottomLayerIndex] = bottomLayer.copyWith(image: mergedImage);

    // Remove top layer
    _layers.removeAt(topLayerIndex);
    document = document.copyWith(layers: _layers);

    // Adjust current layer index if needed
    if (_currentLayerIndex == topLayerIndex) {
      _currentLayerIndex = bottomLayerIndex;
    } else if (_currentLayerIndex > topLayerIndex) {
      _currentLayerIndex--;
    }
  }

  /// Push an action to the undo stack
  void _pushUndoAction(Map<String, dynamic> action) {
    _undoStack.add(action);
    _redoStack.clear(); // Clear redo stack when a new action is performed

    // Limit undo stack size
    if (_undoStack.length > _maxUndoSteps) {
      _undoStack.removeAt(0);
    }
  }

  /// Undo the last action
  Future<void> undo() async {
    if (_undoStack.isEmpty) {
      return;
    }

    final action = _undoStack.removeLast();
    _redoStack.add(action);

    switch (action['type']) {
      case 'addLayer':
        final layerId = action['layer'].id;
        final index = _layers.indexWhere((layer) => layer.id == layerId);
        if (index != -1) {
          _layers.removeAt(index);
          if (_currentLayerIndex >= index) {
            _currentLayerIndex =
                _currentLayerIndex > 0 ? _currentLayerIndex - 1 : 0;
          }
        }
        break;

      case 'deleteLayer':
        final layer = action['layer'];
        final index = action['index'];
        if (index >= 0 && index <= _layers.length) {
          _layers.insert(index, layer);
          if (_currentLayerIndex >= index) {
            _currentLayerIndex++;
          }
        }
        break;

      case 'moveLayer':
        final oldIndex = action['oldIndex'];
        final newIndex = action['newIndex'];
        if (oldIndex >= 0 &&
            oldIndex < _layers.length &&
            newIndex >= 0 &&
            newIndex < _layers.length) {
          final layer = _layers.removeAt(newIndex);
          _layers.insert(oldIndex, layer);
          if (_currentLayerIndex == newIndex) {
            _currentLayerIndex = oldIndex;
          }
        }
        break;

      case 'setVisibility':
        final layerIndex = action['layerIndex'];
        final oldVisibility = action['oldVisibility'];
        if (layerIndex >= 0 && layerIndex < _layers.length) {
          final layer = _layers[layerIndex];
          _layers[layerIndex] = layer.copyWith(visible: oldVisibility);
        }
        break;

      case 'setOpacity':
        final layerIndex = action['layerIndex'];
        final oldOpacity = action['oldOpacity'];
        if (layerIndex >= 0 && layerIndex < _layers.length) {
          final layer = _layers[layerIndex];
          _layers[layerIndex] = layer.copyWith(opacity: oldOpacity);
        }
        break;

      case 'setBlendMode':
        final layerIndex = action['layerIndex'];
        final oldBlendMode = action['oldBlendMode'];
        if (layerIndex >= 0 && layerIndex < _layers.length) {
          final layer = _layers[layerIndex];
          _layers[layerIndex] = layer.copyWith(blendMode: oldBlendMode);
        }
        break;

      case 'brushStroke':
        final layerIndex = action['layerIndex'];
        final oldImage = action['oldImage'];
        if (layerIndex >= 0 && layerIndex < _layers.length) {
          final layer = _layers[layerIndex];
          _layers[layerIndex] = layer.copyWith(image: oldImage);
        }
        break;

      case 'mergeLayers':
        final topLayerIndex = action['topLayerIndex'];
        final bottomLayerIndex = action['bottomLayerIndex'];
        final topLayer = action['topLayer'];
        final bottomLayer = action['bottomLayer'];

        if (bottomLayerIndex >= 0 && bottomLayerIndex < _layers.length) {
          // Restore bottom layer
          _layers[bottomLayerIndex] = bottomLayer;

          // Insert top layer back
          if (topLayerIndex >= 0 && topLayerIndex <= _layers.length) {
            _layers.insert(topLayerIndex, topLayer);
            if (_currentLayerIndex >= topLayerIndex) {
              _currentLayerIndex++;
            }
          }
        }
        break;
    }

    document = document.copyWith(layers: _layers);
  }

  /// Redo the last undone action
  Future<void> redo() async {
    if (_redoStack.isEmpty) {
      return;
    }

    final action = _redoStack.removeLast();
    _undoStack.add(action);

    switch (action['type']) {
      case 'addLayer':
        final layer = action['layer'];
        _layers.add(layer);
        _currentLayerIndex = _layers.length - 1;
        break;

      case 'deleteLayer':
        final index = action['index'];
        if (index >= 0 && index < _layers.length) {
          _layers.removeAt(index);
          if (_currentLayerIndex >= index) {
            _currentLayerIndex =
                _currentLayerIndex > 0 ? _currentLayerIndex - 1 : 0;
          }
        }
        break;

      case 'moveLayer':
        final oldIndex = action['oldIndex'];
        final newIndex = action['newIndex'];
        if (oldIndex >= 0 && oldIndex < _layers.length) {
          final layer = _layers.removeAt(oldIndex);
          _layers.insert(newIndex, layer);
          if (_currentLayerIndex == oldIndex) {
            _currentLayerIndex = newIndex;
          }
        }
        break;

      case 'setVisibility':
        final layerIndex = action['layerIndex'];
        if (layerIndex >= 0 && layerIndex < _layers.length) {
          final layer = _layers[layerIndex];
          _layers[layerIndex] =
              layer.copyWith(visible: !action['oldVisibility']);
        }
        break;

      case 'setOpacity':
        // Implementation would require storing the new opacity as well
        break;

      case 'setBlendMode':
        // Implementation would require storing the new blend mode as well
        break;

      case 'brushStroke':
        // Implementation would require storing the new image as well
        break;

      case 'mergeLayers':
        final topLayerIndex = action['topLayerIndex'];
        final bottomLayerIndex = action['bottomLayerIndex'];

        // Remove top layer
        if (topLayerIndex >= 0 && topLayerIndex < _layers.length) {
          final topLayer = _layers.removeAt(topLayerIndex);

          // Would need to re-merge the layers here with original logic
        }
        break;
    }

    document = document.copyWith(layers: _layers);
  }

  /// Clear undo and redo stacks
  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
  }

  /// Check if undo is available
  bool get canUndo => _undoStack.isNotEmpty;

  /// Check if redo is available
  bool get canRedo => _redoStack.isNotEmpty;
}
