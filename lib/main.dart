import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/ui_state.dart';
import 'screens/places_list_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _preloadFonts();
  // ProviderScope is where all Riverpod providers live. It must wrap the app.
  runApp(const ProviderScope(child: FavoritePlacesApp()));
}

/// Google Fonts are downloaded the first time they are used. Waiting for them
/// before the first frame stops text from jumping to another font a moment
/// later, but never longer than a few seconds so the app starts offline too.
Future<void> _preloadFonts() async {
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.plusJakartaSans(),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
      GoogleFonts.sora(fontWeight: FontWeight.w600),
      GoogleFonts.sora(fontWeight: FontWeight.w700),
      GoogleFonts.sora(fontWeight: FontWeight.w800),
    ]).timeout(const Duration(seconds: 4));
  } catch (_) {
    // Offline or slow: carry on with the fallback font.
  }
}

/// Root widget. A ConsumerStatefulWidget can `watch` providers: the app
/// rebuilds when the theme mode changes.
class FavoritePlacesApp extends ConsumerStatefulWidget {
  const FavoritePlacesApp({super.key});

  @override
  ConsumerState<FavoritePlacesApp> createState() => _FavoritePlacesAppState();
}

class _FavoritePlacesAppState extends ConsumerState<FavoritePlacesApp> {
  @override
  void initState() {
    super.initState();
    // Restore the saved light/dark choice. A provider must not be changed
    // while the widget tree is building, so this runs right after.
    Future.microtask(() => ref.read(themeModeProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Favorite Places',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      home: const PlacesListScreen(),
    );
  }
}
