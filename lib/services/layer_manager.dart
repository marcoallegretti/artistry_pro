import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/layer.dart';

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
  final List<Layer> _layers = [];
  int _currentLayerIndex = 0;

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
    _saveSnapshot();
    final newLayer = Layer(
      id: const Uuid().v4(),
      name: name ?? 'Layer ${_layers.length + 1}',
      contentType: ContentType.drawing,
      opacity: 1.0,
      visible: true,
    );
    _layers.insert(_currentLayerIndex + 1, newLayer);
    _currentLayerIndex = _currentLayerIndex + 1;
    notifyListeners();
  }

  /// Removes a layer by index. Prevents deleting the last remaining layer.
  void deleteLayer(int index) {
    _saveSnapshot();
    if (_layers.length <= 1) return;
    _layers.removeAt(index);
    _currentLayerIndex = min(_currentLayerIndex, _layers.length - 1);
    notifyListeners();
  }

  /// Reorders layers (drag & drop style).
  void reorderLayer(int oldIndex, int newIndex) {
    _saveSnapshot();
    if (oldIndex == newIndex) return;

    // Compensate when moving down the list as per ReorderableListView docs.
    if (oldIndex < newIndex) newIndex -= 1;

    final layer = _layers.removeAt(oldIndex);
    _layers.insert(newIndex, layer);

    if (_currentLayerIndex == oldIndex) {
      _currentLayerIndex = newIndex;
    } else if (_currentLayerIndex > oldIndex && _currentLayerIndex <= newIndex) {
      _currentLayerIndex -= 1;
    } else if (_currentLayerIndex < oldIndex && _currentLayerIndex >= newIndex) {
      _currentLayerIndex += 1;
    }

    notifyListeners();
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
    _saveSnapshot();
    _layers[index].visible = !_layers[index].visible;
    notifyListeners();
  }

  /// Updates layer opacity.
  void setOpacity(int index, double opacity) {
    _saveSnapshot();
    opacity = opacity.clamp(0.0, 1.0);
    _layers[index].opacity = opacity;
    notifyListeners();
  }

  /// Locks / unlocks a layer.
  void toggleLock(int index) {
    _saveSnapshot();
    _layers[index].locked = !_layers[index].locked;
    notifyListeners();
  }

  /// Replaces the runtime payload of a layer – e.g. the actual drawing data.
  void setPayload(int index, dynamic payload) {
    _saveSnapshot();
    _layers[index].payload = payload;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Layer updates
  // -------------------------------------------------------------------------

  /// Sets the content type of a layer.
  void setContentType(int index, ContentType contentType) {
    _saveSnapshot();
    _layers[index].contentType = contentType;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Undo / redo helper snapshots (simple, not memory–optimised)
  // ---------------------------------------------------------------------------
  final List<List<Layer>> _undoStack = [];
  final List<List<Layer>> _redoStack = [];

  void _saveSnapshot() {
    _undoStack.add(_cloneLayers(_layers));
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_cloneLayers(_layers));
    _restoreLayers(_undoStack.removeLast());
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_cloneLayers(_layers));
    _restoreLayers(_redoStack.removeLast());
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  List<Layer> _cloneLayers(List<Layer> source) =>
      source.map((e) => e.copyWith()).toList();

  void _restoreLayers(List<Layer> snapshot) {
    _layers
      ..clear()
      ..addAll(snapshot);
    _currentLayerIndex = _currentLayerIndex.clamp(0, _layers.length - 1);
    notifyListeners();
  }
}
