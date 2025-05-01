import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' hide Layer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/project.dart';
import '../models/layer.dart';
import '../models/canvas_settings.dart';
import '../screens/pro_canvas.dart';

/// Service responsible for managing project persistence
class ProjectService extends ChangeNotifier {
  List<Project> _projects = [];
  Project? _currentProject;
  
  /// Get all available projects
  List<Project> get projects => List.unmodifiable(_projects);
  
  /// Get the currently loaded project (if any)
  Project? get currentProject => _currentProject;
  
  /// Initialize the service and load saved projects
  Future<void> initialize() async {
    await _loadProjects();
    notifyListeners();
  }
  
  /// Create a new project
  Future<Project> createProject({
    required String title,
    required CanvasSettings canvasSettings,
  }) async {
    final project = Project.createNew(
      title: title,
      canvasSettings: canvasSettings,
    );
    
    _projects.add(project);
    _currentProject = project;
    
    // Save the full project data immediately
    await _saveProjectData(project);
    await _saveProjectsList();
    
    debugPrint('Created new project with ID: ${project.id}');
    notifyListeners();
    return project;
  }
  
  /// Load a project and set it as current
  Future<Project> loadProject(String projectId) async {
    debugPrint('Attempting to load project with ID: $projectId');
    
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) {
      debugPrint('Project not found in projects list');
      throw Exception('Project not found in projects list');
    }
    
    final project = _projects[projectIndex];
    debugPrint('Found project in list: ${project.title}');
    
