/// User profile data model
class ProfileData {
  final String userName;
  final String? userBio;
  final DateTime joinedDate;
  final String? avatarPath;
  final bool notificationsEnabled;
  final String? authProvider; // null = local-only, 'google', 'apple'
  final String? authUserId;

  const ProfileData({
    required this.userName,
    this.userBio,
    required this.joinedDate,
    this.avatarPath,
    this.notificationsEnabled = true,
    this.authProvider,
    this.authUserId,
  });

  ProfileData copyWith({
    String? userName,
    String? userBio,
    DateTime? joinedDate,
    String? avatarPath,
    bool? notificationsEnabled,
    String? authProvider,
    String? authUserId,
  }) {
    return ProfileData(
      userName: userName ?? this.userName,
      userBio: userBio ?? this.userBio,
      joinedDate: joinedDate ?? this.joinedDate,
      avatarPath: avatarPath ?? this.avatarPath,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      authProvider: authProvider ?? this.authProvider,
      authUserId: authUserId ?? this.authUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'userBio': userBio,
      'joinedDate': joinedDate.toIso8601String(),
      'avatarPath': avatarPath,
      'notificationsEnabled': notificationsEnabled,
      'authProvider': authProvider,
      'authUserId': authUserId,
    };
  }

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      userName: json['userName'] as String? ?? 'Fashion Enthusiast',
      userBio: json['userBio'] as String?,
      joinedDate: json['joinedDate'] != null
          ? DateTime.parse(json['joinedDate'] as String)
          : DateTime.now(),
      avatarPath: json['avatarPath'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      authProvider: json['authProvider'] as String?,
      authUserId: json['authUserId'] as String?,
    );
  }

  factory ProfileData.initial() {
    return ProfileData(
      userName: 'Fashion Enthusiast',
      joinedDate: DateTime.now(),
      notificationsEnabled: true,
    );
  }
}

/// Profile statistics data
class ProfileStats {
  final int itemsCount;
  final int looksCount;
  final int totalWears;

  const ProfileStats({
    required this.itemsCount,
    required this.looksCount,
    required this.totalWears,
  });

  const ProfileStats.empty() : itemsCount = 0, looksCount = 0, totalWears = 0;
}
