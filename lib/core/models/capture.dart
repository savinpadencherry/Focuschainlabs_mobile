import 'package:equatable/equatable.dart';

class Capture extends Equatable {
  const Capture({
    required this.id,
    required this.clientName,
    required this.summary,
    required this.createdAt,
    this.isPending = true,
  });

  final String id;
  final String clientName;
  final String summary;
  final DateTime createdAt;
  final bool isPending;

  @override
  List<Object?> get props => <Object?>[
        id,
        clientName,
        summary,
        createdAt,
        isPending,
      ];
}
