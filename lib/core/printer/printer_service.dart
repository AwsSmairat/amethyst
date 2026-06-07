import 'dart:async';
import 'dart:io';

import 'package:amethyst/core/printer/printer_exception.dart';
import 'package:amethyst/core/printer/printer_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

enum PrinterConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

final class BluetoothPrinterDevice {
  const BluetoothPrinterDevice({
    required this.name,
    required this.macAddress,
  });

  final String name;
  final String macAddress;
}

final class PrinterService {
  PrinterService() {
    unawaited(_tryAutoReconnect());
  }

  final ValueNotifier<PrinterConnectionStatus> status =
      ValueNotifier<PrinterConnectionStatus>(PrinterConnectionStatus.disconnected);

  String? _connectedMac;
  String? _connectedName;

  String? get connectedMac => _connectedMac;
  String? get connectedName => _connectedName;

  void _ensureMobilePlatform() {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      throw const PrinterException(
        'الطباعة الحرارية متاحة على تطبيق الموبايل فقط',
        code: PrinterErrorCode.platformNotSupported,
      );
    }
  }

  Future<bool> isBluetoothEnabled() async {
    _ensureMobilePlatform();
    return PrintBluetoothThermal.bluetoothEnabled;
  }

  Future<List<BluetoothPrinterDevice>> scanPairedPrinters() async {
    _ensureMobilePlatform();
    if (!await isBluetoothEnabled()) {
      throw const PrinterException(
        'البلوتوث غير مفعّل',
        code: PrinterErrorCode.bluetoothDisabled,
      );
    }
    final List<BluetoothInfo> paired = await PrintBluetoothThermal.pairedBluetooths;
    return paired
        .map(
          (BluetoothInfo info) => BluetoothPrinterDevice(
            name: info.name,
            macAddress: info.macAdress,
          ),
        )
        .toList(growable: false);
  }

  Future<void> connect(BluetoothPrinterDevice device) async {
    _ensureMobilePlatform();
    if (!await isBluetoothEnabled()) {
      throw const PrinterException(
        'البلوتوث غير مفعّل',
        code: PrinterErrorCode.bluetoothDisabled,
      );
    }
    status.value = PrinterConnectionStatus.connecting;
    try {
      final bool ok = await PrintBluetoothThermal.connect(
        macPrinterAddress: device.macAddress,
      ).timeout(const Duration(seconds: 12));
      if (!ok) {
        status.value = PrinterConnectionStatus.error;
        throw const PrinterException(
          'تعذّر الاتصال بالطابعة',
          code: PrinterErrorCode.connectionFailed,
        );
      }
      _connectedMac = device.macAddress;
      _connectedName = device.name;
      await PrinterStorage.savePrinter(
        macAddress: device.macAddress,
        name: device.name,
      );
      status.value = PrinterConnectionStatus.connected;
    } on TimeoutException {
      status.value = PrinterConnectionStatus.error;
      throw const PrinterException(
        'انتهت مهلة الاتصال بالطابعة',
        code: PrinterErrorCode.printTimeout,
      );
    } on PrinterException {
      rethrow;
    } on Object catch (e) {
      status.value = PrinterConnectionStatus.error;
      throw PrinterException(
        e.toString(),
        code: PrinterErrorCode.connectionFailed,
      );
    }
  }

  Future<void> disconnect() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return;
    }
    await PrintBluetoothThermal.disconnect;
    _connectedMac = null;
    _connectedName = null;
    status.value = PrinterConnectionStatus.disconnected;
  }

  Future<void> _tryAutoReconnect() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return;
    }
    final ({String? mac, String? name}) saved = await PrinterStorage.loadPrinter();
    if (saved.mac == null || saved.mac!.isEmpty) {
      return;
    }
    try {
      if (!await isBluetoothEnabled()) {
        return;
      }
      final bool already = await PrintBluetoothThermal.connectionStatus;
      if (already) {
        _connectedMac = saved.mac;
        _connectedName = saved.name;
        status.value = PrinterConnectionStatus.connected;
        return;
      }
      await connect(
        BluetoothPrinterDevice(
          name: saved.name ?? saved.mac!,
          macAddress: saved.mac!,
        ),
      );
    } on Object {
      status.value = PrinterConnectionStatus.disconnected;
    }
  }

  Future<void> ensureConnected() async {
    _ensureMobilePlatform();
    if (!await isBluetoothEnabled()) {
      throw const PrinterException(
        'البلوتوث غير مفعّل',
        code: PrinterErrorCode.bluetoothDisabled,
      );
    }
    final bool live = await PrintBluetoothThermal.connectionStatus;
    if (live && _connectedMac != null) {
      status.value = PrinterConnectionStatus.connected;
      return;
    }
    final ({String? mac, String? name}) saved = await PrinterStorage.loadPrinter();
    if (saved.mac == null || saved.mac!.isEmpty) {
      throw const PrinterException(
        'لم يتم اختيار طابعة',
        code: PrinterErrorCode.printerNotFound,
      );
    }
    await connect(
      BluetoothPrinterDevice(
        name: saved.name ?? saved.mac!,
        macAddress: saved.mac!,
      ),
    );
  }

  Future<void> printBytes(List<int> bytes) async {
    await ensureConnected();
    try {
      final bool ok = await PrintBluetoothThermal.writeBytes(bytes)
          .timeout(const Duration(seconds: 20));
      if (!ok) {
        status.value = PrinterConnectionStatus.disconnected;
        throw const PrinterException(
          'فشلت عملية الطباعة',
          code: PrinterErrorCode.printFailed,
        );
      }
    } on TimeoutException {
      throw const PrinterException(
        'انتهت مهلة الطباعة',
        code: PrinterErrorCode.printTimeout,
      );
    } on PrinterException {
      rethrow;
    } on Object catch (e) {
      status.value = PrinterConnectionStatus.disconnected;
      throw PrinterException(
        e.toString(),
        code: PrinterErrorCode.printFailed,
      );
    }
  }
}
