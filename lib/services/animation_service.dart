import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/painting_models.dart';

/// Manages animation functionality
class AnimationService {
  static const Uuid _uuid = Uuid(); // Fixed declaration
  List<AnimationFrame> _frames = [];
  int _currentFrameIndex = 0;
  AnimationSettings _settings = AnimationSettings();
  bool _isPlaying = false;
  int _playbackFrameRate = 24;

  /// Initialize animation service with a single frame
  AnimationService.withInitialFrame(CanvasDocument document) {
    // Create initial frame with a copy of document layers
    final initialFrame = AnimationFrame(
      id: _uuid.v4(),
      frameNumber: 1,
      duration: Duration(milliseconds: 1000 ~/ _playbackFrameRate),
      layers: List.from(document.layers),
    );

    _frames = [initialFrame];
  }

  /// Get all animation frames
  List<AnimationFrame> get frames => _frames;

  /// Get current frame
  AnimationFrame get currentFrame => _frames[_currentFrameIndex];

  /// Get current frame index
  int get currentFrameIndex => _currentFrameIndex;

  /// Set current frame index
  set currentFrameIndex(int index) {
    if (index >= 0 && index < _frames.length) {
      _currentFrameIndex = index;
    }
  }

  /// Get animation settings
  AnimationSettings get settings => _settings;

  /// Update animation settings
  void updateSettings(AnimationSettings newSettings) {
    _settings = newSettings;
  }

  /// Add a new frame
  AnimationFrame addNewFrame() {
    // Determine the position to insert the new frame
    final newPosition = _currentFrameIndex + 1;

    // Duplicate the current frame's layers
    final layersCopy = _frames[_currentFrameIndex]
        .layers
        .map((layer) => layer.copyWith())
        .toList();

    // Create the new frame
    final newFrame = AnimationFrame(
      id: _uuid.v4(),
      frameNumber: newPosition + 1, // 1-indexed for display
      duration: Duration(milliseconds: 1000 ~/ _playbackFrameRate),
      layers: layersCopy,
    );

    // Insert the new frame
    _frames.insert(newPosition, newFrame);

    // Update frame numbers for frames after the inserted one
    for (int i = newPosition + 1; i < _frames.length; i++) {
      _frames[i] = _frames[i].copyWith(frameNumber: i + 1);
    }

    // Set current frame to the newly created one
    _currentFrameIndex = newPosition;

    return newFrame;
  }

  /// Delete the current frame
  void deleteCurrentFrame() {
    if (_frames.length <= 1) {
      return; // Prevent deleting the last frame
    }

    _frames.removeAt(_currentFrameIndex);

    // Update frame numbers
    for (int i = _currentFrameIndex; i < _frames.length; i++) {
      _frames[i] = _frames[i].copyWith(frameNumber: i + 1);
    }

    // Adjust current frame index if needed
    if (_currentFrameIndex >= _frames.length) {
      _currentFrameIndex = _frames.length - 1;
    }
  }

  /// Duplicate the current frame
  AnimationFrame duplicateCurrentFrame() {
    // Create a copy of the current frame
    final layersCopy = _frames[_currentFrameIndex]
        .layers
        .map((layer) => layer.copyWith())
        .toList();

    final duplicatedFrame = AnimationFrame(
      id: _uuid.v4(),
      frameNumber: _currentFrameIndex + 2, // Position after current
      duration: _frames[_currentFrameIndex].duration,
      layers: layersCopy,
    );

    // Insert the duplicated frame after the current one
    _frames.insert(_currentFrameIndex + 1, duplicatedFrame);

    // Update frame numbers for frames after the inserted one
    for (int i = _currentFrameIndex + 2; i < _frames.length; i++) {
      _frames[i] = _frames[i].copyWith(frameNumber: i + 1);
    }

    // Move to the duplicated frame
    _currentFrameIndex++;

    return duplicatedFrame;
  }

  /// Move a frame to a new position
  void moveFrame(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _frames.length ||
        newIndex < 0 ||
        newIndex >= _frames.length) {
      return;
    }

    final frame = _frames.removeAt(oldIndex);
    _frames.insert(newIndex, frame);

    // Update frame numbers
    for (int i = 0; i < _frames.length; i++) {
      _frames[i] = _frames[i].copyWith(frameNumber: i + 1);
    }

