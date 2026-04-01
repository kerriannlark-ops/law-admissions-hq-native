# Device Setup — Law Admissions HQ Native

## Recommended setup order (free local mode)
1. Install full Xcode on your Mac.
2. Run `./scripts/prepare_native_project.sh`.
3. Open the generated project in Xcode.
4. Set your Apple Development Team for both targets.
5. Build once for Mac.
6. Build once for iPad.
7. Skip CloudKit.
8. Skip API key setup if you do not want AI.
9. Use Settings → Build Backup JSON before major edits.

## Suggested first-device workflow
- Open onboarding.
- Pick light or dark mode.
- Pick standard or premium icon.
- Confirm the seeded demo workspace loads.
- Use the local rule-based tools first.
- Export a backup JSON.

## Optional upgrades later
Only do these if you explicitly want them:
- add OpenAI API key for AI review
- add iCloud / CloudKit for sync
