import 'package:flutter/material.dart';

/// The back arrow every "second-level" bottom-nav tab screen (Hotel, Halls)
/// shows, matching the approved app mockup — even though, being a tab and
/// not a pushed route, there is nothing to actually pop. Switches to the
/// Dashboard tab instead (`onOpenDashboardTab`) when embedded; falls back
/// to a plain `Navigator.pop` when this screen is ever hosted standalone
/// (pushed on top of another screen rather than as a bottom-nav tab).
class DashboardBackButton extends StatelessWidget {
  const DashboardBackButton({super.key, required this.embedded, this.onOpenDashboardTab});

  final bool embedded;
  final VoidCallback? onOpenDashboardTab;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Back',
      onPressed: () {
        if (embedded) {
          onOpenDashboardTab?.call();
        } else {
          Navigator.of(context).maybePop();
        }
      },
    );
  }
}
