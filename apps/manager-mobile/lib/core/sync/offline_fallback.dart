import 'package:hotel_hall_core/hotel_hall_core.dart';

import 'local_replica.dart';

/// Server first; the replica only when the server cannot be reached
/// (Local-First Technical Design §16, "Manager Mobile").
///
/// The screens outside the Hall list read this way rather than local-first,
/// because online they show data the replica deliberately does not hold — a
/// Booking's customer name and number (business decision #3) — and must keep
/// showing it. So online nothing changes; offline, [local] answers instead and
/// the replica is told, which is what raises the app-wide offline banner.
///
/// Only a [NetworkException] falls back. A server *response* — an
/// [ApiException] — is an answer, and replacing it with older local data would
/// hide it. [local] returns null when the replica cannot answer (never synced,
/// not this user's, no database), and then the original failure stands, exactly
/// as before local-first existed.
Future<T> serverFirst<T>(
  LocalReplica? replica, {
  required Future<T> Function() online,
  required Future<T?> Function(LocalReplica replica) local,
}) async {
  try {
    final result = await online();
    replica?.noteReachable();
    return result;
  } on NetworkException catch (error) {
    if (replica == null) rethrow;
    final fallback = await local(replica);
    if (fallback == null) rethrow;
    replica.noteUnreachable(error);
    return fallback;
  }
}
