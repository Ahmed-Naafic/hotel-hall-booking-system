import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../../core/presentation/dashboard_back_button.dart';
import '../../application/hall_list_controller.dart';
import '../../data/hall_models.dart';
import '../../data/hall_repository.dart';
import '../widgets/hall_list_tile.dart';
import 'hall_details_screen.dart';
import 'hall_form_screen.dart';

/// Manager → My Hotel → Halls — the Hotel Manager's own management view
/// (`GET /hotels/:hotelId/halls`, WBS-05): every Hall regardless of
/// visibility (`BR-HALL-02`), searchable by name and filterable by the
/// Manager's own Active/Inactive toggle.
class HallListScreen extends StatelessWidget {
  const HallListScreen({
    super.key,
    required this.hotelId,
    this.embedded = false,
    this.onOpenDashboardTab,
  });

  final String hotelId;

  /// True when hosted as the Halls tab of the bottom-navigation shell
  /// ([HomeScreen]) rather than pushed on top of another screen — loading
  /// behavior is unchanged since this screen owns its own
  /// [HallListController] regardless of embedding; only the back arrow's
  /// behavior differs ([DashboardBackButton]).
  final bool embedded;

  /// Switches [HomeScreen] to its Dashboard tab — the approved app mockup's
  /// own "Halls" screen shows a back arrow even though, as a bottom-nav
  /// tab, there's no route of its own to pop.
  final VoidCallback? onOpenDashboardTab;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HallListController>(
      create: (context) => HallListController(
        repository: HallRepository(context.read<ApiClient>()),
        hotelId: hotelId,
      )..load(),
      child: _HallListView(hotelId: hotelId, embedded: embedded, onOpenDashboardTab: onOpenDashboardTab),
    );
  }
}

class _HallListView extends StatefulWidget {
  const _HallListView({required this.hotelId, required this.embedded, this.onOpenDashboardTab});
  final String hotelId;
  final bool embedded;
  final VoidCallback? onOpenDashboardTab;

  @override
  State<_HallListView> createState() => _HallListViewState();
}

class _HallListViewState extends State<_HallListView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<HallListController>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    final controller = context.read<HallListController>();
    final created = await Navigator.of(context).push<Hall>(
      MaterialPageRoute(
        builder: (_) => HallFormScreen(hotelId: widget.hotelId),
      ),
    );
    if (created != null && mounted) {
      controller.load();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hall created.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = context.watch<HallListController>();

    final canCreate = list.status == HallListStatus.ready || list.status == HallListStatus.empty;

    return Scaffold(
      backgroundColor: context.hh.surfacePage,
      appBar: AppBar(
        title: const Text('Halls'),
        centerTitle: true,
        leading: DashboardBackButton(embedded: widget.embedded, onOpenDashboardTab: widget.onOpenDashboardTab),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('Add Hall'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                HHSpacing.space7,
                HHSpacing.space5,
                HHSpacing.space7,
                HHSpacing.space3,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: list.setSearch,
                decoration: InputDecoration(
                  hintText: 'Search halls...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            list.setSearch('');
                          },
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: HHSpacing.space7),
              child: Row(
                // Spread across the full width — All at the left edge,
                // Inactive at the right edge, Active landing in the true
                // center between them (not just the middle item of a
                // left-packed row).
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusChip(
                    label: 'All',
                    count: list.allCount,
                    selected: list.statusFilter == null,
                    onTap: () => list.setStatusFilter(null),
                  ),
                  _StatusChip(
                    label: 'Active',
                    count: list.activeCount,
                    selected: list.statusFilter == 'active',
                    onTap: () => list.setStatusFilter('active'),
                  ),
                  _StatusChip(
                    label: 'Inactive',
                    count: list.inactiveCount,
                    selected: list.statusFilter == 'inactive',
                    onTap: () => list.setStatusFilter('inactive'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: HHSpacing.space3),
            Expanded(child: _body(context, list)),
          ],
        ),
      ),
    );
  }

  Future<void> _openEdit(Hall hall) async {
    final controller = context.read<HallListController>();
    final updated = await Navigator.of(context).push<Hall>(
      MaterialPageRoute(
        builder: (_) =>
            HallFormScreen(hotelId: widget.hotelId, existingHall: hall),
      ),
    );
    if (updated != null && mounted) {
      controller.upsert(updated);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hall updated.')));
    }
  }

  Future<void> _toggleActive(HallListController controller, Hall hall, bool isActive) async {
    try {
      await controller.setHallActive(hall, isActive);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isActive ? 'Hall activated.' : 'Hall deactivated.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on NetworkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _body(BuildContext context, HallListController list) {
    switch (list.status) {
      case HallListStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case HallListStatus.error:
        return HHEmptyState(
          icon: Icons.error_outline,
          message: list.errorMessage ?? 'Something went wrong.',
          iconColor: context.hh.danger700,
          actionLabel: 'Retry',
          onAction: list.load,
        );

      case HallListStatus.empty:
        return list.isFiltering
            ? HHEmptyState(
                icon: Icons.search_off,
                title: 'No halls match',
                message: 'Try a different search or filter.',
                actionLabel: 'Clear filters',
                onAction: () async {
                  _searchController.clear();
                  list.setSearch('');
                  list.setStatusFilter(null);
                },
              )
            : HHEmptyState(
                icon: Icons.meeting_room_outlined,
                title: 'No halls yet',
                message: 'Create your first Hall to start building your inventory.',
                actionLabel: 'Add Hall',
                onAction: _openCreate,
              );

      case HallListStatus.ready:
        return RefreshIndicator(
          onRefresh: list.load,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
              HHSpacing.space7,
              0,
              HHSpacing.space7,
              HHSpacing.space7,
            ),
            itemCount: list.halls.length + (list.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= list.halls.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: HHSpacing.space4),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final hall = list.halls[index];
              return HallListTile(
                hall: hall,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HallDetailsScreen(
                      hotelId: widget.hotelId,
                      hallId: hall.id,
                    ),
                  ),
                ),
                onEdit: () => _openEdit(hall),
                onToggleActive: (isActive) => _toggleActive(list, hall, isActive),
              );
            },
          ),
        );
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = count == null ? label : '$label ($count)';
    return Material(
      color: selected ? context.hh.actionPrimary : context.hh.surfaceSunken,
      borderRadius: BorderRadius.circular(HHRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HHRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HHSpacing.space5,
            vertical: HHSpacing.space3,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? context.hh.textInverse : context.hh.textMuted,
              fontWeight: selected ? HHTypeScale.weightSemibold : HHTypeScale.weightRegular,
              fontSize: HHTypeScale.textSm,
            ),
          ),
        ),
      ),
    );
  }
}
