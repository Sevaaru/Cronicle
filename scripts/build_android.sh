#!/usr/bin/env bash
# flutter build apk con dart_defines.local.json (o .example si no existe).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DEF="$ROOT/dart_defines.local.json"
if [[ ! -f "$DEF" ]]; then
  DEF="$ROOT/dart_defines.example.json"
  echo "Aviso: no hay dart_defines.local.json; usando dart_defines.example.json" >&2
fi

flutter build apk --dart-define-from-file="$DEF" "$@"
