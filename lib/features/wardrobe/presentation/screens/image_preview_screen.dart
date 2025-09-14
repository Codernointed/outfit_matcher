import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: Import AddItemScreen or the relevant next screen
import 'package:outfit_matcher/features/wardrobe/presentation/screens/add_item_screen.dart';
import 'package:outfit_matcher/core/utils/gemini_api_service.dart';

class ImagePreviewScreen extends ConsumerWidget {
  final String imagePath;
  const ImagePreviewScreen({super.key, required this.imagePath});

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
                  builder: (context) => ProcessingScreen(imagePath: imagePath),
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

class ProcessingScreen extends StatefulWidget {
  final String imagePath;
  const ProcessingScreen({super.key, required this.imagePath});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  double _progress = 0.0;
  String _statusMessage = 'Initializing...';
  final List<String> _stages = [
    'Analyzing colors...',
    'Identifying patterns...',
    'Detecting item type...',
    'Almost there...',
    'Done!',
  ];

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    try {
      for (int i = 0; i < _stages.length; i++) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        setState(() {
          _progress = (i + 1) / _stages.length;
          _statusMessage = _stages[i];
        });
      }

      if (!mounted) return;
      
      // Use Gemini API for real analysis
      Map<String, String>? gemini;
      try {
        gemini = await GeminiApiService.analyzeClothingItem(File(widget.imagePath));
      } catch (e) {
        print('Gemini API error: $e');
        gemini = null;
      }
      
      if (!mounted) return;
      
      if (gemini != null && 
          gemini['itemType'] != null && 
          gemini['itemType']!.isNotEmpty &&
          gemini['primaryColor'] != null && 
          gemini['primaryColor']!.isNotEmpty &&
          gemini['patternType'] != null && 
          gemini['patternType']!.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AddItemScreen(
              imagePath: widget.imagePath,
              aiResults: gemini,
            ),
          ),
        );
      } else {
        // Fallback: Navigate to AddItemScreen without AI results
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => AddItemScreen(
              imagePath: widget.imagePath,
              aiResults: null, // Let user fill manually
            ),
          ),
        );
      }
    } catch (e) {
      print('Processing error: $e');
      if (!mounted) return;
      
      // Show error and navigate back
      setState(() {
        _statusMessage = 'Error processing image. Continuing without AI analysis.';
      });
      
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      
      // Navigate to AddItemScreen without AI results as fallback
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AddItemScreen(
            imagePath: widget.imagePath,
            aiResults: null,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Analyzing Your Item',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              CircularProgressIndicator(value: _progress, strokeWidth: 6),
              const SizedBox(height: 20),
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 40),
              Icon(
                Icons.auto_fix_high,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
