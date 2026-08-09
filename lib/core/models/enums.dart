// Enumerations shared across the domain.

/// Per-tenant role.
///
/// The authoritative role comes from the CRM (`GET /api/me`) and is carried on
/// [Me]; this one exists for the sign-in session, before that call has
/// happened. Where the two disagree, the server's answer is the real one — it
/// is what actually scopes the data.
enum UserRole { rep, manager, admin }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.rep => 'Sales rep',
        UserRole.manager => 'Sales manager',
        UserRole.admin => 'Org admin',
      };
}
