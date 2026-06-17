import 'package:equatable/equatable.dart';

import 'enums.dart';

/// An authenticated member of exactly one org, with a role (spec §3, F10).
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.orgId,
    required this.orgName,
    required this.role,
    this.avatarInitials,
  });

  final String id;
  final String name;
  final String email;
  final String orgId;
  final String orgName;
  final UserRole role;
  final String? avatarInitials;

  String get initials {
    if (avatarInitials != null) return avatarInitials!;
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'email': email,
        'orgId': orgId,
        'orgName': orgName,
        'role': role.name,
        'avatarInitials': avatarInitials,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        orgId: json['orgId'] as String,
        orgName: json['orgName'] as String,
        role: UserRole.values.firstWhere(
          (UserRole r) => r.name == json['role'],
          orElse: () => UserRole.rep,
        ),
        avatarInitials: json['avatarInitials'] as String?,
      );

  @override
  List<Object?> get props =>
      <Object?>[id, name, email, orgId, orgName, role, avatarInitials];
}
