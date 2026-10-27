import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/place.dart';
import '../providers/user_places.dart';
import '../screens/place_detail.dart';
import '../utils/transitions.dart';
import 'place_card.dart';
import 'state_views.dart';

/// A scrolling list of [PlaceCard]s. Swipe a card to the right to remove it
/// (with an Undo), tap it to open the details, tap the heart to favorite it.
/// The same widget is used for "all places" and for "favorites".
class PlacesList extends ConsumerWidget {
  const PlacesList({
    super.key,
    required this.places,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final List<Place> places;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (places.isEmpty) {
      return EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return ListView.builder(
      // Extra space at the bottom so the last card is not hidden behind the
      // floating navigation bar and the add button.
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 170),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Dismissible(
            key: ValueKey('dismiss-${place.id}'),
            direction: DismissDirection.startToEnd,
            background: const _DeleteBackground(),
            onDismissed: (_) => _remove(context, ref, place),
            child: PlaceCard(
              place: place,
              onTap: () => Navigator.of(context).push(
                fadeSlideRoute(PlaceDetailScreen(place: place)),
              ),
              onToggleFavorite: () => _toggleFavorite(context, ref, place),
            ),
          ),
        )
            .animate(
              key: ValueKey(place.id),
              delay: Duration(milliseconds: 60 * index.clamp(0, 5)),
            )
            .fadeIn(duration: 380.ms)
            .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    Place place,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(userPlacesProvider.notifier).toggleFavorite(place.id);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not update the favorite.')),
      );
    }
  }

  /// Called after the swipe animation finished. The place disappears at once;
  /// the photo file is only deleted when the Undo bar goes away unused.
  Future<void> _remove(BuildContext context, WidgetRef ref, Place place) async {
    // Everything async below uses these two objects, not `context`/`ref`,
    // because the card (and maybe this list) is already gone when they run.
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(userPlacesProvider.notifier);
    try {
      await notifier.removePlace(place);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not remove the place.')),
      );
      return;
    }

    var undone = false;
    messenger.clearSnackBars();
    messenger
        .showSnackBar(
          SnackBar(
            content: Text('"${place.title}" removed'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                undone = true;
                notifier.restorePlace(place).catchError((_) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Could not restore the place.')),
                  );
                });
              },
            ),
          ),
        )
        .closed
        .then((_) {
      if (!undone) notifier.discardImage(place);
    });
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 28),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Icon(
        Icons.delete_outline_rounded,
        size: 32,
        color: scheme.onErrorContainer,
      ),
    );
  }
}
