import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';

/// Initialises the shared Supabase CRM when the project URL and publishable key
/// are configured. The publishable key is passed through Supabase Flutter's
/// `anonKey` parameter; authorization is enforced by Row Level Security.
abstract final class SupabaseBootstrap {
  static bool ready = false;
  static Object? lastError;

  static Future<void> init() async {
    ready = false;
    lastError = null;
    if (!AppConfig.hasSupabase) return;

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      ready = true;
    } catch (error) {
      lastError = error;
      ready = false;
    }
  }
}
