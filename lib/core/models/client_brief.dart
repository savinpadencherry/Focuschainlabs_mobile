import 'package:equatable/equatable.dart';

/// A pre-call briefing Rex generates from a client's CRM history (prep mode):
/// a one-line state of play, what to lead with, what to confirm, and any risks.
class ClientBrief extends Equatable {
  const ClientBrief({
    required this.headline,
    this.opener = '',
    this.talkingPoints = const <String>[],
    this.thingsToConfirm = const <String>[],
    this.risks = const <String>[],
  });

  /// One-sentence state of play, e.g. "Acme is warm on the ₹8.5L proposal."
  final String headline;

  /// A natural way to open the call.
  final String opener;

  /// Points worth raising, grounded in recent history.
  final List<String> talkingPoints;

  /// Open questions to nail down on the call.
  final List<String> thingsToConfirm;

  /// Risks / watch-outs (e.g. comparing vendors, gone quiet).
  final List<String> risks;

  bool get isEmpty =>
      headline.trim().isEmpty &&
      talkingPoints.isEmpty &&
      thingsToConfirm.isEmpty &&
      risks.isEmpty;

  factory ClientBrief.fromJson(Map<String, dynamic> json) => ClientBrief(
        headline: json['headline']?.toString() ?? '',
        opener: json['opener']?.toString() ?? '',
        talkingPoints: _stringList(json['talking_points']),
        thingsToConfirm: _stringList(json['things_to_confirm']),
        risks: _stringList(json['risks']),
      );

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((dynamic e) => e?.toString().trim() ?? '')
          .where((String s) => s.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  @override
  List<Object?> get props =>
      <Object?>[headline, opener, talkingPoints, thingsToConfirm, risks];
}
