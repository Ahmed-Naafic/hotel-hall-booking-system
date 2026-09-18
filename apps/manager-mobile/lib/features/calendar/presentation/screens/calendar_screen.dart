import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../../../core/presentation/manager_formatters.dart';
import '../../../bookings/data/booking_models.dart';
import '../../../bookings/data/booking_repository.dart';
import '../../../hotel/application/hotel_context_controller.dart';

/// Manager → Calendar tab (replaces the previous standalone "Profile"
/// destination, which moved to the hamburger-menu Drawer on Home). A month
/// grid plus the selected day's Bookings — every Booking shown is a real
/// row from `GET /hotels/:hotelId/bookings`, grouped by day client-side
/// (no dedicated date-range endpoint exists yet).
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  Future<List<ManagerBooking>>? _bookingsFuture;
  String? _loadedForHotelId;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  void _maybeLoadBookings(String? hotelId) {
    if (hotelId == null) {
      _bookingsFuture = null;
      _loadedForHotelId = null;
      return;
    }
    if (hotelId == _loadedForHotelId) return;
    _loadedForHotelId = hotelId;
    _bookingsFuture = ManagerBookingRepository(context.read<ApiClient>()).list(hotelId);
  }

  void _retry() => setState(() => _loadedForHotelId = null);

  void _changeMonth(int delta) {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final hotelContext = context.watch<HotelContextController>();
    _maybeLoadBookings(hotelContext.hotel?.id);

    return Scaffold(
      backgroundColor: context.hh.surfacePage,
      appBar: AppBar(title: const Text('Calendar'), automaticallyImplyLeading: false),
      body: SafeArea(child: _body(hotelContext)),
    );
  }

  Widget _body(HotelContextController hotelContext) {
    switch (hotelContext.status) {
      case HotelContextStatus.unknown:
      case HotelContextStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case HotelContextStatus.error:
        return HHEmptyState(
          icon: Icons.error_outline,
          message: hotelContext.errorMessage ?? 'Something went wrong.',
          iconColor: context.hh.danger700,
          actionLabel: 'Retry',
          onAction: hotelContext.load,
        );

      case HotelContextStatus.none:
        return HHEmptyState(
          icon: Icons.apartment_outlined,
          title: 'Set up your Hotel',
          message: 'Bookings belong to a Hotel — set up your Hotel first.',
          actionLabel: 'Set up my Hotel',
          onAction: hotelContext.createHotel,
          isLoading: false,
        );

      case HotelContextStatus.ready:
        return FutureBuilder<List<ManagerBooking>>(
          future: _bookingsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              if (snapshot.hasError) {
                return HHEmptyState(
                  icon: Icons.error_outline,
                  message: 'Unable to load bookings.',
                  iconColor: context.hh.danger700,
                  actionLabel: 'Retry',
                  onAction: () async => _retry(),
                );
              }
              return const Center(child: CircularProgressIndicator());
            }
            return _CalendarBody(
              bookings: snapshot.data!,
              visibleMonth: _visibleMonth,
              selectedDate: _selectedDate,
              onChangeMonth: _changeMonth,
              onSelectDate: (date) => setState(() => _selectedDate = date),
            );
          },
        );
    }
  }
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody({
    required this.bookings,
    required this.visibleMonth,
    required this.selectedDate,
    required this.onChangeMonth,
    required this.onSelectDate,
  });

  final List<ManagerBooking> bookings;
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final ValueChanged<int> onChangeMonth;
  final ValueChanged<DateTime> onSelectDate;

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  static bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<ManagerBooking> get _selectedDayBookings {
    final list = bookings.where((b) => _isSameDay(b.startsAt.toLocal(), selectedDate)).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return list;
  }

  Set<DateTime> get _daysWithBookings => bookings
      .map((b) => DateTime(b.startsAt.toLocal().year, b.startsAt.toLocal().month, b.startsAt.toLocal().day))
      .toSet();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstOfMonth = DateTime(visibleMonth.year, visibleMonth.month);
    final daysInMonth = DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    // DateTime.weekday is Monday=1..Sunday=7; this grid is Sunday-first
    // (matching the reference design), so Sunday needs zero leading blanks.
    final leadingBlanks = firstOfMonth.weekday % 7;

    final cells = <DateTime?>[
      for (var i = 0; i < leadingBlanks; i++) null,
      for (var day = 1; day <= daysInMonth; day++) DateTime(visibleMonth.year, visibleMonth.month, day),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final daysWithBookings = _daysWithBookings;
    final selectedDayBookings = _selectedDayBookings;
    final isToday = _isSameDay(selectedDate, now);

    return ListView(
      padding: const EdgeInsets.all(HHSpacing.space7),
      children: [
        HHCard(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => onChangeMonth(-1)),
                  Expanded(
                    child: Text(
                      '${_monthNames[visibleMonth.month - 1]} ${visibleMonth.year}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: HHTypeScale.weightSemibold, fontSize: HHTypeScale.textLg),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => onChangeMonth(1)),
                ],
              ),
              const SizedBox(height: HHSpacing.space3),
              Row(
                children: [
                  for (final label in _weekdayLabels)
                    Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: context.hh.textMuted,
                            fontSize: HHTypeScale.textXs,
                            fontWeight: HHTypeScale.weightMedium,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: HHSpacing.space2),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final cell in cells)
                    cell == null
                        ? const SizedBox.shrink()
                        : _DayCell(
                            date: cell,
                            isSelected: _isSameDay(cell, selectedDate),
                            isToday: _isSameDay(cell, now),
                            hasBookings: daysWithBookings.contains(DateTime(cell.year, cell.month, cell.day)),
                            onTap: () => onSelectDate(cell),
                          ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: HHSpacing.space7),
        Text(
          isToday ? "Today's Bookings" : 'Bookings on ${ManagerFormatters.date(selectedDate)}',
          style: TextStyle(fontWeight: HHTypeScale.weightSemibold, fontSize: HHTypeScale.textLg),
        ),
        const SizedBox(height: HHSpacing.space4),
        if (selectedDayBookings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: HHSpacing.space5),
            child: Text('No bookings for this day.', style: TextStyle(color: context.hh.textMuted)),
          )
        else
          for (final booking in selectedDayBookings) ...[
            _DayBookingTile(booking: booking),
            if (booking != selectedDayBookings.last) const SizedBox(height: HHSpacing.space3),
          ],
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasBookings,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool hasBookings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? context.hh.actionPrimary : Colors.transparent,
              border: isToday && !isSelected ? Border.all(color: context.hh.actionPrimary) : null,
            ),
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected ? Colors.white : context.hh.textBody,
                fontWeight: isSelected || isToday ? HHTypeScale.weightSemibold : HHTypeScale.weightRegular,
              ),
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 4,
            width: 4,
            child: hasBookings
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? context.hh.actionPrimary : context.hh.actionAccent,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _DayBookingTile extends StatelessWidget {
  const _DayBookingTile({required this.booking});

  final ManagerBooking booking;

  @override
  Widget build(BuildContext context) {
    return HHCard(
      padding: const EdgeInsets.all(HHSpacing.space4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: context.hh.surfaceNavyTint, borderRadius: BorderRadius.circular(HHRadii.control)),
            child: Icon(Icons.meeting_room_outlined, color: context.hh.actionPrimary, size: 20),
          ),
          const SizedBox(width: HHSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.hallName ?? 'Hall',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: HHTypeScale.weightSemibold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking.customerFullName ?? booking.customerMobileNumber ?? 'Customer'} • '
                  '${ManagerFormatters.time(booking.startsAt)}–${ManagerFormatters.time(booking.endsAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.hh.textMuted, fontSize: HHTypeScale.textXs),
                ),
              ],
            ),
          ),
          const SizedBox(width: HHSpacing.space3),
          HHStatusBadge(label: ManagerFormatters.status(booking.status), tone: toneForBookingStatus(booking.status)),
        ],
      ),
    );
  }
}
