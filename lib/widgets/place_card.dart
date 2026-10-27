import 'package:flutter/material.dart';

import '../models/place.dart';
import '../theme/app_theme.dart';

/// One place in the list: a big rounded photo with the title and address on a
/// dark gradient, a round heart button and an arrow, like the travel design.
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final Place place;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      height: 236,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: softShadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Hero: the same tag on the detail screen makes the photo fly
                // from the card to the full screen during the transition.
                Hero(
                  tag: 'place-image-${place.id}',
                  child: PlaceImage(place: place),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.45, 1],
                      colors: [Colors.transparent, Color(0xCC000000)],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: HeartButton(
                    isFavorite: place.isFavorite,
                    onPressed: onToggleFavorite,
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 76,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        place.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.place_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                place.location.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The photo of a place, read from the file whose path is stored in the
/// database. If the file is gone, a neutral tile is shown instead of an error.
class PlaceImage extends StatelessWidget {
  const PlaceImage({super.key, required this.place, this.cacheWidth = 900});

  final Place place;

  /// Decode the picture at this width only: a 4000px camera photo would waste
  /// memory in a list of small cards.
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Image.file(
      place.image,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      errorBuilder: (context, error, stack) => ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 40,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A round white heart button that "pops" when toggled.
class HeartButton extends StatelessWidget {
  const HeartButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
  });

  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.elasticOut,
              ),
              child: child,
            ),
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              key: ValueKey(isFavorite),
              color: isFavorite ? const Color(0xFFE5484D) : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
