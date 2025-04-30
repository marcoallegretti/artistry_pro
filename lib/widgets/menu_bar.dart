import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../widgets/new_document_dialog.dart';
import '../dialogs/export_dialog.dart';

/// Menu bar for the top of the screen
class MenuBar extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetView;

  const MenuBar({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetView,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // File menu
          _buildMenuButton(
            context: context,
            label: 'File',
            items: [
              PopupMenuItem(
                child: const Text('New...'),
                onTap: () {
                  // Show new document dialog
                  _showNewDocumentDialog(context);
                },
              ),
              PopupMenuItem(
                child: const Text('Open...'),
                onTap: () {
                  // Open file functionality
                },
              ),
              PopupMenuItem(
                child: const Text('Save'),
                onTap: () {
                  appState.saveCurrentDocument();
                },
              ),
              PopupMenuItem(
                child: const Text('Save As...'),
                onTap: () {
                  // Save as dialog
                },
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const Text('Export...'),
                onTap: () {
                  // Use a future to avoid problems with onTap
                  Future.delayed(Duration.zero, () {
                    _showExportDialog(context);
                  });
                },
              ),
            ],
          ),

          // Edit menu
          _buildMenuButton(
            context: context,
            label: 'Edit',
            items: [
              PopupMenuItem(
                onTap: () {
                  if (appState.canvasEngine.canUndo) {
                    appState.canvasEngine.undo();
                  }
                },
                enabled: appState.canvasEngine.canUndo,
                child: const Row(
                  children: [
                    Text('Undo'),
                    Spacer(),
                    Text('Ctrl+Z',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () {
                  if (appState.canvasEngine.canRedo) {
                    appState.canvasEngine.redo();
                  }
                },
                enabled: appState.canvasEngine.canRedo,
                child: const Row(
                  children: [
                    Text('Redo'),
                    Spacer(),
                    Text('Ctrl+Shift+Z',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false,
                child: Text('Cut'),
              ),
              const PopupMenuItem(
                enabled: false,
                child: Text('Copy'),
              ),
              const PopupMenuItem(
                enabled: false,
                child: Text('Paste'),
              ),
            ],
          ),

          // View menu
          _buildMenuButton(
            context: context,
            label: 'View',
            items: [
              PopupMenuItem(
                onTap: onZoomIn,
                child: const Text('Zoom In'),
              ),
              PopupMenuItem(
                onTap: onZoomOut,
                child: const Text('Zoom Out'),
              ),
              PopupMenuItem(
                onTap: onResetView,
                child: const Text('Reset View'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: Text(
                    appState.preferences.darkMode ? 'Light Mode' : 'Dark Mode'),
                onTap: () {
                  appState.toggleDarkMode();
                },
              ),
              CheckedPopupMenuItem(
                checked: appState.preferences.showGrid,
                child: const Text('Show Grid'),
                onTap: () {
                  // Toggle grid
                },
              ),
            ],
          ),

          // Layer menu
          _buildMenuButton(
            context: context,
            label: 'Layer',
            items: [
              PopupMenuItem(
                child: const Text('New Layer'),
                onTap: () {
                  appState.addNewLayer();
                },
              ),
              PopupMenuItem(
                onTap: () {
                  appState.deleteCurrentLayer();
                },
                enabled: appState.currentDocument?.layers.length != null &&
                    appState.currentDocument!.layers.length > 1,
                child: const Text('Delete Layer'),
              ),
              PopupMenuItem(
                child: const Text('Duplicate Layer'),
                onTap: () {
                  // Duplicate layer functionality
                },
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                onTap: () {
                  // Merge down functionality
                },
                enabled: false,
                child: const Text('Merge Down'),
              ),
              PopupMenuItem(
                onTap: () {
                  // Merge visible functionality
                },
                enabled: false,
                child: const Text('Merge Visible'),
              ),
            ],
          ),

          // Animation menu (only visible in animation mode)
          if (appState.isAnimationMode)
            _buildMenuButton(
              context: context,
              label: 'Animation',
              items: [
                PopupMenuItem(
                  child: const Text('Add Frame'),
                  onTap: () {
                    appState.addNewFrame();
                  },
                ),
                PopupMenuItem(
                  onTap: () {
                    // Delete frame functionality
                  },
                  enabled: appState.animationService.frames.length > 1,
                  child: const Text('Delete Frame'),
                ),
                PopupMenuItem(
                  child: const Text('Duplicate Frame'),
                  onTap: () {
                    // Duplicate frame functionality
                  },
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  child: const Text('Animation Settings'),
                  onTap: () {
                    // Animation settings dialog
                  },
                ),
              ],
            ),

          const Spacer(),

          // Quick access tools
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: onZoomIn,
            tooltip: 'Zoom In',
            color: Theme.of(context).colorScheme.primary,
          ),

          // Current zoom level
          Text(
            '${(appState.zoomLevel * 100).toInt()}%',
            style: const TextStyle(fontSize: 14),
          ),

          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: onZoomOut,
            tooltip: 'Zoom Out',
            color: Theme.of(context).colorScheme.primary,
          ),

          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: onResetView,
            tooltip: 'Fit to Screen',
            color: Theme.of(context).colorScheme.primary,
          ),

          // Dark mode toggle
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
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required String label,
    required List<PopupMenuEntry> items,
  }) {
    return PopupMenuButton(
      itemBuilder: (context) => items,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _showNewDocumentDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => NewDocumentDialog(
        onCreateDocument: (name, size, resolution, colorMode) {
          appState.createNewDocument(
            name: name,
            size: size,
            resolution: resolution,
            colorMode: colorMode,
          );
        },
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        isAnimation: appState.isAnimationMode,
        onExport: (name, params) {
          appState.exportCurrentDocument(
            params['format'],
            jpegQuality: params['jpegQuality'] ?? 90,
            fileName: name,
          );
        },
      ),
    );
  }
}
