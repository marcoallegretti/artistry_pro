import 'package:flutter/material.dart';
import '../services/animation_service.dart';

/// Animation timeline panel for the bottom of the screen
class TimelinePanel extends StatelessWidget {
  final AnimationService animationService;
  final VoidCallback onAddFrame;
  final Function(int) onFrameSelected;

  const TimelinePanel({
    super.key,
    required this.animationService,
    required this.onAddFrame,
    required this.onFrameSelected,
  });

  @override
  Widget build(BuildContext context) {
    final frames = animationService.frames;
    final currentFrameIndex = animationService.currentFrameIndex;

    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[850]
          : Colors.grey[200],
      child: Column(
        children: [
          // Timeline toolbar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Timeline',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 16),
                Text(
                  'Frame ${currentFrameIndex + 1} of ${frames.length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                // Animation controls
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 20),
                  onPressed: () {
                    animationService.firstFrame();
                    onFrameSelected(0);
                  },
                  tooltip: 'First Frame',
                  color: Theme.of(context).colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.navigate_before, size: 20),
                  onPressed: currentFrameIndex > 0
                      ? () {
                          animationService.previousFrame();
                          onFrameSelected(animationService.currentFrameIndex);
                        }
                      : null,
                  tooltip: 'Previous Frame',
                  color: Theme.of(context).colorScheme.primary,
                ),
                IconButton(
                  icon: Icon(
                    animationService.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 20,
                  ),
                  onPressed: () {
                    animationService.togglePlayback();
                  },
                  tooltip: animationService.isPlaying ? 'Pause' : 'Play',
                  color: Theme.of(context).colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.navigate_next, size: 20),
                  onPressed: currentFrameIndex < frames.length - 1
                      ? () {
                          animationService.nextFrame();
                          onFrameSelected(animationService.currentFrameIndex);
                        }
                      : null,
                  tooltip: 'Next Frame',
                  color: Theme.of(context).colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 20),
                  onPressed: () {
                    animationService.lastFrame();
                    onFrameSelected(frames.length - 1);
                  },
                  tooltip: 'Last Frame',
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: onAddFrame,
                  tooltip: 'Add Frame',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),

          // Frames list
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: frames.length,
                itemBuilder: (context, index) {
                  final isSelected = index == currentFrameIndex;

                  return GestureDetector(
                    onTap: () => onFrameSelected(index),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          // Frame thumbnail (placeholder)
                          Expanded(
                            child: Container(
                              color: Colors.white,
                              child: Center(
                                child: Icon(
                                  Icons.image,
                                  size: 24,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ),

                          // Frame info
                          Container(
                            height: 24,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surface,
                            child: Center(
                              child: Text(
                                'Frame ${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
