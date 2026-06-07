import 'package:shared_preferences/shared_preferences.dart';

abstract final class PrinterStorage {
  static const String _macKey = 'printer_last_mac';
  static const String _nameKey = 'printer_last_name';

  static Future<void> savePrinter({
    required String macAddress,
    required String name,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_macKey, macAddress);
    await prefs.setString(_nameKey, name);
  }

  static Future<({String? mac, String? name})> loadPrinter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return (
      mac: prefs.getString(_macKey),
      name: prefs.getString(_nameKey),
    );
  }

  static Future<void> clearPrinter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_macKey);
    await prefs.remove(_nameKey);
  }
}
