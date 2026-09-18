import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../bookings/presentation/screens/booking_detail_screen.dart';
import '../../application/notification_controller.dart';
import '../../data/notification_models.dart';

/// Notification V1 — Customer Mobile's Notification Center. Tapping a
/// Notification marks it read and navigates to the existing screen most
/// relevant to it (Approved Technical Design, "Navigation Targets") —
/// every Notification Catalog type reachable from Customer Mobile resolves
/// to Booking Detail, since every one of them concerns a Booking the
/// Customer already owns.
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NotificationController>().load());
  }

  Future<void> _openNotification(AppNotification notification) async {
    final controller = context.read<NotificationController>();
    if (notification.isUnread) await controller.markRead(notification.id);
    if (!mounted) return;
    if (notification.bookingId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: notification.bookingId!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.hh.surfacePage,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationController>(
            builder: (context, controller, _) => TextButton(
              onPressed: controller.unreadCount > 0 ? () => controller.markAllRead() : null,
              child: const Text('Mark all read'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<NotificationController>(
          builder: (context, controller, _) {
            return RefreshIndicator(
              onRefresh: controller.load,
              child: _body(controller),
            );
          },
        ),
      ),
    );
  }

  Widget _body(NotificationController controller) {
    switch (controller.status) {
      case NotificationLoadStatus.initial:
      case NotificationLoadStatus.loading:
        if (controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return _list(controller);
      case NotificationLoadStatus.error:
        return HHEmptyState(
          icon: Icons.error_outline,
          message: controller.errorMessage ?? 'Something went wrong.',
          actionLabel: 'Retry',
          onAction: controller.load,
        );
      case NotificationLoadStatus.ready:
        if (controller.notifications.isEmpty) {
          return const HHEmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'No notifications yet',
            message: 'Updates about your bookings and payments will appear here.',
          );
        }
        return _list(controller);
    }
  }

  Widget _list(NotificationController controller) {
    return ListView.separated(
      padding: const EdgeInsets.all(HHSpacing.space5),
      itemCount: controller.notifications.length + (controller.hasNext ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: HHSpacing.space3),
      itemBuilder: (context, index) {
        if (index >= controller.notifications.length) {
          controller.loadMore();
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: HHSpacing.space5),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final notification = controller.notifications[index];
        return HHCard(
          onTap: () => _openNotification(notification),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: notification.isUnread ? context.hh.actionPrimary : Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(width: HHSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isUnread ? HHTypeScale.weightSemibold : FontWeight.normal,
                        fontSize: HHTypeScale.textMd,
                      ),
                    ),
                    const SizedBox(height: HHSpacing.space1),
                    Text(notification.body, style: TextStyle(color: context.hh.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
