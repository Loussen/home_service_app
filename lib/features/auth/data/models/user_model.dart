import 'package:home_service_app/core/utils/json_numbers.dart';

class ProfileCompleteness {
  const ProfileCompleteness({
    required this.complete,
    required this.percent,
    this.missing = const [],
    this.profileId,
  });

  final bool complete;
  final int percent;
  final List<String> missing;
  final int? profileId;

  factory ProfileCompleteness.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ProfileCompleteness(complete: true, percent: 100);
    }
    final missingRaw = json['missing'];
    return ProfileCompleteness(
      complete: json['complete'] == true,
      percent: (json['percent'] as num?)?.toInt() ?? 0,
      missing: missingRaw is List
          ? missingRaw.map((e) => '$e').where((s) => s.isNotEmpty).toList()
          : const [],
      profileId: (json['profile_id'] as num?)?.toInt(),
    );
  }

  static ProfileCompleteness skipped({required int profileCount}) {
    if (profileCount > 0) {
      return const ProfileCompleteness(complete: true, percent: 100);
    }
    return const ProfileCompleteness(
      complete: false,
      percent: 0,
      missing: ['profile'],
    );
  }
}

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
    this.completeness,
  });

  final int id;
  final String phone;
  final String? name;
  final String? avatarUrl;
  final String activeRole;
  final double balance;
  final String status;
  final int providerProfilesCount;
  final ProfileCompleteness? completeness;
  bool get isProvider => activeRole == 'provider';
  bool get isClient => activeRole == 'client';
  bool get needsProviderOnboarding =>
      isProvider && providerProfilesCount == 0;

  ProfileCompleteness get effectiveCompleteness {
    if (!isProvider) {
      return const ProfileCompleteness(complete: true, percent: 100);
    }
    return completeness ??
        ProfileCompleteness.skipped(profileCount: providerProfilesCount);
  }

  bool get showCompletenessBanner =>
      isProvider && !effectiveCompleteness.complete;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final completenessJson = json['profile_completeness'];
    return UserModel(
      id: json['id'] as int,
      phone: json['phone'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      activeRole: json['active_role'] as String? ?? 'client',
      balance: parseDouble(json['balance']),
      status: json['status'] as String? ?? 'active',
      providerProfilesCount:
          (json['provider_profiles_count'] as num?)?.toInt() ?? 0,
      completeness: completenessJson is Map
          ? ProfileCompleteness.fromJson(
              Map<String, dynamic>.from(completenessJson),
            )
          : null,
    );
  }
}
