/// Turning what a rep typed into a number WhatsApp will accept.
///
/// `contacts.phone` is free text, and in practice it holds all of these:
///
///     8422978854          bare local, the common case
///     +919073388221       already international
///     +91 90733 88221     international with spacing
///     09073388221         local with a trunk zero
///     (080) 4567 8901     landline, punctuated
///
/// wa.me needs digits only, **including the country code and excluding the
/// leading +**. Handing it a bare local number does not fail loudly — WhatsApp
/// opens and says "the phone number shared via url is invalid", which a rep
/// reads as the client's number being wrong rather than the link being
/// malformed. That is the failure this class exists to prevent.
///
/// The dial code comes from the workspace, not from a constant here: which
/// country a bare number belongs to is a property of the tenant, and a client
/// guessing it would be wrong the first time this is sold outside India.
class PhoneNumber {
  const PhoneNumber._({
    required this.raw,
    required this.msisdn,
    required this.reason,
  });

  /// Parse [raw] for a workspace whose local numbers belong to [dialCode].
  factory PhoneNumber.parse(String raw, {required String dialCode}) {
    final String cc = dialCode.replaceAll(RegExp(r'[^0-9]'), '');
    final String trimmed = raw.trim();

    if (trimmed.isEmpty) {
      return PhoneNumber._(raw: raw, msisdn: '', reason: 'No number on file');
    }

    final bool explicitlyInternational = trimmed.startsWith('+');
    String digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return PhoneNumber._(raw: raw, msisdn: '', reason: 'Not a phone number');
    }

    // Written as +CC…, so it is already complete.
    if (explicitlyInternational) {
      return _finish(raw, digits, cc);
    }

    // A trunk zero is a domestic dialling convention and never part of the
    // international number: 09073388221 is +91 9073388221, not +91 09073388221.
    if (digits.length > 10 && digits.startsWith('0')) {
      digits = digits.replaceFirst(RegExp(r'^0+'), '');
    }

    // Already carries the country code (91 + ten digits here).
    if (cc.isNotEmpty &&
        digits.startsWith(cc) &&
        digits.length == cc.length + 10) {
      return _finish(raw, digits, cc);
    }

    // The common case: a bare local number.
    if (digits.length == 10) {
      return _finish(raw, '$cc$digits', cc);
    }

    // A local number with the STD code and a trunk zero — '(080) 4567 8901'.
    // Landlines reach ten digits this way, so they would otherwise look like
    // mobiles; _finish rejects them on the prefix rule below.
    if (digits.length == 11 && digits.startsWith('0')) {
      return _finish(raw, '$cc${digits.substring(1)}', cc);
    }

    // Anything else is a landline, an extension, or a typo. Guessing a country
    // code onto it would produce a link that opens WhatsApp on a stranger.
    return PhoneNumber._(
      raw: raw,
      msisdn: '',
      reason: 'Not a mobile number we can message',
    );
  }

  static PhoneNumber _finish(String raw, String digits, String cc) {
    // Shortest plausible international mobile number is around 8 digits after
    // the code; longest E.164 is 15 in total.
    if (digits.length < 8 || digits.length > 15) {
      return PhoneNumber._(
        raw: raw,
        msisdn: '',
        reason: 'Not a mobile number we can message',
      );
    }

    // India-specific, and deliberately the only country rule here: Indian
    // mobile numbers begin 6-9. It catches most landlines, because the STD
    // codes for Delhi, Mumbai, Kolkata, Chennai, Hyderabad and Pune all leave
    // a leading 1-4 once the trunk zero is stripped.
    //
    // It does NOT catch Bengaluru: 080 4567 8901 becomes 8045678901, and 80 is
    // a real mobile prefix, so an office line there is indistinguishable from
    // a mobile without an STD-code table. Left alone rather than special-cased
    // — a partial rule that is right about Delhi is worth having, and the cost
    // of the remaining case is WhatsApp saying the number is not on WhatsApp,
    // which is recoverable. Other dial codes are not second-guessed at all.
    if (cc == '91' && digits.length == 12) {
      final String local = digits.substring(2);
      if (!RegExp(r'^[6-9]').hasMatch(local)) {
        return PhoneNumber._(
          raw: raw,
          msisdn: '',
          reason: 'Landline — WhatsApp needs a mobile',
        );
      }
    }

    return PhoneNumber._(raw: raw, msisdn: digits, reason: '');
  }

  /// What the rep typed.
  final String raw;

  /// Digits only, country code included, no `+` — the form wa.me takes.
  /// Empty when the number cannot be messaged.
  final String msisdn;

  /// Why it cannot be messaged, for showing next to the lead.
  final String reason;

  bool get canWhatsApp => msisdn.isNotEmpty;

  /// `+91 90733 88221` — for showing back, so a rep can see the number the
  /// message is about to go to before they send it.
  String get pretty {
    if (!canWhatsApp) return raw;
    if (msisdn.length == 12 && msisdn.startsWith('91')) {
      return '+91 ${msisdn.substring(2, 7)} ${msisdn.substring(7)}';
    }
    return '+$msisdn';
  }

  /// The link that opens WhatsApp on this number with [message] prefilled.
  ///
  /// wa.me rather than the `whatsapp://` scheme: it opens the installed app
  /// when there is one and falls back to WhatsApp Web when there is not, so a
  /// tablet without the app still gets somewhere useful.
  Uri whatsAppUri(String message) => Uri.parse(
        'https://wa.me/$msisdn?text=${Uri.encodeComponent(message)}',
      );
}
