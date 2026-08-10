import 'package:equatable/equatable.dart';
import 'package:home_service_app/features/profile/data/models/provider_profile_model.dart';

class ProfileListState extends Equatable {
  const ProfileListState({
    this.profiles = const [],
    this.loading = false,
    this.message,
  });

  final List<ProviderProfileModel> profiles;
  final bool loading;
  final String? message;

  ProfileListState copyWith({
    List<ProviderProfileModel>? profiles,
    bool? loading,
    String? message,
    bool clearMessage = false,
  }) {
    return ProfileListState(
      profiles: profiles ?? this.profiles,
      loading: loading ?? this.loading,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [profiles, loading, message];
}
