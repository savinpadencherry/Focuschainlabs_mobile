import 'package:equatable/equatable.dart';

/// A CRM contact/lead, mirroring the Leads Agent's contact schema (a subset of
/// the fields persisted by `utils.crm_store`).
class CrmContact extends Equatable {
  const CrmContact({
    required this.id,
    required this.name,
    this.company = '',
    this.status = '',
    this.dealStatus = '',
    this.value = '',
    this.owner = '',
  });

  final String id;
  final String name;
  final String company;
  final String status;
  final String dealStatus;
  final String value;
  final String owner;

  factory CrmContact.fromJson(Map<String, dynamic> json) => CrmContact(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        company: json['company']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        dealStatus: json['deal_status']?.toString() ?? '',
        value: json['value']?.toString() ?? '',
        owner: json['owner']?.toString() ?? '',
      );

  @override
  List<Object?> get props => <Object?>[id, name, company, status];
}

/// A single interaction on a contact's timeline (comment or email event).
class CrmInteraction extends Equatable {
  const CrmInteraction({
    required this.body,
    required this.createdAt,
    this.author = '',
    this.kind = 'comment',
  });

  final String body;
  final DateTime createdAt;
  final String author;
  final String kind; // comment | email

  factory CrmInteraction.fromJson(Map<String, dynamic> json) => CrmInteraction(
        body: (json['body'] ?? json['summary'] ?? '').toString(),
        createdAt: DateTime.tryParse(
              (json['created_at'] ?? json['sent_at'] ?? '').toString(),
            ) ??
            DateTime.now(),
        author: (json['author'] ?? json['from'] ?? '').toString(),
        kind: json['kind']?.toString() ??
            (json['subject'] != null ? 'email' : 'comment'),
      );

  @override
  List<Object?> get props => <Object?>[body, createdAt, author, kind];
}

/// Outcome of an upsert into the CRM.
class CrmWriteResult extends Equatable {
  const CrmWriteResult({
    required this.ok,
    required this.contactId,
    required this.contactName,
    this.action = 'created',
    this.webUrl,
    this.error,
  });

  final bool ok;
  final String contactId;
  final String contactName;
  final String action; // created | merged
  final String? webUrl; // deep link to the contact in the CRM, if provided
  final String? error;

  const CrmWriteResult.failure(this.error)
      : ok = false,
        contactId = '',
        contactName = '',
        action = 'none',
        webUrl = null;

  @override
  List<Object?> get props =>
      <Object?>[ok, contactId, contactName, action, webUrl, error];
}
