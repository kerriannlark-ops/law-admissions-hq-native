#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== Law Admissions HQ Native setup =="
echo "Mode: local-only (no CloudKit required, no AI required)"
echo

if command -v xcodegen >/dev/null 2>&1; then
  echo "Using installed XcodeGen binary..."
  xcodegen generate
elif [ -d "$ROOT/XcodeGen" ] && command -v swift >/dev/null 2>&1; then
  echo "No global XcodeGen install found. Using bundled XcodeGen source..."
  (
    cd "$ROOT/XcodeGen"
    swift run xcodegen generate --spec "$ROOT/project.yml" --project "$ROOT"
  )
else
  echo "XcodeGen is not available yet."
  echo "Best fix: install full Xcode, then either:"
  echo "  1. install xcodegen globally, or"
  echo "  2. keep the bundled XcodeGen folder and rerun this script"
  echo
  echo "Project spec is ready at: $ROOT/project.yml"
  exit 1
fi

echo
if command -v open >/dev/null 2>&1; then
  echo "Generated Xcode project."
  echo "Open it with: open \"$ROOT/LawAdmissionsHQNative.xcodeproj\""
else
  echo "Generated Xcode project at: $ROOT/LawAdmissionsHQNative.xcodeproj"
fi

echo
cat <<'STEPS'
Local-only Xcode checklist:
1. Open LawAdmissionsHQNative.xcodeproj in Xcode.
2. Set your Apple Development Team for both app targets.
3. Do NOT add iCloud or CloudKit.
4. Build and run LawAdmissionsHQ-Mac first.
5. Build and run LawAdmissionsHQ-iPad second.
6. Skip API key setup if you want no-AI mode.
7. Use the app's built-in rule-based tools, backup/restore, and demo workspace locally.
STEPS
