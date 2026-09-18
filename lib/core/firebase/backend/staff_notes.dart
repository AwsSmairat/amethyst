part of '../amethyst_firebase_backend.dart';

mixin _FirebaseStaffNotesOps on _FirebaseBackendHelpers {
  Future<List<Map<String, dynamic>>> listStaffNoteRecipients() async {
    await _requireStaff();
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.users)
        .where('isActive', isEqualTo: true)
        .get();
    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final Map<String, dynamic> u = mapUserDoc(doc);
      final String role = u['role']?.toString() ?? '';
      if (role == 'admin' || role == 'driver') {
        out.add(u);
      }
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> createStaffNotes({
    required String message,
    required String recipientKind,
    String? driverUserId,
  }) async {
    final Map<String, dynamic> actor = await _requireStaff();
    final String text = message.trim();
    if (text.isEmpty) {
      throw ApiException('Empty message', code: 'EMPTY_MESSAGE');
    }
    final List<String> targetUserIds = <String>[];
    switch (recipientKind) {
      case 'all_admins':
        final QuerySnapshot<Map<String, dynamic>> snap = await _db
            .collection(FirestorePaths.users)
            .where('role', isEqualTo: 'admin')
            .get();
        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
          if (doc.data()['isActive'] == true) {
            targetUserIds.add(doc.id);
          }
        }
      case 'driver':
        final String? id = driverUserId?.trim();
        if (id == null || id.isEmpty) {
          throw ApiException('Missing driver', code: 'MISSING_DRIVER');
        }
        targetUserIds.add(id);
      default:
        throw ApiException('Invalid recipient', code: 'INVALID_RECIPIENT');
    }
    if (targetUserIds.isEmpty) {
      throw ApiException('No recipients', code: 'NO_RECIPIENTS');
    }
    final List<Map<String, dynamic>> created = <Map<String, dynamic>>[];
    for (final String toUserId in targetUserIds) {
      if (toUserId == actor['id']) {
        continue;
      }
      final DocumentReference<Map<String, dynamic>> ref =
          _db.collection(FirestorePaths.staffNotes).doc();
      await ref.set(<String, dynamic>{
        'message': text,
        'toUserId': toUserId,
        'fromUserId': actor['id'],
        'fromUserName': actor['fullName']?.toString() ?? '',
        'createdAt': serverTimestamp(),
        'readAt': null,
      });
      final DocumentSnapshot<Map<String, dynamic>> doc = await ref.get();
      created.add(<String, dynamic>{
        'id': doc.id,
        ...?doc.data(),
      });
    }
    if (created.isEmpty) {
      throw ApiException('No recipients', code: 'NO_RECIPIENTS');
    }
    return created;
  }

  Future<Map<String, dynamic>?> _selectPendingStaffNote(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    Map<String, dynamic>? pick;
    DateTime? pickAt;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in docs) {
      final Map<String, dynamic> data = doc.data();
      if (data['readAt'] != null) {
        continue;
      }
      final DateTime? created = timestampToDate(data['createdAt']);
      if (pick == null ||
          (created != null &&
              (pickAt == null || created.isBefore(pickAt)))) {
        pick = <String, dynamic>{'id': doc.id, ...data};
        pickAt = created;
      }
    }
    if (pick == null) {
      return null;
    }
    return _hydrateStaffNote(pick);
  }

  Future<Map<String, dynamic>> _hydrateStaffNote(
    Map<String, dynamic> note,
  ) async {
    final String? fromUserId = note['fromUserId']?.toString();
    if (fromUserId != null && fromUserId.isNotEmpty) {
      try {
        final DocumentSnapshot<Map<String, dynamic>> fromDoc = await _db
            .collection(FirestorePaths.users)
            .doc(fromUserId)
            .get();
        if (fromDoc.exists) {
          final Map<String, dynamic> fromUser = mapUserDoc(fromDoc);
          note['fromUser'] = fromUser;
          final String profileName =
              fromUser['fullName']?.toString().trim() ?? '';
          if (profileName.isNotEmpty &&
              (note['fromUserName']?.toString().trim().isEmpty ?? true)) {
            note['fromUserName'] = profileName;
          }
        }
      } on FirebaseException {
        // fallback: fromUserName المخزّن مع الملاحظة
      }
    }
    final String cachedName = note['fromUserName']?.toString().trim() ?? '';
    if (cachedName.isNotEmpty && note['fromUser'] is! Map<String, dynamic>) {
      note['fromUser'] = <String, dynamic>{'fullName': cachedName};
    }
    final DateTime? created = timestampToDate(note['createdAt']);
    if (created != null) {
      note['createdAt'] = created;
    }
    return note;
  }

  Future<Map<String, dynamic>?> getPendingStaffNoteForMe() async {
    final UserEntity user = await _auth.loadCurrentUser();
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestorePaths.staffNotes)
        .where('toUserId', isEqualTo: user.id)
        .get();
    return _selectPendingStaffNote(snap.docs);
  }

  Stream<Map<String, dynamic>?> watchPendingStaffNoteForMe() {
    return Stream.fromFuture(_auth.loadCurrentUser()).asyncExpand(
      (UserEntity user) => _db
          .collection(FirestorePaths.staffNotes)
          .where('toUserId', isEqualTo: user.id)
          .snapshots()
          .asyncMap(
            (QuerySnapshot<Map<String, dynamic>> snap) =>
                _selectPendingStaffNote(snap.docs),
          ),
    );
  }

  Future<void> markStaffNoteRead(String noteId) async {
    final UserEntity user = await _auth.loadCurrentUser();
    final DocumentReference<Map<String, dynamic>> ref =
        _db.collection(FirestorePaths.staffNotes).doc(noteId);
    final DocumentSnapshot<Map<String, dynamic>> doc = await ref.get();
    if (!doc.exists || doc.data()?['toUserId'] != user.id) {
      return;
    }
    await ref.update(<String, dynamic>{
      'readAt': serverTimestamp(),
    });
  }
}
