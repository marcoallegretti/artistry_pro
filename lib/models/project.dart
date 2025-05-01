import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'canvas_settings.dart';
import 'layer.dart';

/// Represents a painting project that can be saved and loaded
class Project {
  /// Unique identifier for the project
  final String id;
  
  /// Project title displayed to the user
  String title;
  
  /// When the project was created
  final DateTime createdAt;
  
  /// When the project was last modified
  DateTime lastModifiedAt;
  
  /// Canvas settings (size, background, etc.)
  final CanvasSettings canvasSettings;
  
  /// All layers in the project
  final List<Layer> layers;
  
  /// Currently selected layer index
  final int currentLayerIndex;
  
  /// Thumbnail image path (if saved)
  String? thumbnailPath;
  
  Project({
    String? id,
    required this.title,
    DateTime? createdAt,
    DateTime? lastModifiedAt,
    required this.canvasSettings,
    required this.layers,
    required this.currentLayerIndex,
    this.thumbnailPath,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    lastModifiedAt = lastModifiedAt ?? DateTime.now();
  
  /// Create a copy of this project with updated fields
  Project copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastModifiedAt,
    CanvasSettings? canvasSettings,
    List<Layer>? layers,
    int? currentLayerIndex,
    String? thumbnailPath,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? DateTime.now(),
      canvasSettings: canvasSettings ?? this.canvasSettings,
      layers: layers ?? this.layers,
      currentLayerIndex: currentLayerIndex ?? this.currentLayerIndex,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
  
  /// Create a new empty project with default settings
  static Project createNew({
    required String title,
    CanvasSettings? canvasSettings,
  }) {
    return Project(
      title: title,
      canvasSettings: canvasSettings ?? CanvasSettings.defaultSettings,
      layers: [
        Layer(
          id: const Uuid().v4(),
          name: 'Background',
          contentType: ContentType.drawing,
          opacity: 1.0,
          visible: true,
          blendMode: BlendMode.srcOver,
        ),
      ],
      currentLayerIndex: 0,
    );
  }
  
  @override
  String toString() {
    return 'Project{id: $id, title: $title, layers: ${layers.length}, lastModified: $lastModifiedAt}';
  }
}
