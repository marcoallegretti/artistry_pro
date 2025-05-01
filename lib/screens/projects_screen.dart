import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/project_service.dart';
import '../widgets/new_project_dialog.dart';
import 'pro_canvas.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projectService = Provider.of<ProjectService>(context, listen: false);
    await projectService.initialize();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createNewProject() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const NewProjectDialog(),
    );

    if (result != null) {
      final projectService = Provider.of<ProjectService>(context, listen: false);
      final project = await projectService.createProject(
        title: result['title'],
        canvasSettings: result['canvasSettings'],
      );

      if (mounted) {
        // Navigate to ProCanvasScreen with the new project
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProCanvasScreen(projectId: project.id),
          ),
        );
      }
    }
  }

  Future<void> _openProject(Project project) async {
    final projectService = Provider.of<ProjectService>(context, listen: false);
    
    try {
      await projectService.loadProject(project.id);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProCanvasScreen(projectId: project.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening project: $e')),
        );
      }
    }
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final projectService = Provider.of<ProjectService>(context, listen: false);
      await projectService.deleteProject(project.id);
    }
  }

  Future<void> _renameProject(Project project) async {
    final titleController = TextEditingController(text: project.title);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Project'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Project Title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (confirmed == true && titleController.text.isNotEmpty) {
      final projectService = Provider.of<ProjectService>(context, listen: false);
      await projectService.renameProject(project.id, titleController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artistry Pro - Projects'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<ProjectService>(
              builder: (context, projectService, child) {
                final projects = projectService.projects;
                
                if (projects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.palette_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 24),
                        const Text(
                          'No Projects Yet',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Create your first painting project to get started',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _createNewProject,
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Project'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Projects',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            onPressed: _createNewProject,
                            icon: const Icon(Icons.add),
                            label: const Text('New Project'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: projects.length,
                          itemBuilder: (context, index) {
                            final project = projects[index];
                            return _buildProjectCard(project);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProjectCard(Project project) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _openProject(project),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: project.thumbnailPath != null
                ? FutureBuilder<String?>(  
                    future: _getThumbnailData(project.thumbnailPath!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && 
                          snapshot.hasData && 
                          snapshot.data != null) {
                        // Convert base64 to image
                        final imageData = base64Decode(snapshot.data!);
                        return Image.memory(
                          imageData,
                          fit: BoxFit.cover,
                        );
                      } else {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                          ),
                        );
                      }
                    })
                : Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                    ),
                  ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last edited: ${_formatDate(project.lastModifiedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Rename',
                        onPressed: () => _renameProject(project),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        tooltip: 'Delete',
                        onPressed: () => _deleteProject(project),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  /// Get thumbnail data from SharedPreferences
  Future<String?> _getThumbnailData(String thumbnailId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(thumbnailId);
    } catch (e) {
      debugPrint('Error loading thumbnail: $e');
      return null;
    }
  }
}
