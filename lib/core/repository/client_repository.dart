import '../constants/app_constants.dart';
import '../data/seed_data.dart';
import '../models/client.dart';

/// Reads client records for F1 lookup and the client 360. Backed by seed data
/// in demo mode; swap the body for Supabase queries scoped by `org_id`.
class ClientRepository {
  final List<Client> _clients = SeedData.clients();

  Future<List<Client>> all() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return List<Client>.unmodifiable(_clients);
  }

  /// Synchronous access to the in-memory clients (used for lookup grounding).
  List<Client> get cached => List<Client>.unmodifiable(_clients);

  List<String> clientNames() => _clients.map((Client c) => c.name).toList();

  Client? byId(String id) {
    for (final Client c in _clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Fuzzy name search for the lookup search field.
  Future<List<Client>> search(String query) async {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return all();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _clients
        .where((Client c) =>
            c.name.toLowerCase().contains(q) ||
            c.industry.toLowerCase().contains(q))
        .toList();
  }
}
