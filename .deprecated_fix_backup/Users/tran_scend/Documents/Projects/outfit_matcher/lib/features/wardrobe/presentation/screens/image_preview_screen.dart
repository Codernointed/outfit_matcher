import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/visual_search_screen.dart';
import 'package:vestiq/core/utils/gemini_api_service_new.dart';

class ImagePreviewScreen extends ConsumerWidget {
  final String imagePath;
  final bool fromCamera;
  
  const ImagePreviewScreen({
    super.key, 
    required this.imagePath,
    this.fromCamera = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview & Adjust'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          tooltip: 'Retake / Choose Different',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Continue',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ProcessingScreen(
                    imagePath: imagePath,
                    fromCamera: fromCamera,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: InteractiveViewer(
                  child: Image.file(File(imagePath), fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            color:
                Theme.of(context).bottomAppBarTheme.color ??
                Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEditOption(context, Icons.crop, 'Crop', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Crop feature coming soon!')),
                  );
                }),
                _buildEditOption(
                  context,
                  Icons.rotate_90_degrees_ccw,
                  'Rotate',
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rotate feature coming soon!'),
                      ),
                    );
                  },
                ),
                _buildEditOption(
                  context,
                  Icons.brightness_6_outlined,
                  'Adjust',
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Adjust brightness feature coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class ProcessingScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final bool fromCamera;
  
  const ProcessingScreen({
    super.key, 
    required this.imagePath,
    this.fromCamera = false,
  });

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _progress = 0.0;
  String _statusMessage = 'Initializing...';
  final List<Map<String, dynamic>> _stages = [
    {'message': 'Analyzing colors...', 'icon': Icons.color_lens},
    {'message': 'Identifying patterns...', 'icon': Icons.pattern},
    {'message': 'Detecting item type...', 'icon': Icons.category},
    {'message': 'Finding matching styles...', 'icon': Icons.style},
    {'message': 'Preparing recommendations...', 'icon': Icons.auto_awesome},
    {'message': 'Done!', 'icon': Icons.check_circle},
  ];
  
  // Analysis results
  Map<String, dynamic>? _analysisResults;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    // Start processing after a short delay to allow animation to begin
    Future.delayed(const Duration(milliseconds: 300), _startProcessing);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startProcessing() async {
    try {
      // Simulate processing stages with progress
      for (int i = 0; i < _stages.length; i++) {
        if (i == _stages.length - 1) {
          // Last stage - perform actual analysis
          try {
            final result = await GeminiApiService.analyzeClothingItem(File(widget.imagePath));
            if (result != null) {
              _analysisResults = result;
              debugPrint('Analysis results: $_analysisResults');
            }
          } catch (e) {
            debugPrint('Error analyzing image: $e');
            if (!mounted) return;
            _showError('Failed to analyze image. Please try again.');
            return;
          }
        }
        
        if (!mounted) return;
        
        // Update UI for current stage
        setState(() {
          _progress = (i + 1) / _stages.length;
          _statusMessage = _stages[i]['message'] as String;
        });
        
        // Add variable delay based on stage
        final delay = i < _stages.length - 1 
            ? Duration(milliseconds: 500 + (i * 200))
            : Duration.zero;
            
        await Future.delayed(delay);
      }

      if (!mounted) return;
      
      // Navigate to results
      if (_analysisResults != null) {
        _navigateToResults();
      } else {
        _showError('Could not analyze the image. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('An error occurred while processing your image.');
    }
  }

  void _navigateToResults() {
    if (!mounted) return;
    
    // Convert the analysis results to the expected format for VisualSearchScreen
    final analysis = _analysisResults!;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => VisualSearchScreen.withDetails(
          imagePath: widget.imagePath,
          itemType: analysis['itemType'] ?? 'clothing',
          primaryColor: analysis['primaryColor'] ?? 'neutral',
          patternType: analysis['patternType'] ?? 'solid',
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) => Navigator.pop(context));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentStage = _stages.firstWhere(
      (stage) => stage['message'] == _statusMessage,
      orElse: () => _stages.first,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyzing Your Item'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated illustration
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  
                  // Progress indicator
                  CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 4,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                  
                  // Current stage icon
                  Icon(
                    currentStage['icon'] as IconData? ?? Icons.auto_awesome,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Status message
            Text(
              _statusMessage,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Progress percentage
            Text(
              '${(_progress * 100).toInt()}% complete',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Progress bar
            LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
