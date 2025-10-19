import 'package:flutter/material.dart';
import '../constants/exercise_assets.dart';
import '../services/supabase_service.dart';

/// Simple debug widget to test image loading
class ExerciseImageDebugWidget extends StatefulWidget {
  const ExerciseImageDebugWidget({super.key});

  @override
  State<ExerciseImageDebugWidget> createState() => _ExerciseImageDebugWidgetState();
}

class _ExerciseImageDebugWidgetState extends State<ExerciseImageDebugWidget> {
  String? _signedUrl;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    print('🔍 DEBUG: Starting image load...');
    print('🔍 DEBUG: Image path: $kExercisePlaceholderImage');
    
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Try to get signed URL
      final url = await SupabaseService.instance
          .getSignedUrlForStoragePath(kExercisePlaceholderImage);
      
      print('✅ DEBUG: Got signed URL: $url');
      
      setState(() {
        _signedUrl = url;
        _loading = false;
      });
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error loading image: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
      
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: _loading
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _error != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 24),
                    Text('Error', style: TextStyle(fontSize: 8, color: Colors.red)),
                  ],
                )
              : _signedUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _signedUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            print('✅ DEBUG: Image loaded successfully!');
                            return child;
                          }
                          print('⏳ DEBUG: Loading image... ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ DEBUG: Image.network error: $error');
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.red, size: 24),
                              Text('Failed', style: TextStyle(fontSize: 8)),
                            ],
                          );
                        },
                      ),
                    )
                  : Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}
