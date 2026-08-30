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

  Future<void> createEmptyProfile() =>
      apiClient.post('/customers/me/profile', body: {'profileData': {}});
  Future<void> updateEmptyProfile() =>
      apiClient.patch('/customers/me/profile', body: {'profileData': {}});
}
