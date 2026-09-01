import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../application/hall_list_controller.dart';
import '../../data/hall_models.dart';
import '../../data/hall_repository.dart';
import '../widgets/hall_list_tile.dart';
import 'hall_details_screen.dart';
import 'hall_form_screen.dart';

/// Manager → My Hotel → Halls — the Hotel Manager's own management view
/// (`GET /hotels/:hotelId/halls`, WBS-05): every Hall regardless of
/// visibility (`BR-HALL-02`).
class HallListScreen extends StatelessWidget {
  const HallListScreen({super.key, required this.hotelId});

  final String hotelId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HallListController>(
      create: (context) => HallListController(
        repository: HallRepository(context.read<ApiClient>()),
        hotelId: hotelId,
      )..load(),
      child: _HallListView(hotelId: hotelId),
    );
  }
}

class _HallListView extends StatefulWidget {
  const _HallListView({required this.hotelId});
  final String hotelId;

  @override
  State<_HallListView> createState() => _HallListViewState();
}

class _HallListViewState extends State<_HallListView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<HallListController>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    final controller = context.read<HallListController>();
    final created = await Navigator.of(context).push<Hall>(
      MaterialPageRoute(builder: (_) => HallFormScreen(hotelId: widget.hotelId)),
    );
    if (created != null && mounted) {
      controller.load();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hall created.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = context.watch<HallListController>();

    return Scaffold(
      backgroundColor: HHColors.surfacePage,
      appBar: AppBar(title: const Text('Halls')),
      floatingActionButton: list.status == HallListStatus.ready || list.status == HallListStatus.empty
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create Hall'),
            )
          : null,
      body: SafeArea(child: _body(context, list)),
    );
  }

  Future<void> _openEdit(Hall hall) async {
    final controller = context.read<HallListController>();
    final updated = await Navigator.of(context).push<Hall>(
      MaterialPageRoute(
        builder: (_) => HallFormScreen(hotelId: widget.hotelId, existingHall: hall),
      ),
    );
    if (updated != null && mounted) {
      controller.upsert(updated);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hall updated.')));
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
          iconColor: HHColors.danger700,
          actionLabel: 'Retry',
          onAction: list.load,
        );

      case HallListStatus.empty:
        return HHEmptyState(
          icon: Icons.meeting_room_outlined,
          title: 'No halls yet',
          message: 'Create your first Hall to start building your inventory.',
          actionLabel: 'Create Hall',
          onAction: _openCreate,
        );

      case HallListStatus.ready:
        return RefreshIndicator(
          onRefresh: list.load,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(HHSpacing.space7),
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
                  MaterialPageRoute(builder: (_) => HallDetailsScreen(hotelId: widget.hotelId, hallId: hall.id)),
                ),
                onEdit: () => _openEdit(hall),
              );
            },
          ),
        );
    }
  }
}
