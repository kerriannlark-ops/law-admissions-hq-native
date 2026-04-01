# Local-Only Setup — No CloudKit, No AI

## Best path
Use the app as a normal local SwiftUI app on your Mac and iPad.

You do **not** need to enable:
- iCloud
- CloudKit
- OpenAI API

## What still works
- Dashboard
- Dossier workspace
- Essays
- Resume + Addendum
- Interview + Recs
- School Strategy
- Prompt Studio
- Sources + Method
- Demo workspace
- Backup / restore JSON
- Theme, icon, and settings

## What to skip
### In Xcode
Skip these entirely:
- iCloud capability
- CloudKit capability
- any container setup

### In the app
Skip this unless you want paid AI later:
- adding an OpenAI API key in Settings
- Analyze with AI actions

## Startup steps
1. Install full Xcode.
2. From Terminal:
   ```bash
   cd /Users/kerriannlark/Documents/Playground/law-admissions-native
   ./scripts/prepare_native_project.sh
   ```
3. Open `LawAdmissionsHQNative.xcodeproj` in Xcode.
4. For both app targets, choose your Apple Development Team.
5. Run `LawAdmissionsHQ-Mac` on My Mac.
6. Run `LawAdmissionsHQ-iPad` on an iPad simulator or connected iPad.

## If Xcode asks about capabilities
Do the minimum:
- keep signing automatic
- choose your team
- do not add new capabilities

## If you want sync or AI later
You can add them later:
- CloudKit/iCloud = Apple Developer Program path
- AI = OpenAI API key path
