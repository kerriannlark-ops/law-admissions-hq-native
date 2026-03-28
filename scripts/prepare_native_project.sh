#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "== Law Admissions HQ Native setup =="

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen is not installed. Install it first, then rerun this script."
  echo "Project spec is ready at: $ROOT/project.yml"
  exit 1
fi

xcodegen generate

echo
if command -v open >/dev/null 2>&1; then
  echo "Generated Xcode project."
  echo "Open it with: open \"$ROOT/LawAdmissionsHQNative.xcodeproj\""
else
  echo "Generated Xcode project at: $ROOT/LawAdmissionsHQNative.xcodeproj"
fi

echo
cat <<'STEPS'
Final Xcode checklist:
1. Set your Apple Development Team for both targets.
2. Confirm bundle identifiers.
3. Enable iCloud + CloudKit capabilities.
4. Verify AppIcon is the primary app icon.
5. Keep PremiumAppIcon as the alternate/premium asset set for final packaging.
6. Run once on Mac, then once on iPad.
STEPS
