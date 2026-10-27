import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/services.dart';

/// The photo part of the "Add place" form: a preview plus two buttons.
///
/// Stateful or stateless? **Stateful**: the widget has to remember the picture
/// that was chosen (and whether the camera is open) and redraw when it changes.
class ImageInput extends ConsumerStatefulWidget {
  const ImageInput({super.key, required this.onPickImage, this.errorText});

  /// Called with the picture every time the user takes or picks one.
  final void Function(File image) onPickImage;

  /// Validation message to show under the preview (from the surrounding form).
  final String? errorText;

  @override
  ConsumerState<ImageInput> createState() => _ImageInputState();
}

class _ImageInputState extends ConsumerState<ImageInput> {
  File? _selectedImage;
  bool _isBusy = false;

  Future<void> _pick(Future<File?> Function() source) async {
    setState(() => _isBusy = true);
    try {
      final image = await source();
      if (image == null || !mounted) return; // the user cancelled
      setState(() => _selectedImage = image);
      widget.onPickImage(image);
    } catch (_) {
      // e.g. camera permission denied or no camera available
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the camera or gallery.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.read(photoServiceProvider);
    final scheme = Theme.of(context).colorScheme;
    final hasError = widget.errorText != null;

    final preview = _selectedImage == null
        ? Column(
            key: const ValueKey('no-image'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_camera_outlined,
                size: 40,
                color: hasError ? scheme.error : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'No image taken',
                style: TextStyle(
                  color: hasError ? scheme.error : scheme.onSurfaceVariant,
                ),
              ),
            ],
          )
        : ClipRRect(
            key: ValueKey(_selectedImage!.path),
            borderRadius: BorderRadius.circular(22),
            child: Image.file(
              _selectedImage!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              cacheWidth: 900,
              errorBuilder: (context, error, stack) =>
                  const Center(child: Icon(Icons.broken_image_outlined)),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 190,
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasError ? scheme.error : scheme.outlineVariant,
              width: hasError ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: preview,
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Text(
              widget.errorText!,
              style: TextStyle(color: scheme.error, fontSize: 12.5),
            ),
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _isBusy ? null : () => _pick(photos.takePicture),
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('Take Picture'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isBusy ? null : () => _pick(photos.pickFromGallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
