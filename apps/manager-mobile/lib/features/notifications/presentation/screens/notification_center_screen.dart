import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../application/notification_controller.dart';
import '../../data/notification_models.dart';

/// Notification V1 — Manager Mobile's Notification Center. Every
/// Notification Catalog type reachable here (`NEW_BOOKING_REQUEST`,
/// `CUSTOMER_PAYMENT_REPORTED`, `CUSTOMER_BOOKING_CANCELLED`) concerns the
/// own-Hotel Bookings queue — the safest existing destination for it
/// (Approved Technical Design, "Navigation Targets"): the Bookings tab
/// lives inside `HomeScreen`'s `IndexedStack`, not a pushable route, so
/// this screen pops itself and returns `true` to signal its caller
/// (Dashboard's bell action) to switch to that tab, the same
/// push-and-react-on-return shape already used elsewhere in this app.
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
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HHColors.surfacePage,
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
          builder: (context, controller, _) => RefreshIndicator(
            onRefresh: controller.load,
            child: _body(controller),
          ),
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
                    color: notification.isUnread ? HHColors.actionPrimary : Colors.transparent,
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
                    Text(notification.body, style: TextStyle(color: HHColors.textMuted)),
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
