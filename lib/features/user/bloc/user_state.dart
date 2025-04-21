import 'package:equatable/equatable.dart';
import 'package:sacdia/features/user/models/user_profile_model.dart';

enum UserStatus {
  initial,
  loading,
  loaded,
  error,
}

class UserState extends Equatable {
  final UserStatus status;
  final UserProfileModel? userProfile;
  final String? errorMessage;
  final bool isChangingClubType;
  
  const UserState({
    this.status = UserStatus.initial,
    this.userProfile,
    this.errorMessage,
    this.isChangingClubType = false,
  });
  
  bool get isLoading => status == UserStatus.loading || isChangingClubType;
  
  UserState copyWith({
    UserStatus? status,
    UserProfileModel? userProfile,
    String? errorMessage,
    bool? isChangingClubType,
  }) {
    return UserState(
      status: status ?? this.status,
      userProfile: userProfile ?? this.userProfile,
      errorMessage: errorMessage,
      isChangingClubType: isChangingClubType ?? this.isChangingClubType,
    );
  }
  
  /// Limpia los errores del estado
  UserState clearErrors() {
    return copyWith(
      errorMessage: null,
    );
  }
  
  @override
  List<Object?> get props => [status, userProfile, errorMessage, isChangingClubType];
} 