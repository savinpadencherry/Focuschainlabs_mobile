import '../models/capture.dart';

class CaptureRepository {
  Future<List<Capture>> fetchPendingCaptures() async {
    return <Capture>[
      Capture(
        id: 'demo-acme',
        clientName: 'Acme',
        summary: 'Capture the outcome of the discovery call.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
    ];
  }
}
