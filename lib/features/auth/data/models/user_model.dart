import 'package:home_service_app/core/remote/app_remote_config.dart';
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
    this.isBlocked = false,
    this.profileStatus,
    this.profileStatusLabel,
    this.providerProfilesCount = 0,
    this.completeness,
    this.connectQuota,
    this.urgentQuota,
    this.bumpQuota,
    this.needsRole = false,
    this.providerApprovalStatus,
    this.needsProviderApproval = false,
    this.providerApprovalMessage,
    this.providerRejectionNote,
  });

  final int id;
  final String phone;
  final String? name;
  final String? avatarUrl;
  final String activeRole;
  final double balance;
  final String status;
  final bool isBlocked;
  final String? profileStatus;
  final String? profileStatusLabel;
  final int providerProfilesCount;
  final ProfileCompleteness? completeness;
  final ConnectQuota? connectQuota;
  final UrgentQuota? urgentQuota;
  final BumpQuota? bumpQuota;
  final bool needsRole;
  final String? providerApprovalStatus;
  final bool needsProviderApproval;
  final String? providerApprovalMessage;
  final String? providerRejectionNote;
  bool get isProvider => activeRole == 'provider';
  bool get isClient => activeRole == 'client';
  bool get needsProviderOnboarding =>
      isProvider && providerProfilesCount == 0;
  bool get isProviderPending =>
      isProvider && (needsProviderApproval || providerApprovalStatus == 'pending');
  bool get isProviderRejected =>
      isProvider && providerApprovalStatus == 'rejected';
  bool get canConnect => connectQuota?.canConnect ?? true;
  bool get canUrgent => urgentQuota?.canUrgent ?? true;
  bool get canBump => bumpQuota?.canBump ?? true;

  String get displayProfileStatus {
    if (isBlocked || status == 'blocked' || profileStatus == 'blocked') {
      return profileStatusLabel ?? 'Bloklanıb';
    }
    if (profileStatusLabel != null && profileStatusLabel!.isNotEmpty) {
      return profileStatusLabel!;
    }
    return switch (providerApprovalStatus) {
      'approved' => 'Təsdiqli',
      'rejected' => 'Rədd edilib',
      'pending' => 'Gözləyir',
      _ => '—',
    };
  }

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
    final quotaJson = json['connect_quota'];
    final urgentJson = json['urgent_quota'];
    final bumpJson = json['bump_quota'];
    final status = json['status'] as String? ?? 'active';
    return UserModel(
      id: json['id'] as int,
      phone: json['phone'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      activeRole: json['active_role'] as String? ?? 'client',
      balance: parseDouble(json['balance']),
      status: status,
      isBlocked: json['is_blocked'] == true || status == 'blocked',
      profileStatus: json['profile_status'] as String?,
      profileStatusLabel: json['profile_status_label'] as String?,
      providerProfilesCount:
          (json['provider_profiles_count'] as num?)?.toInt() ?? 0,
      completeness: completenessJson is Map
          ? ProfileCompleteness.fromJson(
              Map<String, dynamic>.from(completenessJson),
            )
          : null,
      connectQuota: quotaJson is Map
          ? ConnectQuota.fromJson(Map<String, dynamic>.from(quotaJson))
          : null,
      urgentQuota: urgentJson is Map
          ? UrgentQuota.fromJson(Map<String, dynamic>.from(urgentJson))
          : null,
      bumpQuota: bumpJson is Map
          ? BumpQuota.fromJson(Map<String, dynamic>.from(bumpJson))
          : null,
      needsRole: json['needs_role'] == true,
      providerApprovalStatus: json['provider_approval_status'] as String?,
      needsProviderApproval: json['needs_provider_approval'] == true,
      providerApprovalMessage: json['provider_approval_message'] as String?,
      providerRejectionNote: json['provider_rejection_note'] as String?,
    );
  }
}

class ConnectQuota {
  const ConnectQuota({
    required this.inFreeWindow,
    required this.dailyRemaining,
    required this.dailyLimit,
    required this.canConnect,
    this.freeQuota = 5,
    this.freeUsed = 0,
    this.freeRemaining = 0,
    this.fee = 0,
  });

  final bool inFreeWindow;
  final int dailyRemaining;
  final int dailyLimit;
  final bool canConnect;
  final int freeQuota;
  final int freeUsed;
  final int freeRemaining;
  final double fee;

  factory ConnectQuota.fromJson(Map<String, dynamic> json) {
    final freeQuota = (json['free_quota'] as num?)?.toInt() ?? 5;
    final freeUsed = (json['free_used'] as num?)?.toInt() ?? 0;
    final freeRemaining = (json['free_remaining'] as num?)?.toInt() ??
        (freeQuota - freeUsed).clamp(0, freeQuota);
    return ConnectQuota(
      inFreeWindow: json['in_free_window'] == true,
      dailyRemaining: (json['daily_remaining'] as num?)?.toInt() ?? 0,
      dailyLimit: (json['daily_limit'] as num?)?.toInt() ?? 10,
      canConnect: json['can_connect'] != false,
      freeQuota: freeQuota,
      freeUsed: freeUsed,
      freeRemaining: freeRemaining,
      fee: parseDouble(json['fee']),
    );
  }

  String hintLabel() {
    final daily = '$dailyRemaining';
    if (inFreeWindow) {
      if (freeRemaining > 0) {
        return t('match.connect_free', params: {
          'left': '$freeRemaining',
          'quota': '$freeQuota',
          'count': daily,
        });
      }
      return t('match.connect_free_open', params: {'count': daily});
    }
    final feeText = fee == fee.roundToDouble()
        ? fee.toStringAsFixed(0)
        : fee.toStringAsFixed(1);
    return t('match.connect_paid', params: {
      'fee': feeText,
      'count': daily,
    });
  }
}

class UrgentQuota {
  const UrgentQuota({
    required this.dailyRemaining,
    required this.dailyLimit,
    required this.canUrgent,
    this.radiusKm = 5,
    this.hours = 2,
    this.fee = 2,
  });

  final int dailyRemaining;
  final int dailyLimit;
  final bool canUrgent;
  final double radiusKm;
  final int hours;
  final double fee;

  factory UrgentQuota.fromJson(Map<String, dynamic> json) {
    return UrgentQuota(
      dailyRemaining: (json['daily_remaining'] as num?)?.toInt() ?? 0,
      dailyLimit: (json['daily_limit'] as num?)?.toInt() ?? 3,
      canUrgent: json['can_urgent'] != false,
      radiusKm: parseDouble(json['radius_km'], fallback: 5),
      hours: (json['hours'] as num?)?.toInt() ?? 2,
      fee: parseDouble(json['fee'], fallback: 2),
    );
  }
}

class BumpQuota {
  const BumpQuota({
    required this.dailyRemaining,
    required this.dailyLimit,
    required this.canBump,
    this.hours = 24,
    this.fee = 1,
  });

  final int dailyRemaining;
  final int dailyLimit;
  final bool canBump;
  final int hours;
  final double fee;

  factory BumpQuota.fromJson(Map<String, dynamic> json) {
    return BumpQuota(
      dailyRemaining: (json['daily_remaining'] as num?)?.toInt() ?? 0,
      dailyLimit: (json['daily_limit'] as num?)?.toInt() ?? 2,
      canBump: json['can_bump'] != false,
      hours: (json['hours'] as num?)?.toInt() ?? 24,
      fee: parseDouble(json['fee'], fallback: 1),
    );
  }
}
