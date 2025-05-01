import 'dart:ui' as ui;

/// Basic layer model for the new pro‑grade layer system.
///
/// This class intentionally starts small – we can extend it with more
/// properties (masks, effects, adjustment types, etc.) once the core
/// pipeline is wired up.
enum ContentType { drawing, image }

class Layer {
  /// Unique identifier – useful when we start wiring persistence, selections
  /// and drag‑and‑drop re‑ordering.
  final String id;

  /// Display name shown in the layers panel.
  String name;

  /// Visibility toggle.
  bool visible;

  /// Overall layer opacity (0 – invisible, 1 – fully opaque).
  double opacity;

  /// Blend mode applied when compositing this layer onto the canvas.
  ui.BlendMode blendMode;

  /// Whether the layer is locked for editing.
  bool locked;

  /// Type of content in the payload.
  ContentType contentType;

  /// Arbitrary payload that represents the raster/vector data for this layer.
  ///
  /// For the first milestone we keep using the existing `List<DrawingPoint?>`
  /// from `pro_canvas.dart`. We store it as `dynamic` here to avoid circular
  /// imports.  The concrete widgets / engines know the exact runtime type.
  dynamic payload;

  Layer({
    required this.id,
    required this.name,
    this.visible = true,
    this.opacity = 1.0,
    this.blendMode = ui.BlendMode.srcOver,
    this.locked = false,
    required this.contentType,
    this.payload,
  }) {
    if (payload == null && contentType == ContentType.drawing) {
      payload = <dynamic>[];
    }
  }

  /// Helper clone with updated fields.
  Layer copyWith({
    String? id,
    String? name,
    bool? visible,
    double? opacity,
    ui.BlendMode? blendMode,
    bool? locked,
    ContentType? contentType,
    dynamic payload,
  }) {
    return Layer(
      id: id ?? this.id,
      name: name ?? this.name,
      visible: visible ?? this.visible,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      locked: locked ?? this.locked,
      contentType: contentType ?? this.contentType,
      payload: payload ?? this.payload,
    );
  }

  @override
  String toString() {
    return 'Layer{id: $id, name: $name, visible: $visible, opacity: $opacity, blendMode: $blendMode, locked: $locked, contentType: $contentType}';
  }
}
