/// تحويل أرقام عربية / فارسية / عرض كامل إلى ASCII (٠–٩ → 0–9).
String digitsToAsciiLatin(String input) {
  final StringBuffer b = StringBuffer();
  for (final int r in input.runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      b.writeCharCode(0x30 + (r - 0x0660));
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      b.writeCharCode(0x30 + (r - 0x06F0));
    } else if (r >= 0xFF10 && r <= 0xFF19) {
      b.writeCharCode(0x30 + (r - 0xFF10));
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

/// يزيل مسافات اتجاهية وعلامات عرض شائعة قد تلصق بالأرقام من لوحة عربية.
String stripBidiAndFormatMarks(String s) {
  return s.replaceAll(
    RegExp(r'[\u200B-\u200F\u202A-\u202E\u2066-\u2069]'),
    '',
  );
}

/// يحلّل حقل كمية (تحميل/بيع): يدعم الأرقام العربية والفارسية.
/// - نص فارغ بعد `trim` → `null` (المستدعي يتعامل مع «تخطي الصف»).
/// - `0` أو أقل بعد التحليل → يعاد الرقم (المستدعي يتخطى إن ≤ 0).
/// - غير صالح → `null` ويُفترض أن المستدعي يعرض خطأ.
int? parseLoosePositiveIntField(String raw) {
  final String trimmed = stripBidiAndFormatMarks(raw.trim());
  if (trimmed.isEmpty) {
    return null;
  }
  final String noSpace = trimmed.replaceAll(RegExp(r'\s'), '');
  final String ascii = digitsToAsciiLatin(noSpace);
  final String forInt = ascii
      .replaceAll(',', '')
      .replaceAll('٬', '')
      .replaceAll("'", '');
  final int? direct = int.tryParse(forInt);
  if (direct != null) {
    return direct;
  }
  final String forDouble =
      ascii.replaceAll('٫', '.').replaceAll(',', '.');
  final double? d = double.tryParse(forDouble);
  if (d == null) {
    return null;
  }
  final int r = d.round();
  if ((d - r).abs() > 1e-9) {
    return null;
  }
  return r;
}
