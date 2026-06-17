import 'package:equatable/equatable.dart';

import 'enums.dart';

/// A key contact at a client company.
class Contact extends Equatable {
  const Contact({required this.name, required this.title, this.email});

  final String name;
  final String title;
  final String? email;

  @override
  List<Object?> get props => <Object?>[name, title, email];
}

/// An open or closed deal with a client.
class Deal extends Equatable {
  const Deal({
    required this.title,
    required this.stage,
    required this.value,
    this.sentiment = Sentiment.neutral,
  });

  final String title;
  final DealStage stage;
  final String value;
  final Sentiment sentiment;

  Deal copyWith({DealStage? stage, Sentiment? sentiment}) => Deal(
        title: title,
        stage: stage ?? this.stage,
        value: value,
        sentiment: sentiment ?? this.sentiment,
      );

  @override
  List<Object?> get props => <Object?>[title, stage, value, sentiment];
}

/// A logged touchpoint on the client timeline.
class Interaction extends Equatable {
  const Interaction({
    required this.summary,
    required this.date,
    required this.type,
  });

  final String summary;
  final DateTime date;
  final UpdateType type;

  @override
  List<Object?> get props => <Object?>[summary, date, type];
}

/// The company/contact a record is about; maps to the org's CRM record
/// (spec §8 `client`). Carries the data needed for the F1 "client 360".
class Client extends Equatable {
  const Client({
    required this.id,
    required this.name,
    required this.industry,
    required this.owner,
    this.sentiment = Sentiment.neutral,
    this.contacts = const <Contact>[],
    this.deals = const <Deal>[],
    this.interactions = const <Interaction>[],
    this.recentEmailSubjects = const <String>[],
    this.pendingFollowUps = const <String>[],
  });

  final String id;
  final String name;
  final String industry;
  final String owner;
  final Sentiment sentiment;
  final List<Contact> contacts;
  final List<Deal> deals;
  final List<Interaction> interactions;
  final List<String> recentEmailSubjects;
  final List<String> pendingFollowUps;

  String get initials =>
      name.isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase();

  Deal? get primaryDeal => deals.isEmpty ? null : deals.first;

  Client copyWith({
    Sentiment? sentiment,
    List<Deal>? deals,
    List<Interaction>? interactions,
    List<String>? pendingFollowUps,
  }) =>
      Client(
        id: id,
        name: name,
        industry: industry,
        owner: owner,
        sentiment: sentiment ?? this.sentiment,
        contacts: contacts,
        deals: deals ?? this.deals,
        interactions: interactions ?? this.interactions,
        recentEmailSubjects: recentEmailSubjects,
        pendingFollowUps: pendingFollowUps ?? this.pendingFollowUps,
      );

  @override
  List<Object?> get props => <Object?>[id, name, industry, owner, sentiment];
}
