#!/usr/bin/env bash
# APK con dart_defines.local.json. Por defecto DEBUG; release: RELEASE=1 ./scripts/build_android.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DEF="$ROOT/dart_defines.local.json"
if [[ ! -f "$DEF" ]]; then
  DEF="$ROOT/dart_defines.example.json"
  echo "Aviso: no hay dart_defines.local.json; usando dart_defines.example.json" >&2
fi

if [[ "${RELEASE:-}" == "1" ]]; then
  flutter build apk --dart-define-from-file="$DEF" "$@"
else
  flutter build apk --debug --dart-define-from-file="$DEF" "$@"
fi
