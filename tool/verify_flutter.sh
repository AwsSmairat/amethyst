#!/usr/bin/env bash
# فحص تطبيق Flutter/Dart محلياً (مكافئ لما يُنصح به في CI).
# الاستخدام: من جذر المشروع: bash tool/verify_flutter.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "== flutter pub get =="
flutter pub get

echo "== flutter analyze =="
flutter analyze

echo "== flutter test =="
flutter test

if [[ "${CHECK_FORMAT:-0}" == "1" ]]; then
  echo "== dart format (CHECK_FORMAT=1) =="
  dart format --output=none --set-exit-if-changed lib test
fi

echo "== تم الفحص بنجاح =="
echo "اختياري: CHECK_FORMAT=1 bash tool/verify_flutter.sh للتحقق من التنسيق"
