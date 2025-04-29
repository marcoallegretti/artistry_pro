import 'package:flutter/material.dart';
import '../models/painting_models.dart';
import '../services/filter_service.dart';

/// Represents a single action that can be undone/redone
class HistoryAction {
  final String id;
  final String name;
  final DateTime timestamp;
  final ActionType type;
  final Map<String, dynamic> data;
  
  HistoryAction({
    required this.id,
    required this.name,
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  @override
  String toString() => name;
}

/// Types of actions that can be recorded in history
enum ActionType {
  DRAW_STROKE,
  ERASE,
  ADD_LAYER,
  DELETE_LAYER,
  MERGE_LAYERS,
  REORDER_LAYERS,
  MODIFY_LAYER_PROPERTIES,
  APPLY_FILTER,
  TRANSFORM,
  CROP,
  TEXT_EDIT,
  FILL,
  SELECTION,
  PASTE,
  IMPORT_IMAGE,
  ADJUSTMENT,
}

/// History management for undo/redo operations
class HistoryManager extends ChangeNotifier {
  final int _maxHistorySize;
  final List<HistoryAction> _history = [];
  int _currentIndex = -1;
  
  bool _isUndoingOrRedoing = false;
  
  /// Constructor with optional max history size
  HistoryManager({int maxHistorySize = 100}) : _maxHistorySize = maxHistorySize;
  
  /// Check if undo is available
  bool get canUndo => _currentIndex >= 0;
  
  /// Check if redo is available
  bool get canRedo => _currentIndex < _history.length - 1;
  
  /// Get the current history state index
  int get currentIndex => _currentIndex;
  
  /// Get the history actions
  List<HistoryAction> get history => List.unmodifiable(_history);
  
  /// Add a new action to history
  void addAction(HistoryAction action) {
    if (_isUndoingOrRedoing) return;
    
    // Remove any actions after the current index (if we've undone actions)
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }
    
    // Add the new action
    _history.add(action);
    _currentIndex = _history.length - 1;
    
    // Trim history if it exceeds max size
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
      _currentIndex--;
    }
    
    notifyListeners();
  }
  
  /// Get the current action
  HistoryAction? get currentAction {
    if (_currentIndex >= 0 && _currentIndex < _history.length) {
      return _history[_currentIndex];
    }
    return null;
  }
  
  /// Perform an undo operation
  HistoryAction? undo() {
    if (!canUndo) return null;
    
    _isUndoingOrRedoing = true;
    final action = _history[_currentIndex];
    _currentIndex--;
    
    notifyListeners();
    _isUndoingOrRedoing = false;
    
    return action;
  }
  
  /// Perform a redo operation
  HistoryAction? redo() {
    if (!canRedo) return null;
    
    _isUndoingOrRedoing = true;
    _currentIndex++;
    final action = _history[_currentIndex];
    
    notifyListeners();
    _isUndoingOrRedoing = false;
    
    return action;
  }
  
  /// Clear all history
  void clear() {
    _history.clear();
    _currentIndex = -1;
    notifyListeners();
  }
  
  /// Jump to a specific history state
  HistoryAction? jumpToState(int index) {
    if (index < -1 || index >= _history.length) return null;
    
    _isUndoingOrRedoing = true;
    _currentIndex = index;
    final action = index >= 0 ? _history[index] : null;
    
    notifyListeners();
    _isUndoingOrRedoing = false;
    
    return action;
  }
  
  /// Group multiple actions together as a single undo/redo step
  void beginActionGroup(String groupName, ActionType type) {
    // Implement action grouping logic here
    // This would start tracking a group of actions that can be undone as one
  }
  
  /// End an action group
  void endActionGroup() {
    // Implement logic to finalize a group of actions
  }
  
  /// Create a history action for drawing a stroke
  static HistoryAction createDrawStrokeAction(String layerId, BrushStroke stroke) {
    return HistoryAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Draw Stroke',
      type: ActionType.DRAW_STROKE,
      data: {
        'layerId': layerId,
        'color': stroke.color.value,
        'width': stroke.width,
        'points': stroke.points.map((p) => {
          'x': p.point.dx,
          'y': p.point.dy,
          'pressure': p.pressure,
        }).toList(),
      },
    );
  }
  
  /// Create a history action for adding a layer
  static HistoryAction createAddLayerAction(Layer layer) {
    return HistoryAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Add Layer',
      type: ActionType.ADD_LAYER,
      data: {
        'layerId': layer.id,
        'name': layer.name,
        'visible': layer.visible,
        'opacity': layer.opacity,
        'blendMode': layer.blendMode.toString(),
      },
    );
  }
  
  /// Create a history action for deleting a layer
  static HistoryAction createDeleteLayerAction(Layer layer) {
    return HistoryAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Delete Layer',
      type: ActionType.DELETE_LAYER,
      data: {
        'layerId': layer.id,
        'name': layer.name,
        'visible': layer.visible,
        'opacity': layer.opacity,
        'blendMode': layer.blendMode.toString(),
        // In a real implementation, you might store the layer image data
        // to allow restoring it on undo
      },
    );
  }
  
  /// Create a history action for applying a filter
  static HistoryAction createApplyFilterAction(
    String layerId, 
    FilterType filterType,
    Map<String, dynamic> filterParams,
  ) {
    return HistoryAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Apply ${filterType.toString().split('.').last} Filter',
      type: ActionType.APPLY_FILTER,
      data: {
        'layerId': layerId,
        'filterType': filterType.toString(),
        'filterParams': filterParams,
      },
    );
  }
  
  /// Create a history action for transforming content
  static HistoryAction createTransformAction(
    String layerId,
    Map<String, dynamic> transformParams,
  ) {
    return HistoryAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Transform',
      type: ActionType.TRANSFORM,
      data: {
        'layerId': layerId,
        'transformParams': transformParams,
      },
    );
  }
  
  /// Create a history action for text edits
  static HistoryAction createTextEditAction(
    String layerId,
    String text,
    TextStyle style,
    Offset position,
  ) {
    return HistoryAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Edit Text',
      type: ActionType.TEXT_EDIT,
      data: {
        'layerId': layerId,
        'text': text,
        'fontFamily': style.fontFamily,
        'fontSize': style.fontSize,
        'fontWeight': style.fontWeight?.index,
        'color': style.color?.value,
        'x': position.dx,
        'y': position.dy,
      },
    );
  }
}

/// Extension to convert enum to string and back
extension ActionTypeExtension on ActionType {
  String toShortString() {
    return toString().split('.').last;
  }
  
  static ActionType fromString(String typeString) {
    return ActionType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () => ActionType.DRAW_STROKE,
    );
  }
}
