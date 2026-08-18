import 'package:home_service_app/core/utils/json_numbers.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.phone,
    required this.activeRole,
    required this.balance,
    this.name,
    this.avatarUrl,
    this.status = 'active',
    this.providerProfilesCount = 0,
  });

  final int id;
  final String phone;
  final String? name;
  final String? avatarUrl;
  final String activeRole;
  final double balance;
  final String status;
  final int providerProfilesCount;
  bool get isProvider => activeRole == 'provider';
  bool get isClient => activeRole == 'client';
  bool get needsProviderOnboarding =>
      isProvider && providerProfilesCount == 0;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      phone: json['phone'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      activeRole: json['active_role'] as String? ?? 'client',
      balance: parseDouble(json['balance']),
      status: json['status'] as String? ?? 'active',
      providerProfilesCount: (json['provider_profiles_count'] as num?)?.toInt() ?? 0,
    );
  }
}