    // Update current frame index if needed
    if (_currentFrameIndex == oldIndex) {
      _currentFrameIndex = newIndex;
    } else if (_currentFrameIndex > oldIndex &&
        _currentFrameIndex <= newIndex) {
      _currentFrameIndex--;
    } else if (_currentFrameIndex < oldIndex &&
        _currentFrameIndex >= newIndex) {
      _currentFrameIndex++;
    }
  }

  /// Set frame duration
  void setFrameDuration(int frameIndex, Duration duration) {
    if (frameIndex < 0 || frameIndex >= _frames.length) {
      return;
    }

    _frames[frameIndex] = _frames[frameIndex].copyWith(duration: duration);
  }

  /// Get total animation duration
  Duration get totalDuration {
    int totalMilliseconds = 0;
    for (final frame in _frames) {
      totalMilliseconds += frame.duration.inMilliseconds;
    }
    return Duration(milliseconds: totalMilliseconds);
  }

  /// Get playback status
  bool get isPlaying => _isPlaying;

  /// Start animation playback
  void play() {
    _isPlaying = true;
  }

  /// Pause animation playback
  void pause() {
    _isPlaying = false;
  }

  /// Toggle play/pause
  void togglePlayback() {
    _isPlaying = !_isPlaying;
  }

  /// Move to next frame
  void nextFrame() {
    if (_currentFrameIndex < _frames.length - 1) {
      _currentFrameIndex++;
    } else if (_isPlaying) {
      // Loop back to the first frame during playback
      _currentFrameIndex = 0;
    }
  }

  /// Move to previous frame
  void previousFrame() {
    if (_currentFrameIndex > 0) {
      _currentFrameIndex--;
    }
  }

  /// Go to first frame
  void firstFrame() {
    _currentFrameIndex = 0;
  }

  /// Go to last frame
  void lastFrame() {
    _currentFrameIndex = _frames.length - 1;
  }

  /// Set playback frame rate
  set playbackFrameRate(int frameRate) {
    if (frameRate > 0) {
      _playbackFrameRate = frameRate;
      // Update settings
      _settings = _settings.copyWith(frameRate: frameRate);
    }
  }

  /// Get playback frame rate
  int get playbackFrameRate => _playbackFrameRate;

  /// Get frames to render for onion skinning
  List<MapEntry<AnimationFrame, double>> getOnionSkinFrames() {
    if (!_settings.onionSkinning) {
      return [];
    }

    final result = <MapEntry<AnimationFrame, double>>[];

    // Add previous frames
    for (int i = 1; i <= _settings.onionSkinningBefore; i++) {
      final frameIndex = _currentFrameIndex - i;
      if (frameIndex >= 0) {
        // Opacity decreases with distance from current frame
        final opacity = _settings.onionSkinningOpacity *
            (1 - (i - 1) / _settings.onionSkinningBefore);
        result.add(MapEntry(_frames[frameIndex], opacity));
      }
    }

    // Add future frames
    for (int i = 1; i <= _settings.onionSkinningAfter; i++) {
      final frameIndex = _currentFrameIndex + i;
      if (frameIndex < _frames.length) {
        // Opacity decreases with distance from current frame
        final opacity = _settings.onionSkinningOpacity *
            (1 - (i - 1) / _settings.onionSkinningAfter);
        result.add(MapEntry(_frames[frameIndex], opacity));
      }
    }

    return result;
  }

  /// Render a frame to an image
  Future<ui.Image> renderFrame(AnimationFrame frame, Size size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw a white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw each visible layer in order
    for (final layer in frame.layers) {
      if (layer.visible && layer.image != null) {
        final paint = Paint()
          ..colorFilter = ColorFilter.mode(
            Colors.white.withOpacity(layer.opacity),
            mapBlendMode(layer.blendMode),
          );

        canvas.drawImage(layer.image!, Offset.zero, paint);
      }
    }

    // Convert to an image
    final picture = recorder.endRecording();
    return await picture.toImage(size.width.toInt(), size.height.toInt());
  }

  /// Render all frames for export
  Future<List<ui.Image>> renderAllFrames(Size size) async {
    final List<ui.Image> result = [];

    for (final frame in _frames) {
      final image = await renderFrame(frame, size);
      result.add(image);
    }

    return result;
  }
}
