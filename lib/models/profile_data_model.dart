import 'user_model.dart';

class ProfileData {
  final User user;
  final bool locationEnabled;
  final bool isUploading;

  ProfileData({
    required this.user,
    this.locationEnabled = false,
    this.isUploading = false,
  });

  // ✅ Méthode copyWith pour les mises à jour immutables
  ProfileData copyWith({
    User? user,
    bool? locationEnabled,
    bool? isUploading,
  }) {
    return ProfileData(
      user: user ?? this.user,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      isUploading: isUploading ?? this.isUploading,
    );
  }

  // ✅ Accesseurs pratiques
  String? get phoneNumber => user.phoneNumber;
  double? get latitude => user.lastLat;
  double? get longitude => user.lastLng;
  String? get photoUrl => user.photoUrl;
  int get userId => user.id;
  String get username => user.username;

  // ✅ Conversion vers Map (pour sauvegarde)
  Map<String, dynamic> toMap() {
    return {
      'user': user.toMap(),
      'locationEnabled': locationEnabled,
    };
  }

  // ✅ Création depuis Map + infos de base
  factory ProfileData.fromBaseInfo({
    required int userId,
    required String username,
    Map<String, dynamic>? userMap,
    bool locationEnabled = false,
  }) {
    final user = userMap != null
        ? User.fromMap(userMap)
        : User(id: userId, username: username);
    return ProfileData(
      user: user,
      locationEnabled: locationEnabled,
    );
  }
}