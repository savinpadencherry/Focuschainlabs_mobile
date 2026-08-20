import 'package:equatable/equatable.dart';

/// The Google account this device is signed in as.
///
/// Deliberately says nothing about the organisation or the role. It used to:
/// it was built at sign-in with the org hard-coded to `org-fcl` and the role
/// to admin, which is right for one tenant and one person and wrong for
/// everyone else — and nothing on screen distinguished that guess from an
/// answer. Firebase knows who signed in; only the CRM knows which workspace
/// they belong to and what they may do there, and that lives on `Me`
/// (`GET /api/me`), resolved through `IdentityCache`.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarInitials,
  });

  final String id;
  final String name;
  final String email;
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
        'avatarInitials': avatarInitials,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        avatarInitials: json['avatarInitials'] as String?,
      );

  @override
  List<Object?> get props => <Object?>[id, name, email, avatarInitials];
}
