import 'dart:convert';

import 'package:amethyst/core/printer/driver_receipt_style_id.dart';
import 'package:amethyst/core/printer/driver_receipt_styles_state.dart';
import 'package:amethyst/core/printer/receipt_style_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class ReceiptStyleStorage {
  static const String _legacyStyleKey = 'receipt_style_config_v1';
  static const String _stylesKey = 'driver_receipt_styles_v2';

  static Future<DriverReceiptStylesState> loadAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_stylesKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return DriverReceiptStylesState.fromJson(decoded);
        }
      } on Object {
        // ignore malformed cache
      }
    }
    return _migrateLegacy(prefs);
  }

  static Future<ReceiptStyleConfig> load() async {
    final DriverReceiptStylesState state = await loadAll();
    return state.activeStyle;
  }

  static Future<DriverReceiptStyleId> loadActiveId() async {
    final DriverReceiptStylesState state = await loadAll();
    return state.activeId;
  }

  static Future<void> saveAll(DriverReceiptStylesState state) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stylesKey, jsonEncode(state.toJson()));
  }

  static Future<void> savePattern({
    required DriverReceiptStyleId id,
    required ReceiptStyleConfig config,
  }) async {
    final DriverReceiptStylesState state = await loadAll();
    final Map<DriverReceiptStyleId, ReceiptStyleConfig> styles =
        Map<DriverReceiptStyleId, ReceiptStyleConfig>.from(state.styles);
    styles[id] = config;
    await saveAll(state.copyWith(styles: styles));
  }

  static Future<void> setActive(DriverReceiptStyleId id) async {
    final DriverReceiptStylesState state = await loadAll();
    await saveAll(state.copyWith(activeId: id));
  }

  static Future<void> resetPattern(DriverReceiptStyleId id) async {
    await savePattern(id: id, config: ReceiptStyleConfig.preset(id));
  }

  static Future<void> resetAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stylesKey);
    await prefs.remove(_legacyStyleKey);
  }

  static Future<DriverReceiptStylesState> _migrateLegacy(
    SharedPreferences prefs,
  ) async {
    final String? legacy = prefs.getString(_legacyStyleKey);
    final DriverReceiptStylesState defaults = DriverReceiptStylesState.defaults();
    if (legacy == null || legacy.isEmpty) {
      return defaults;
    }
    try {
      final Object? decoded = jsonDecode(legacy);
      if (decoded is Map<String, dynamic>) {
        final ReceiptStyleConfig migrated = ReceiptStyleConfig.fromJson(decoded);
        final Map<DriverReceiptStyleId, ReceiptStyleConfig> styles =
            Map<DriverReceiptStyleId, ReceiptStyleConfig>.from(defaults.styles);
        styles[DriverReceiptStyleId.pattern1] = migrated;
        final DriverReceiptStylesState state = DriverReceiptStylesState(
          activeId: DriverReceiptStyleId.pattern1,
          styles: styles,
        );
        await saveAll(state);
        await prefs.remove(_legacyStyleKey);
        return state;
      }
    } on Object {
      // ignore
    }
    return defaults;
  }
}
