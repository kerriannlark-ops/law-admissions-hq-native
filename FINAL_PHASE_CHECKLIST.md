# Final Phase Checklist — Law Admissions HQ Native

## Build + Signing
- [ ] Install full Xcode
- [ ] Install XcodeGen
- [ ] Run `scripts/prepare_native_project.sh`
- [ ] Set Apple Development Team for Mac + iPad targets
- [ ] Confirm bundle IDs

## CloudKit / iCloud
- [ ] Enable iCloud capability in Xcode
- [ ] Enable CloudKit container
- [ ] Confirm SwiftData sync works on Mac and iPad

## App Polish
- [x] ADHD-friendly color system
- [x] Times New Roman typography layer
- [x] Standard app icon
- [x] Premium icon variant asset
- [x] Onboarding screen
- [x] Settings preview for theme, font, and icon direction

## AI Layer
- [ ] Add personal OpenAI API key in Settings
- [ ] Test streaming review in each section
- [x] Add graceful offline message checks

## Data Protection
- [x] Backup / restore JSON workflow added
- [x] Demo workspace reseed controls added

## Final Packaging
- [x] Runtime alternate-icon preference support added
- [ ] Validate layout on Mac windowed mode
- [ ] Validate layout on iPad split view
- [ ] Review CloudKit entitlements and signing one last time
