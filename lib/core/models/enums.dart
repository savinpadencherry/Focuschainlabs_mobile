/// Enumerations shared across the domain. Values mirror the spec's extraction
/// schema and data model so they serialise cleanly to/from the backend.

/// Update types the conversational engine can produce (spec §8).
enum UpdateType { comment, interaction, stageChange, followUp }

extension UpdateTypeX on UpdateType {
  String get wire => switch (this) {
        UpdateType.comment => 'comment',
        UpdateType.interaction => 'interaction',
        UpdateType.stageChange => 'stage_change',
        UpdateType.followUp => 'follow_up',
      };

  String get label => switch (this) {
        UpdateType.comment => 'Comment',
        UpdateType.interaction => 'Interaction',
        UpdateType.stageChange => 'Stage change',
        UpdateType.followUp => 'Follow-up',
      };

  static UpdateType fromWire(String value) => UpdateType.values.firstWhere(
        (UpdateType t) => t.wire == value,
        orElse: () => UpdateType.comment,
      );
}

/// Sentiment values from the extraction schema (spec §8).
enum Sentiment { positive, neutral, negative, atRisk }

extension SentimentX on Sentiment {
  String get wire => switch (this) {
        Sentiment.positive => 'positive',
        Sentiment.neutral => 'neutral',
        Sentiment.negative => 'negative',
        Sentiment.atRisk => 'at_risk',
      };

  String get label => switch (this) {
        Sentiment.positive => 'Positive',
        Sentiment.neutral => 'Neutral',
        Sentiment.negative => 'Negative',
        Sentiment.atRisk => 'At risk',
      };

  static Sentiment fromWire(String value) => Sentiment.values.firstWhere(
        (Sentiment s) => s.wire == value,
        orElse: () => Sentiment.neutral,
      );
}

/// Per-tenant role (spec §3).
enum UserRole { rep, manager, admin }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.rep => 'Sales rep',
        UserRole.manager => 'Sales manager',
        UserRole.admin => 'Org admin',
      };
}

/// Deal pipeline stage.
enum DealStage { lead, qualified, proposal, negotiation, won, lost }

extension DealStageX on DealStage {
  String get label => switch (this) {
        DealStage.lead => 'Lead',
        DealStage.qualified => 'Qualified',
        DealStage.proposal => 'Proposal',
        DealStage.negotiation => 'Negotiation',
        DealStage.won => 'Won',
        DealStage.lost => 'Lost',
      };
}

/// Lifecycle of a capture (spec §8 capture.status).
enum CaptureStatus { pending, drafting, review, written, undone }

/// Connection state for an integration (CRM/calendar/task/email).
enum ConnectionStatus { connected, pending, error }
