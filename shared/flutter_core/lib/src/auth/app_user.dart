/// Mirrors `openapi.json#/components/schemas/PublicUser` exactly — no field
/// invented, none omitted.
class AppUser {
  const AppUser({
    required this.id,
    required this.mobileNumber,
    required this.accountType,
    required this.isVerified,
    required this.isActive,
    this.fullName,
  });

  final String id;
  final String mobileNumber;
  final String accountType;
  final bool isVerified;
  final bool isActive;
  // Populated for a Hotel Manager (BDR-019). A Customer's own display name
  // lives on CustomerProfile instead (BDR-018, fetched separately via
  // `GET /customers/me`) — always `null` here for that account type.
  final String? fullName;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        mobileNumber: json['mobileNumber'] as String,
        accountType: json['accountType'] as String,
        isVerified: json['isVerified'] as bool,
        isActive: json['isActive'] as bool,
        fullName: json['fullName'] as String?,
      );
}
