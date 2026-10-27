import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/place.dart';
import 'user_places.dart';

/// What the user typed in the search field.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// A *derived* provider: it is recalculated whenever the places or the search
/// text change, and widgets just watch the result. Nothing is stored twice.
final visiblePlacesProvider = Provider<List<Place>>((ref) {
  final places = ref.watch(userPlacesProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return places;
  return [
    for (final place in places)
      if (place.title.toLowerCase().contains(query) ||
          place.location.address.toLowerCase().contains(query))
        place,
  ];
});

/// The visible places that have a heart.
final favoritePlacesProvider = Provider<List<Place>>((ref) {
  return [
    for (final place in ref.watch(visiblePlacesProvider))
      if (place.isFavorite) place,
  ];
});

/// Light / dark / system theme, remembered between launches.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() => ThemeMode.system;

  /// Reads the saved choice. Called once at startup.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    state = ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
