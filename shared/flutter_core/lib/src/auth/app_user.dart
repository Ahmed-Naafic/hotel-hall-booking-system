/// Mirrors `openapi.json#/components/schemas/PublicUser` exactly — no field
/// invented, none omitted.
class AppUser {
  const AppUser({
    required this.id,
    required this.mobileNumber,
    required this.accountType,
    required this.isVerified,
    required this.isActive,
  });

  final String id;
  final String mobileNumber;
  final String accountType;
  final bool isVerified;
  final bool isActive;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        mobileNumber: json['mobileNumber'] as String,
        accountType: json['accountType'] as String,
        isVerified: json['isVerified'] as bool,
        isActive: json['isActive'] as bool,
      );
}
