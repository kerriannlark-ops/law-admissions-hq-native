#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$ROOT/../law-admissions-native-github-$STAMP.zip"

swiftc -parse Sources/*.swift
zip -r "$OUT" . \
  -x "*.DS_Store" \
  -x "build/*" \
  -x "DerivedData/*" \
  -x "*.xcodeproj/project.xcworkspace/*" \
  -x "*.xcodeproj/xcuserdata/*" \
  -x "*.xcuserstate"

echo "Created GitHub-ready archive: $OUT"
