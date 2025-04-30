import 'package:flutter/material.dart';
import '../services/history_manager.dart';

/// Panel that displays action history with undo/redo capabilities
class HistoryPanel extends StatelessWidget {
  final HistoryManager historyManager;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final Function(int) onJumpToState;

  const HistoryPanel({
    super.key,
    required this.historyManager,
    required this.onUndo,
    required this.onRedo,
    required this.onJumpToState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Undo/Redo buttons
          Row(
            children: [
              Text(
                'History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo',
                onPressed: historyManager.canUndo ? onUndo : null,
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                tooltip: 'Redo',
                onPressed: historyManager.canRedo ? onRedo : null,
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Clear History',
                onPressed: historyManager.history.isNotEmpty
                    ? () => historyManager.clear()
                    : null,
              ),
            ],
          ),

          const Divider(),

          // History list
          Expanded(
            child: historyManager.history.isEmpty
                ? const Center(
                    child: Text(
                      'No history yet',
                      style: TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: historyManager.history.length,
                    itemBuilder: (context, index) {
                      final action = historyManager.history[index];
                      final isCurrentState =
                          index == historyManager.currentIndex;

                      return _buildHistoryItem(
                        context,
                        action,
                        index,
                        isCurrentState,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    HistoryAction action,
    int index,
    bool isCurrentState,
  ) {
    IconData actionIcon;

    // Choose icon based on action type
    switch (action.type) {
      case ActionType.DRAW_STROKE:
        actionIcon = Icons.brush;
        break;
      case ActionType.ERASE:
        actionIcon = Icons.auto_fix_high;
        break;
      case ActionType.ADD_LAYER:
        actionIcon = Icons.add;
        break;
      case ActionType.DELETE_LAYER:
        actionIcon = Icons.delete;
        break;
      case ActionType.MERGE_LAYERS:
        actionIcon = Icons.merge_type;
        break;
      case ActionType.REORDER_LAYERS:
        actionIcon = Icons.reorder;
        break;
      case ActionType.MODIFY_LAYER_PROPERTIES:
        actionIcon = Icons.tune;
        break;
      case ActionType.APPLY_FILTER:
        actionIcon = Icons.filter;
        break;
      case ActionType.TRANSFORM:
        actionIcon = Icons.transform;
        break;
      case ActionType.CROP:
        actionIcon = Icons.crop;
        break;
      case ActionType.TEXT_EDIT:
        actionIcon = Icons.text_fields;
        break;
      case ActionType.FILL:
        actionIcon = Icons.format_color_fill;
        break;
      case ActionType.SELECTION:
        actionIcon = Icons.select_all;
        break;
      case ActionType.PASTE:
        actionIcon = Icons.content_paste;
        break;
      case ActionType.IMPORT_IMAGE:
        actionIcon = Icons.image;
        break;
      case ActionType.ADJUSTMENT:
        actionIcon = Icons.tune;
        break;
    }

    // Format the timestamp
    final time = action.timestamp;
    final timeString =
        '${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';

    return Material(
      color: isCurrentState
          ? Theme.of(context).colorScheme.primaryContainer
          : index > historyManager.currentIndex
              ? Colors.grey.withOpacity(0.2) // Future states (can be redone)
              : Colors.transparent, // Past states (can be undone)
      child: InkWell(
        onTap: () => onJumpToState(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Row(
            children: [
              Icon(
                actionIcon,
                size: 18,
                color: isCurrentState
                    ? Theme.of(context).colorScheme.primary
                    : index > historyManager.currentIndex
                        ? Colors.grey // Future states (can be redone)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface, // Past states (can be undone)
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action.name,
                      style: TextStyle(
                        fontWeight: isCurrentState
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrentState
                            ? Theme.of(context).colorScheme.primary
                            : index > historyManager.currentIndex
                                ? Colors.grey // Future states (can be redone)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface, // Past states (can be undone)
                      ),
                    ),
                    Text(
                      timeString,
                      style: TextStyle(
                        fontSize: 10,
                        color: isCurrentState
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.7)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrentState)
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
