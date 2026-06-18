import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';

/// Initialises the Supabase client (CRM database) when `SUPABASE_URL` and
/// `SUPABASE_ANON_KEY` are present. Degrades silently otherwise so the app
/// keeps running on the mock/GitHub CRM.
abstract final class SupabaseBootstrap {
  static bool ready = false;

  static Future<void> init() async {
    if (!AppConfig.hasSupabase) return;
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      );
      ready = true;
    } catch (_) {
      ready = false;
    }
  }
}
