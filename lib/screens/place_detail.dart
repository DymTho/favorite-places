import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/place.dart';
import '../providers/user_places.dart';
import '../utils/transitions.dart';
import '../widgets/map_preview.dart';
import '../widgets/place_card.dart';
import 'map.dart';

/// Details of one place: the photo fills the screen, a round map preview and the
/// address sit at the bottom. Tapping the map opens the full map.
class PlaceDetailScreen extends ConsumerWidget {
  const PlaceDetailScreen({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the live copy of the place, so the heart here updates when it is
    // toggled (the `place` we were given is a frozen snapshot).
    final live = ref.watch(
      userPlacesProvider.select(
        (places) => places.where((p) => p.id == place.id).firstOrNull,
      ),
    );
    final current = live ?? place;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'place-image-${current.id}',
            child: PlaceImage(place: current, cacheWidth: 1400),
          ),
          // Dark fades at the top and bottom keep white text readable.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.22, 0.45, 1],
                colors: [
                  Color(0x99000000),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xE6000000),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      HeartButton(
                        isFavorite: current.isFavorite,
                        onPressed: () => ref
                            .read(userPlacesProvider.notifier)
                            .toggleFavorite(current.id),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      fadeSlideRoute(
                        MapScreen(
                          initialLocation: current.location,
                          markerTitle: current.title,
                        ),
                      ),
                    ),
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 24),
                        ],
                      ),
                      child: ClipOval(
                        child: MapPreview(location: current.location),
                      ),
                    ),
                  ).animate().scale(
                        delay: 250.ms,
                        duration: 500.ms,
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.5, 0.5),
                      ),
                  const SizedBox(height: 18),
                  Text(
                    current.title,
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(color: Colors.white),
                  ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    current.location.address,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(color: Colors.white70),
                  ).animate(delay: 380.ms).fadeIn().slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      // Without a Maps key the address *is* the coordinates,
                      // so showing them twice would only repeat the text.
                      if (current.location.address !=
                          current.location.coordinatesText)
                        _InfoChip(
                          icon: Icons.my_location_rounded,
                          label: current.location.coordinatesText,
                        ),
                      _InfoChip(
                        icon: Icons.event_outlined,
                        label: 'Added ${_date(current.createdAt)}',
                      ),
                    ],
                  ).animate(delay: 450.ms).fadeIn(),
                  const SizedBox(height: 10),
                  Text(
                    'Map © OpenStreetMap contributors',
                    style: text.labelSmall?.copyWith(color: Colors.white54),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _date(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black87),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
