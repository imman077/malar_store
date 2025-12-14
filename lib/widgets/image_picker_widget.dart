import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? initialBase64;
  final Function(String?) onImageSelected;
  final String uploadText;

  const ImagePickerWidget({
    super.key,
    this.initialBase64,
    required this.onImageSelected,
    required this.uploadText,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  String? _imageBase64;
  Uint8List? _cachedImageBytes; // Cache decoded image
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _imageBase64 = widget.initialBase64;
    _updateCachedImage();
  }

  @override
  void didUpdateWidget(ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if the base64 actually changed
    if (widget.initialBase64 != oldWidget.initialBase64) {
      _imageBase64 = widget.initialBase64;
      _updateCachedImage();
    }
  }

  void _updateCachedImage() {
    if (_imageBase64 != null) {
      _cachedImageBytes = Helpers.decodeBase64ToImage(_imageBase64);
    } else {
      _cachedImageBytes = null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = Helpers.encodeImageToBase64(bytes);
        setState(() {
          _imageBase64 = base64String;
          _cachedImageBytes = bytes; // Use the bytes directly
        });
        widget.onImageSelected(base64String);
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImageDialog(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            // Full screen image with pinch to zoom
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Change image button
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showImageSourceDialog();
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Change Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use cached bytes instead of decoding every time
    return GestureDetector(
      onTap: _cachedImageBytes != null ? () => _showFullImageDialog(_cachedImageBytes!) : _showImageSourceDialog,
      onLongPress: _showImageSourceDialog,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray.withOpacity(0.3)),
        ),
        child: _cachedImageBytes != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 200,
                      child: Image.memory(
                        _cachedImageBytes!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true, // Prevents flicker
                      ),
                    ),
                  ),
                  // Hint overlay
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Tap to view',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: AppColors.gray,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.uploadText,
                    style: TextStyle(
                      color: AppColors.gray,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
