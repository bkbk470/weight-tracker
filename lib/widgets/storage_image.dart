import 'package:flutter/material.dart';
import 'package:weight_tracker/services/supabase_service.dart';

/// Widget that displays images from Supabase storage or regular URLs
/// Automatically handles storage paths (e.g., "Exercises/default_exercise.gif")
/// and converts them to signed URLs
class StorageImage extends StatefulWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const StorageImage({
    super.key,
    required this.imageUrl,
    this.width = 56,
    this.height = 56,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<StorageImage> createState() => _StorageImageState();
}

class _StorageImageState extends State<StorageImage> {
  String? _resolvedUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _resolveImageUrl();
  }

  @override
  void didUpdateWidget(StorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resolveImageUrl();
    }
  }

  Future<void> _resolveImageUrl() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final imageUrl = widget.imageUrl!;

      // Check if it's already a full URL (starts with http:// or https://)
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        setState(() {
          _resolvedUrl = imageUrl;
          _isLoading = false;
        });
        return;
      }

      // Otherwise, treat it as a storage path and get signed URL
      final signedUrl = await SupabaseService.instance.getSignedUrlForStoragePath(imageUrl);

      if (!mounted) return;

      setState(() {
        _resolvedUrl = signedUrl;
        _isLoading = false;
      });
    } catch (e) {
      print('Error resolving image URL: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Error state
    if (_hasError) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: colorScheme.surfaceVariant,
            child: Icon(
              Icons.fitness_center,
              color: colorScheme.primary,
            ),
          );
    }

    // Loading state
    if (_isLoading || _resolvedUrl == null) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: colorScheme.surfaceVariant,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
            ),
          );
    }

    // Display image
    return Image.network(
      _resolvedUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ??
            Container(
              width: widget.width,
              height: widget.height,
              color: colorScheme.surfaceVariant,
              child: Icon(
                Icons.fitness_center,
                color: colorScheme.primary,
              ),
            );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: widget.width,
          height: widget.height,
          color: colorScheme.surfaceVariant,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
