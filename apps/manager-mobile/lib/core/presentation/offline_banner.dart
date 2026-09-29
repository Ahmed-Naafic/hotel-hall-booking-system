import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../sync/local_replica.dart';

/// The one app-wide statement that what is on screen may be out of date.
///
/// Shown above every screen, from the replica's single reachability flag —
/// raised by whichever request first failed to reach the server (a sync, or
/// any read that fell back to local data), cleared by the next one that
/// succeeds. One banner rather than a notice per screen, so no screen can show
/// saved data without saying so, including ones added later.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  /// For `MaterialApp.builder`, so the banner sits above every route.
  static Widget wrap(BuildContext context, Widget? child) =>
      OfflineBanner(child: child ?? const SizedBox.shrink());

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<LocalReplica?>()?.isOffline ?? false;
    if (!offline) return child;
    return Column(
      children: [
        Material(
          color: context.hh.surfaceSunken,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: HHSpacing.space7, vertical: HHSpacing.space3),
              child: Row(
                children: [
                  Icon(Icons.cloud_off, size: 16, color: context.hh.textMuted),
                  const SizedBox(width: HHSpacing.space2),
                  Expanded(
                    child: Text(
                      'Offline — data may be out of date. Changes need a connection.',
                      style: TextStyle(color: context.hh.textMuted, fontSize: HHTypeScale.textSm),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // The banner took the status-bar inset; the screen below must not
        // pad for it a second time.
        Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: child)),
      ],
    );
  }
}
