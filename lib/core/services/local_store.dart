import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin async key-value store over [SharedPreferences] for demo-mode
/// persistence (session, captures, activity feed). In production this layer is
/// superseded by Supabase; nothing else in the app talks to prefs directly.
class LocalStore {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<Map<String, dynamic>?> readJson(String key) async {
    final SharedPreferences prefs = await _instance;
    final String? raw = prefs.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<List<dynamic>> readList(String key) async {
    final SharedPreferences prefs = await _instance;
    final String? raw = prefs.getString(key);
    if (raw == null) return <dynamic>[];
    return jsonDecode(raw) as List<dynamic>;
  }

  Future<void> writeJson(String key, Object value) async {
    final SharedPreferences prefs = await _instance;
    await prefs.setString(key, jsonEncode(value));
  }

  Future<void> remove(String key) async {
    final SharedPreferences prefs = await _instance;
    await prefs.remove(key);
  }
}
