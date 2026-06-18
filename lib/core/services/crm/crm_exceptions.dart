/// Typed CRM failures surfaced to the UI instead of silently returning empty
/// lists or generic error strings.
enum CrmErrorCode {
  unauthorized,
  notFound,
  conflict,
  malformed,
  network,
  unknown,
}

class CrmServiceException implements Exception {
  const CrmServiceException(this.code, this.message);

  final CrmErrorCode code;
  final String message;

  @override
  String toString() => 'CrmServiceException($code): $message';
}

CrmServiceException crmExceptionFromStatus(int status, String body) {
  switch (status) {
    case 401:
    case 403:
      return CrmServiceException(
        CrmErrorCode.unauthorized,
        'GitHub token rejected — check GITHUB_TOKEN scope and expiry.',
      );
    case 404:
      return CrmServiceException(
        CrmErrorCode.notFound,
        'CRM file not found at the configured path.',
      );
    case 409:
      return CrmServiceException(
        CrmErrorCode.conflict,
        'CRM was updated by someone else — retrying.',
      );
    default:
      if (status >= 500) {
        return CrmServiceException(
          CrmErrorCode.network,
          'GitHub CRM server error ($status).',
        );
      }
      return CrmServiceException(
        CrmErrorCode.unknown,
        'GitHub CRM error $status: $body',
      );
  }
}
