class LedgerCoreException implements Exception {
  final String message;
  final String statusCode;

  LedgerCoreException({this.statusCode = '0x9000', this.message = ''});
}

class LedgerAppAlreadyOpenException extends LedgerCoreException {
  LedgerAppAlreadyOpenException()
      : super(
          statusCode: '6d00',
          message:
              'The application is installed on the device, but an application is already launched.',
        );
}

class LedgerAppNotInstalledException extends LedgerCoreException {
  LedgerAppNotInstalledException()
      : super(
          statusCode: '6807',
          message: 'The requested application is not present on the device',
        );
}
