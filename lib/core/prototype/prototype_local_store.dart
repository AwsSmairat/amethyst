import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for prototype data and auth session (no Firebase).
final class PrototypeLocalStore {
  PrototypeLocalStore._();

  static const String _sessionUserIdKey = 'prototype_session_user_id';
  static const String _snapshotFileName = 'prototype_snapshot.json';

  static Future<void> init() async {
    // Reserved for future eager setup; [PrototypeSampleData.ensureLoaded] loads data.
  }

  static Future<String?> readSessionUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? id = prefs.getString(_sessionUserIdKey);
    if (id == null || id.isEmpty) {
      return null;
    }
    return id;
  }

  static Future<void> persistSessionUserId(String? userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (userId == null || userId.isEmpty) {
      await prefs.remove(_sessionUserIdKey);
      return;
    }
    await prefs.setString(_sessionUserIdKey, userId);
  }

  static Future<Map<String, dynamic>?> loadSnapshot() async {
    try {
      final File file = await _snapshotFile();
      if (!await file.exists()) {
        return null;
      }
      final String raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return decoded;
    } on Object {
      return null;
    }
  }

  static Future<void> saveSnapshot(Map<String, dynamic> snapshot) async {
    try {
      final File file = await _snapshotFile();
      await file.parent.create(recursive: true);
      final String encoded = jsonEncode(snapshot);
      await file.writeAsString(encoded, flush: true);
    } on Object {
      // Prototype: ignore persistence errors; in-memory state still works.
    }
  }

  static Future<File> _snapshotFile() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_snapshotFileName');
  }
}
