import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

final class FirebaseStorageService {
  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadExpenseReceipt({
    required String expenseId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final Reference ref = _storage.ref('expense_receipts/$expenseId/$filename');
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }
}
