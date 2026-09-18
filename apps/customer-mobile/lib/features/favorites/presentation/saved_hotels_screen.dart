import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../discovery/data/discovery_models.dart';
import '../../discovery/data/discovery_repository.dart';
import '../../discovery/presentation/discover_screen.dart' show HotelDetailScreen;
import '../application/favorites_controller.dart';
import '../application/saved_hotels_controller.dart';

/// Customer Mobile — the dedicated Saved Hotels screen deferred from the
/// icons-only Favorites V1. Reachable from Discover's header bookmark icon.
class SavedHotelsScreen extends StatefulWidget {
  const SavedHotelsScreen({super.key});

  @override
  State<SavedHotelsScreen> createState() => _SavedHotelsScreenState();
}

class _SavedHotelsScreenState extends State<SavedHotelsScreen> {
  late final SavedHotelsController _controller = SavedHotelsController(
    repository: DiscoveryRepository(context.read<ApiClient>()),
    favorites: context.read<FavoritesController>(),
  );

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.hh.surfacePage,
      appBar: AppBar(title: const Text('Saved Hotels')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _controller.load,
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _body(),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_controller.errorMessage != null) {
      return ListView(
        children: [
          HHEmptyState(
            icon: Icons.error_outline,
            message: _controller.errorMessage!,
            actionLabel: 'Retry',
            onAction: _controller.load,
          ),
        ],
      );
    }
    if (_controller.isLoading && _controller.hotels.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.hotels.isEmpty) {
      return ListView(
        children: const [
          HHEmptyState(
            icon: Icons.bookmark_border_rounded,
            title: 'No saved Hotels yet',
            message: 'Tap the bookmark icon on a Hotel to save it here.',
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(HHSpacing.space5),
      itemCount: _controller.hotels.length,
      separatorBuilder: (_, __) => const SizedBox(height: HHSpacing.space4),
      itemBuilder: (context, index) => _SavedHotelTile(hotel: _controller.hotels[index]),
    );
  }
}

class _SavedHotelTile extends StatelessWidget {
  const _SavedHotelTile({required this.hotel});

  final HotelSummary hotel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return HHCard(
      padding: const EdgeInsets.all(10),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HotelDetailScreen(hotelId: hotel.id)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 92,
              height: 92,
              child: hotel.logo?.url == null
                  ? Container(
                      color: scheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(Icons.apartment_rounded, color: scheme.onSurfaceVariant),
                    )
                  : Image.network(
                      hotel.logo!.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: scheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotel.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (hotel.location.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: scheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hotel.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.bookmark_rounded, color: scheme.primary),
            tooltip: 'Remove from saved',
            onPressed: () => context.read<FavoritesController>().toggle(hotel.id),
          ),
        ],
      ),
    );
  }
}
