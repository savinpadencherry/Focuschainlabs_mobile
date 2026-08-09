/// User-facing copy kept in one place for easy editing / future localisation.
abstract final class AppStrings {
  // Auth
  static const String welcomeTitle = 'Welcome to\nSecona';
  static const String welcomeBody =
      'Your pipeline, your inventory and Ona — the same desk your team uses, on your phone.';
  static const String isolationNote =
      'Your organisation’s data stays isolated and access-controlled.';
  static const String continueGoogle = 'Continue with Google';

  /// Shown when Google sign-in worked but the address is not on the CRM's
  /// invite list. Naming the address matters — the usual cause is signing in
  /// with a personal account instead of a work one.
  static const String notAMemberTitle = 'No access for this account';

  // Ona
  static const String onaTitle = 'Ona';
  static const String onaHint = 'Ask about leads, properties or your day…';
  static const String onaThinking = 'Thinking…';

  // Pipeline
  static const String pipelineTitle = 'Pipeline';
  static const String pipelineSearchHint = 'Search leads, companies, owners…';
  static const String pipelineEmpty = 'No leads in your pipeline yet.';

  // Listings
  static const String listingsTitle = 'Listings';
  static const String listingsSearchHint = 'Search inventory — “3 BHK Whitefield”';
  static const String listingsEmptyInventory = 'No properties in inventory yet.';

  // Shared
  static const String offline = 'Could not reach the CRM.';
  static const String retry = 'Try again';
}
