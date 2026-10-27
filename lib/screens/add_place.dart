import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/place.dart';
import '../providers/user_places.dart';
import '../widgets/image_input.dart';
import '../widgets/location_input.dart';

/// The form that creates a place: title, photo and location. Nothing is saved
/// until every field passes validation.
class AddPlaceScreen extends ConsumerStatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  ConsumerState<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends ConsumerState<AddPlaceScreen> {
  // The key gives access to the Form's state: validate(), save(), reset().
  final _formKey = GlobalKey<FormState>();

  String _enteredTitle = '';
  File? _selectedImage;
  PlaceLocation? _selectedLocation;
  bool _isSaving = false;

  Future<void> _savePlace() async {
    // validate() runs every validator and shows the error messages.
    if (!_formKey.currentState!.validate()) return;
    // save() calls each field's onSaved, which copies the values into variables.
    _formKey.currentState!.save();

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(userPlacesProvider.notifier)
          .addPlace(_enteredTitle, _selectedImage!, _selectedLocation!);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save the place. Try again.')),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text('"${_enteredTitle.trim()}" added to your places')),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add new Place')),
      body: Form(
        key: _formKey,
        // Each field validates itself once the user has touched it (see
        // autovalidateMode on the fields). A Form-level mode would instead
        // flag every empty field as soon as one of them changes.
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Text(
              'Title',
              style: text.titleMedium,
            ),
            const SizedBox(height: 10),
            TextFormField(
              maxLength: 40,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Where is it?',
                prefixIcon: Icon(Icons.edit_location_alt_outlined),
              ),
              validator: (value) {
                final title = value?.trim() ?? '';
                if (title.isEmpty) return 'Please enter a title.';
                if (title.length < 2) return 'The title must have at least 2 characters.';
                return null;
              },
              onSaved: (value) => _enteredTitle = value!.trim(),
            ),
            const SizedBox(height: 12),
            Text('Photo', style: text.titleMedium),
            const SizedBox(height: 10),
            FormField<File>(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (_) =>
                  _selectedImage == null ? 'Please take or choose a picture.' : null,
              builder: (field) => ImageInput(
                errorText: field.errorText,
                onPickImage: (image) {
                  _selectedImage = image;
                  field.didChange(image);
                },
              ),
            ),
            const SizedBox(height: 24),
            Text('Location', style: text.titleMedium),
            const SizedBox(height: 10),
            FormField<PlaceLocation>(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (_) =>
                  _selectedLocation == null ? 'Please choose a location.' : null,
              builder: (field) => LocationInput(
                errorText: field.errorText,
                onSelectLocation: (location) {
                  _selectedLocation = location;
                  field.didChange(location);
                },
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isSaving ? null : _savePlace,
              icon: _isSaving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    )
                  : const Icon(Icons.add_rounded),
              label: const Text('Add Place'),
            ),
          ].animate(interval: 60.ms).fadeIn(duration: 350.ms).slideY(
                begin: 0.05,
                end: 0,
                curve: Curves.easeOutCubic,
              ),
        ),
      ),
    );
  }
}
