# Device Setup — Law Admissions HQ Native

## Mac + iPad setup order
1. Install full Xcode on your Mac.
2. Install XcodeGen.
3. Run `./scripts/prepare_native_project.sh`.
4. Open the generated project in Xcode.
5. Set your Apple Development Team for both targets.
6. Enable iCloud + CloudKit.
7. Build once for Mac.
8. Build once for iPad.
9. In Settings, add your OpenAI API key if you want AI features.
10. Use Settings → Build Backup JSON before major edits.

## Suggested first-device workflow
- Open onboarding.
- Pick light or dark mode.
- Pick standard or premium icon.
- Confirm the seeded demo workspace loads.
- Test one AI review call.
- Export a backup JSON.
