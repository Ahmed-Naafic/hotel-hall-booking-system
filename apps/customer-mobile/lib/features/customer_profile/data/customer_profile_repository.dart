import 'package:hotel_hall_core/hotel_hall_core.dart';

class CustomerSnapshot {
  const CustomerSnapshot({
    required this.user,
    required this.profile,
    required this.readiness,
  });
  final Map<String, dynamic> user;
  final Map<String, dynamic>? profile;
  final Map<String, dynamic> readiness;
}

class CustomerProfileRepository {
  CustomerProfileRepository(this.apiClient);
  final ApiClient apiClient;

  Future<CustomerSnapshot> getMe() async {
    final data = (await apiClient.get('/customers/me') as Map)
        .cast<String, dynamic>();
    return CustomerSnapshot(
      user: (data['user'] as Map).cast<String, dynamic>(),
      profile: (data['profile'] as Map?)?.cast<String, dynamic>(),
      readiness: (data['readiness'] as Map).cast<String, dynamic>(),
    );
  }

  /// Creates the Customer's profile with their Full Name (BDR-018) — the
  /// only approved profile field. Only reachable for an account that
  /// somehow has no profile yet (registered before this decision was
  /// approved); every new registration creates one automatically.
  Future<void> createProfile({required String fullName}) => apiClient.post(
    '/customers/me/profile',
    body: {'profileData': {'fullName': fullName}},
  );

  Future<void> updateFullName(String fullName) => apiClient.patch(
    '/customers/me/profile',
    body: {'profileData': {'fullName': fullName}},
  );
}
