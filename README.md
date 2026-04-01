# Law Admissions HQ Native

A personal-use **SwiftUI law school admissions workspace** for **macOS + iPadOS**.

Built to help you manage your entire law admissions workflow in one native Apple app:
- school strategy
- dossier management
- personal statement revision
- resume + addendum review
- interview prep
- prompt generation
- optional AI-assisted analysis

---

## START HERE
### Free local mode
You can use this app **without CloudKit and without AI**.

That means:
- no iCloud setup required
- no OpenAI API key required
- local SwiftData storage still works
- rule-based admissions tools still work
- backup / restore JSON still works

Run:
```bash
cd /Users/kerriannlark/Documents/Playground/law-admissions-native
./scripts/prepare_native_project.sh
```

Then in Xcode:
1. open `LawAdmissionsHQNative.xcodeproj`
2. set your Apple Development Team for both app targets
3. **do not add CloudKit or iCloud**
4. run `LawAdmissionsHQ-Mac`
5. run `LawAdmissionsHQ-iPad`

Detailed setup:
- `docs/LOCAL_ONLY_SETUP.md`
- `docs/DEVICE_SETUP.md`

---

## Why this app exists
Law Admissions HQ Native is designed as a focused admissions operating system for a real applicant workflow — especially for part-time, hybrid, online-friendly, and Ohio-centered law school planning.

It combines:
- **rule-based admissions coaching**
- **native local-first storage**
- **optional OpenAI-powered review**
- **optional iCloud / CloudKit-ready expansion path**
- **ADHD-friendly visual design**

---

## Core features

### Admissions workspace
- Dashboard
- Dossier workspace
- Essays
- Resume + Addendum
- Interview + Recs
- School Strategy
- Prompt Studio
- Sources + Method

### Native app features
- SwiftUI shared codebase for **Mac + iPad**
- SwiftData models for profile, dossier, schools, prompts, AI reviews, and tasks
- local-first storage
- Keychain-backed API key storage for optional AI
- First-launch onboarding
- Settings previews for theme, icon, and typography
- Backup / restore JSON workflow
- Seeded demo workspace

### Visual system
- ADHD-friendly light + dark mode palette
- Times New Roman typography layer
- Standard app icon
- Premium alternate icon asset set

### Optional AI layer
- OpenAI Responses API integration
- streaming text review support
- graceful offline / API-failure fallback messaging
- app remains usable when AI is unavailable or unset

---

## Project status
This project is **implementation-ready** for local use.

To use advanced Apple/cloud features later, you may still want:
- Apple signing setup
- optional iCloud / CloudKit capability enablement
- optional OpenAI API setup
- device testing on Mac + iPad

---

## Recommended repo name
**Best default:** `law-admissions-hq-native`

Strong alternatives:
- `law-admissions-hq-ios-mac`
- `law-school-dashboard-native`
- `law-admissions-workspace-apple`

---

## Publishing / setup docs
- `docs/LOCAL_ONLY_SETUP.md`
- `docs/DEVICE_SETUP.md`
- `docs/GITHUB_PUBLISH.md`
- `docs/REPO_NAME_AND_RELEASE_PLAN.md`
- `RELEASE_NOTES.md`
- `FINAL_PHASE_CHECKLIST.md`

---

## GitHub-ready extras
- `.github/workflows/swift-syntax-check.yml`
- `scripts/package_github_repo.sh`
- `SampleData/demo-workspace-backup.json`

---

## OpenAI docs used for the optional AI scaffold
- https://developers.openai.com/api/reference/resources/responses/methods/create
- https://developers.openai.com/api/docs/guides/migrate-to-responses
- https://developers.openai.com/api/docs/guides/streaming-responses
