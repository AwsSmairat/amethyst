enum PrinterErrorCode {
  platformNotSupported,
  bluetoothDisabled,
  printerNotFound,
  notConnected,
  connectionFailed,
  printTimeout,
  printFailed,
}

final class PrinterException implements Exception {
  const PrinterException(this.message, {this.code});

  final String message;
  final PrinterErrorCode? code;

  @override
  String toString() => message;
}
