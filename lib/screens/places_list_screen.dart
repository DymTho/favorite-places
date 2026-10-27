import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ui_state.dart';
import '../providers/user_places.dart';
import '../theme/app_theme.dart';
import '../utils/transitions.dart';
import '../widgets/places_list.dart';
import '../widgets/places_overview_map.dart';
import '../widgets/state_views.dart';
import 'add_place.dart';

/// The home screen: header with search, three tabs (all places, favorites, map)
/// in a floating bottom bar, and the "Add place" button.
class PlacesListScreen extends ConsumerStatefulWidget {
  const PlacesListScreen({super.key});

  @override
  ConsumerState<PlacesListScreen> createState() => _PlacesListScreenState();
}

class _PlacesListScreenState extends ConsumerState<PlacesListScreen> {
  // The Future that loads the places from the database. It is created once
  // here (not in build) so that rebuilding the screen never reloads the data.
  late Future<void> _placesFuture;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _placesFuture = ref.read(userPlacesProvider.notifier).loadPlaces();
  }

  void _retry() {
    setState(() {
      _placesFuture = ref.read(userPlacesProvider.notifier).loadPlaces();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final count = ref.watch(userPlacesProvider.select((p) => p.length));
    final isMapTab = _tab == 2;

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          count == 0
                              ? 'Discover'
                              : '$count ${count == 1 ? 'place' : 'places'} saved',
                          style: text.labelLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text('Favorite Places', style: text.headlineMedium),
                      ],
                    ),
                  ),
                  const _ThemeToggle(),
                ],
              ),
            ),
            if (!isMapTab) const _SearchField(),
            Expanded(
              child: FutureBuilder<void>(
                future: _placesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ErrorState(
                      message: 'Could not load your places.',
                      onRetry: _retry,
                    );
                  }
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    child: KeyedSubtree(
                      key: ValueKey(_tab),
                      child: _buildTab(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          fadeSlideRoute(const AddPlaceScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add place'),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? scheme.surfaceContainerHigh
                : scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(32),
            boxShadow: softShadow(context),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (index) => setState(() => _tab = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore_rounded),
                  label: 'Places',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: 'Favorites',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map_rounded),
                  label: 'Map',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case 1:
        return _FavoritesTab();
      case 2:
        return const PlacesOverviewMap();
      default:
        return _AllPlacesTab();
    }
  }
}

class _AllPlacesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAny = ref.watch(userPlacesProvider).isNotEmpty;
    return PlacesList(
      places: ref.watch(visiblePlacesProvider),
      emptyIcon: hasAny ? Icons.search_off_rounded : Icons.landscape_outlined,
      emptyTitle: hasAny ? 'No matches' : 'No places yet',
      emptyMessage: hasAny
          ? 'Try another search.'
          : 'Tap "Add place" to save your first favorite spot.',
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasAny = ref.watch(userPlacesProvider).isNotEmpty;
    final searching = ref.watch(searchQueryProvider).trim().isNotEmpty;
    return PlacesList(
      places: ref.watch(favoritePlacesProvider),
      emptyIcon: searching ? Icons.search_off_rounded : Icons.favorite_border_rounded,
      emptyTitle: searching ? 'No matches' : 'No favorites yet',
      emptyMessage: searching
          ? 'Try another search.'
          : hasAny
              ? 'Tap the heart on a place to find it here.'
              : 'Add a place first, then mark it with a heart.',
    );
  }
}

/// The search box under the header. Typing updates [searchQueryProvider];
/// the lists watch the filtered result.
class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: TextField(
        controller: _controller,
        onChanged: ref.read(searchQueryProvider.notifier).set,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search places',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _controller.clear();
                    ref.read(searchQueryProvider.notifier).set('');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

/// Round button that flips between light and dark theme.
class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton.filledTonal(
      tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
      onPressed: () => ref
          .read(themeModeProvider.notifier)
          .set(isDark ? ThemeMode.light : ThemeMode.dark),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => RotationTransition(
          turns: Tween<double>(begin: 0.75, end: 1).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey(isDark),
        ),
      ),
    );
  }
}
