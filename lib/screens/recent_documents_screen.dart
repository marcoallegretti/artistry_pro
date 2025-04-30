import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/painting_models.dart';
import '../services/app_state.dart';
import '../services/file_service.dart';
import '../widgets/document_thumbnail.dart';
import '../widgets/new_document_dialog.dart';
import '../screens/pro_canvas.dart';

class RecentDocumentsScreen extends StatefulWidget {
  const RecentDocumentsScreen({super.key});

  @override
  _RecentDocumentsScreenState createState() => _RecentDocumentsScreenState();
}

class _RecentDocumentsScreenState extends State<RecentDocumentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentDocuments = [];
  final FileService _fileService = FileService();

  @override
  void initState() {
    super.initState();
    _loadRecentDocuments();
  }

  Future<void> _loadRecentDocuments() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final recentFiles = appState.recentFiles;
    final loadedDocuments = <Map<String, dynamic>>[];

    for (final filePath in recentFiles) {
      try {
        final document = await _fileService.loadProject(filePath);
        if (document != null) {
          ui.Image? thumbnail;
          try {
            thumbnail = await _fileService.generateThumbnail(document);
          } catch (e) {
            // Skip thumbnail generation if it fails
            print('Error generating thumbnail: $e');
          }

          loadedDocuments.add({
            'document': document,
            'thumbnail': thumbnail,
            'lastModified':
                DateTime.now(), // In a real app, get this from file metadata
          });
        }
      } catch (e) {
        print('Error loading document: $e');
        // Skip this document if it can't be loaded
      }
    }

    setState(() {
      _recentDocuments = loadedDocuments;
      _isLoading = false;
    });
  }

  void _createNewDocument(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => NewDocumentDialog(
        onCreateDocument: (name, size, resolution, colorMode) {
          final appState = Provider.of<AppState>(context, listen: false);
          appState.createNewDocument(
            name: name,
            size: size,
            resolution: resolution,
            colorMode: colorMode,
          );
          // Close the dialog first
          Navigator.of(dialogContext).pop();
          // Then navigate to the pro canvas screen, replacing the start screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ProCanvasScreen()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ProPaint Studio'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(appState.preferences.darkMode
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () {
              appState.toggleDarkMode();
            },
            tooltip: appState.preferences.darkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to ProPaint Studio',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Professional Digital Painting & Illustration',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _createNewDocument(context),
                        icon: const Icon(Icons.add),
                        label: const Text('New Document'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          // Show open file dialog
                        },
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Open Existing'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                // Recent documents section
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Documents',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (_recentDocuments.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            // Clear recent documents
                          },
                          child: const Text('Clear All'),
                        ),
                    ],
                  ),
                ),

                // Recent documents grid
                Expanded(
                  child: _recentDocuments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_album_outlined,
                                size: 72,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No recent documents',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create a new document to get started',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.5),
                                    ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(24),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                (MediaQuery.of(context).size.width / 280)
                                    .floor()
                                    .clamp(1, 5),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _recentDocuments.length,
                          itemBuilder: (context, index) {
                            final item = _recentDocuments[index];
                            final document = item['document'] as CanvasDocument;
                            final thumbnail = item['thumbnail'] as ui.Image?;
                            final lastModified =
                                item['lastModified'] as DateTime?;

                            return DocumentThumbnail(
                              document: document,
                              thumbnail: thumbnail,
                              lastModified: lastModified,
                              onTap: () {
                                // Load this document
                                appState.loadDocument(document.filePath!);
                                Navigator.of(context)
                                    .pop(); // Go to canvas screen
                              },
                            );
                          },
                        ),
                ),

                // Footer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[850]
                        : Colors.grey[100],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ProPaint Studio v1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              // Open help dialog
                            },
                            icon: const Icon(Icons.help_outline, size: 16),
                            label: const Text('Help'),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              // Open settings dialog
                            },
                            icon: const Icon(Icons.settings_outlined, size: 16),
                            label: const Text('Settings'),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