    try {
      // Check if project data exists
      final prefs = await _getPrefs();
      final projectDataKey = 'project_${project.id}';
      final hasProjectData = prefs.containsKey(projectDataKey);
      
      debugPrint('Project data exists in SharedPreferences: $hasProjectData');
      
      if (!hasProjectData) {
        // If no full data exists yet, save the basic data first
        debugPrint('No full project data found, saving basic project data');
        await _saveProjectData(project);
      }
      
      // Load full project data from storage
      final fullProject = await _loadProjectData(project.id);
      _currentProject = fullProject;
      notifyListeners();
      return fullProject;
    } catch (e) {
      debugPrint('Error loading project: $e');
      // If we can't load the full data, create a new project with the same ID
      final newProject = Project.createNew(
        title: project.title,
      ).copyWith(
        id: project.id,
        createdAt: project.createdAt,
        lastModifiedAt: DateTime.now(),
      );
      
      // Save this new project
      _currentProject = newProject;
      await _saveProjectData(newProject);
      notifyListeners();
      
      return newProject;
    }
  }
  
  /// Save the current project
  Future<void> saveCurrentProject({
    required List<Layer> layers,
    required int currentLayerIndex,
    required CanvasSettings canvasSettings,
    required BuildContext context,
    GlobalKey? canvasKey,
  }) async {
    if (_currentProject == null) {
      throw Exception('No project is currently active');
    }
    
    // Generate a thumbnail if canvasKey is provided
    String? thumbnailPath;
    if (canvasKey != null) {
      debugPrint('Generating thumbnail for project ${_currentProject!.id}');
      thumbnailPath = await _generateAndSaveThumbnail(canvasKey, _currentProject!.id);
    } else {
      thumbnailPath = _currentProject!.thumbnailPath;
    }
    
    // Deep copy the layers to ensure we capture all drawing data
    final layersCopy = <Layer>[];
    for (final layer in layers) {
      if (layer.contentType == ContentType.drawing) {
        final points = layer.payload as List;
        debugPrint('Layer ${layer.name} has ${points.length} points');
      }
      layersCopy.add(layer.copyWith());
    }
    
    // Update the current project with new data
    _currentProject = _currentProject!.copyWith(
      layers: layersCopy,
      currentLayerIndex: currentLayerIndex,
      canvasSettings: canvasSettings,
      lastModifiedAt: DateTime.now(),
      thumbnailPath: thumbnailPath,
    );
    
    // Update project in the list
    final projectIndex = _projects.indexWhere((p) => p.id == _currentProject!.id);
    if (projectIndex >= 0) {
      _projects[projectIndex] = _currentProject!;
    }
    
    // Save project data
    await _saveProjectData(_currentProject!);
    await _saveProjectsList();
    notifyListeners();
  }
  
  /// Delete a project
  Future<void> deleteProject(String projectId) async {
    // Check if deleting the current project
    if (_currentProject?.id == projectId) {
      _currentProject = null;
    }
    
    // Remove from projects list
    _projects.removeWhere((p) => p.id == projectId);
    
    // Delete project data from SharedPreferences
    final prefs = await _getPrefs();
    await prefs.remove('project_$projectId');
    
    await _saveProjectsList();
    notifyListeners();
  }
  
  /// Rename a project
  Future<void> renameProject(String projectId, String newTitle) async {
    final projectIndex = _projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) {
      throw Exception('Project not found');
    }
    
    // Update the project title
    _projects[projectIndex] = _projects[projectIndex].copyWith(
      title: newTitle,
      lastModifiedAt: DateTime.now(),
    );
    
    // Update current project if it's the same project
    if (_currentProject?.id == projectId) {
      _currentProject = _currentProject!.copyWith(
        title: newTitle,
        lastModifiedAt: DateTime.now(),
      );
    }
    
    await _saveProjectsList();
    await _saveProjectData(_projects[projectIndex]);
    notifyListeners();
  }
  
  /// Load the list of projects from SharedPreferences
  Future<void> _loadProjects() async {
    try {
      final prefs = await _getPrefs();
      final projectsListJson = prefs.getString('projects_list');
      
      if (projectsListJson != null) {
        final List<dynamic> projectsList = jsonDecode(projectsListJson);
        
        _projects = projectsList.map((json) {
          return Project(
            id: json['id'],
            title: json['title'],
            createdAt: DateTime.parse(json['createdAt']),
            lastModifiedAt: DateTime.parse(json['lastModifiedAt']),
            canvasSettings: CanvasSettings.defaultSettings, // Just placeholder for list
            layers: [], // Empty for list view
            currentLayerIndex: 0,
            thumbnailPath: json['thumbnailPath'],
          );
        }).toList();
        
        // Sort by last modified (newest first)
        _projects.sort((a, b) => b.lastModifiedAt.compareTo(a.lastModifiedAt));
      }
    } catch (e) {
      debugPrint('Error loading projects: $e');
      _projects = [];
    }
  }
  
  /// Save the projects list to SharedPreferences
  Future<void> _saveProjectsList() async {
    try {
      final prefs = await _getPrefs();
      
      final List<Map<String, dynamic>> projectsData = _projects.map((project) {
        return {
          'id': project.id,
          'title': project.title,
          'createdAt': project.createdAt.toIso8601String(),
          'lastModifiedAt': project.lastModifiedAt.toIso8601String(),
          'thumbnailPath': project.thumbnailPath,
        };
      }).toList();
      
      await prefs.setString('projects_list', jsonEncode(projectsData));
    } catch (e) {
      debugPrint('Error saving projects list: $e');
    }
  }
  
  /// Save a project's full data to SharedPreferences
  Future<void> _saveProjectData(Project project) async {
    try {
      debugPrint('Saving project data for ID: ${project.id}');
      final prefs = await _getPrefs();
      
      // Transform layers data to be serializable
      final List<Map<String, dynamic>> layersData = project.layers.map((layer) {
        // Handle payload based on content type
        dynamic serializedPayload;
        
        if (layer.contentType == ContentType.drawing) {
          // For drawing layers, convert DrawingPoints to serializable format
          final points = layer.payload as List<dynamic>;
          
          debugPrint('Serializing layer ${layer.name} with ${points.length} points');
          
          final serializedPoints = <dynamic>[];
          for (var i = 0; i < points.length; i++) {
            final point = points[i];
            if (point == null) {
              serializedPoints.add(null);
            } else if (point is DrawingPoint) {
              serializedPoints.add({
                'x': point.point.dx,
                'y': point.point.dy,
                'color': point.paint.color.value,
                'strokeWidth': point.paint.strokeWidth,
                'strokeCap': point.paint.strokeCap.index,
                'blendMode': point.paint.blendMode.index,
                'isEraser': point.isEraser,
              });
            }
          }
          
          serializedPayload = serializedPoints;
        } else if (layer.contentType == ContentType.image) {
          // For image layers, we can't directly serialize the image
          // Store a reference or encode base64 if needed
          // This is placeholder - actual implementation would depend on how images are handled
          serializedPayload = null;
        }
        
        return {
          'id': layer.id,
          'name': layer.name,
          'visible': layer.visible,
          'opacity': layer.opacity,
          'blendMode': layer.blendMode.index,
          'locked': layer.locked,
          'contentType': layer.contentType.index,
          'payload': serializedPayload,
        };
      }).toList();
      
      // Create serializable project data
      final Map<String, dynamic> projectData = {
        'id': project.id,
        'title': project.title,
        'createdAt': project.createdAt.toIso8601String(),
        'lastModifiedAt': project.lastModifiedAt.toIso8601String(),
        'canvasSettings': {
          'width': project.canvasSettings.size.width,
          'height': project.canvasSettings.size.height,
          'backgroundColor': project.canvasSettings.backgroundColor.value,
          'isTransparent': project.canvasSettings.isTransparent,
          'checkerPatternOpacity': project.canvasSettings.checkerPatternOpacity,
          'checkerSquareSize': project.canvasSettings.checkerSquareSize,
        },
        'layers': layersData,
        'currentLayerIndex': project.currentLayerIndex,
      };
      
      final projectKey = 'project_${project.id}';
      final projectJson = jsonEncode(projectData);
      final success = await prefs.setString(projectKey, projectJson);
      
      debugPrint('Project data saved successfully: $success (key: $projectKey)');
      debugPrint('Project data size: ${projectJson.length} characters');
    } catch (e) {
      debugPrint('Error saving project data: $e');
    }
  }
  
  /// Load a project's full data from SharedPreferences
  Future<Project> _loadProjectData(String projectId) async {
    try {
      final prefs = await _getPrefs();
      final projectJson = prefs.getString('project_$projectId');
      
      if (projectJson != null) {
        final json = jsonDecode(projectJson);
        
        // Parse canvas settings
        final canvasSettingsJson = json['canvasSettings'];
        final canvasSettings = CanvasSettings(
          size: Size(
            canvasSettingsJson['width'].toDouble(),
            canvasSettingsJson['height'].toDouble(),
          ),
          backgroundColor: Color(canvasSettingsJson['backgroundColor']),
          isTransparent: canvasSettingsJson['isTransparent'],
          checkerPatternOpacity: canvasSettingsJson['checkerPatternOpacity'],
          checkerSquareSize: canvasSettingsJson['checkerSquareSize'],
        );
        
        // Parse layers
        final layersJson = json['layers'] as List<dynamic>;
        final layers = layersJson.map<Layer>((layerJson) {
          // Parse content type
          final contentType = ContentType.values[layerJson['contentType']];
          
          // Parse payload based on content type
          dynamic payload;
          
          if (contentType == ContentType.drawing) {
            final pointsJson = layerJson['payload'] as List<dynamic>?;
            debugPrint('Deserializing layer points, found ${pointsJson?.length ?? 0} points');
            
            if (pointsJson != null && pointsJson.isNotEmpty) {
              final List<DrawingPoint?> deserializedPoints = [];
              
              for (var i = 0; i < pointsJson.length; i++) {
                final pointJson = pointsJson[i];
                if (pointJson == null) {
                  deserializedPoints.add(null);
                } else {
                  try {
                    final Paint paint = Paint()
                      ..color = Color(pointJson['color'])
                      ..strokeWidth = pointJson['strokeWidth'].toDouble()
                      ..strokeCap = StrokeCap.values[pointJson['strokeCap']]
                      ..blendMode = BlendMode.values[pointJson['blendMode']];
                    
                    deserializedPoints.add(DrawingPoint(
                      Offset(pointJson['x'].toDouble(), pointJson['y'].toDouble()),
                      paint,
                      isEraser: pointJson['isEraser'] ?? false,
                    ));
                  } catch (e) {
                    debugPrint('Error deserializing point $i: $e');
                    deserializedPoints.add(null);
                  }
                }
              }
              
              payload = deserializedPoints;
              debugPrint('Successfully deserialized ${deserializedPoints.length} drawing points');
            } else {
              payload = <DrawingPoint?>[];
              debugPrint('No points to deserialize, created empty list');
            }
          }
          
          return Layer(
            id: layerJson['id'],
            name: layerJson['name'],
            visible: layerJson['visible'],
            opacity: layerJson['opacity'],
            blendMode: BlendMode.values[layerJson['blendMode']],
            locked: layerJson['locked'],
            contentType: contentType,
            payload: payload,
          );
        }).toList();
        
        return Project(
          id: json['id'],
          title: json['title'],
          createdAt: DateTime.parse(json['createdAt']),
          lastModifiedAt: DateTime.parse(json['lastModifiedAt']),
          canvasSettings: canvasSettings,
          layers: layers,
          currentLayerIndex: json['currentLayerIndex'],
          thumbnailPath: json['thumbnailPath'],
        );
      } else {
        throw Exception('Project data not found');
      }
    } catch (e) {
      debugPrint('Error loading project data: $e');
      rethrow;
    }
  }
  
  /// Generate a thumbnail for the project and save it as base64 string in project data
  Future<String?> _generateAndSaveThumbnail(GlobalKey canvasKey, String projectId) async {
    try {
      final boundary = canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      final image = await boundary.toImage(pixelRatio: 0.3); // Very small thumbnail for storage
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) return null;
      
      // Store the thumbnail ID - we'll store the actual data in the project
      final thumbnailId = 'thumbnail_$projectId';
      
      // Convert to base64 and store in SharedPreferences
      final bytes = byteData.buffer.asUint8List();
      final base64Thumbnail = base64Encode(bytes);
      
      final prefs = await _getPrefs();
      await prefs.setString(thumbnailId, base64Thumbnail);
      
      return thumbnailId;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }
  
  /// Gets the SharedPreferences instance for storage
  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }
}
