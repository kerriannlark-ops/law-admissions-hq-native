# Law Admissions HQ Native

A personal-use **SwiftUI law school admissions workspace** for **macOS + iPadOS**.

Built to help you manage your entire law admissions workflow in one native Apple app:
- school strategy
- dossier management
- personal statement revision
- resume + addendum review
- interview prep
- prompt generation
- AI-assisted analysis

---

## Why this app exists
Law Admissions HQ Native is designed as a focused admissions operating system for a real applicant workflow — especially for part-time, hybrid, online-friendly, and Ohio-centered law school planning.

It combines:
- **rule-based admissions coaching**
- **native local-first storage**
- **optional OpenAI-powered review**
- **iCloud / CloudKit-ready sync scaffolding**
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
- iCloud / CloudKit-ready entitlements scaffold
- Keychain-backed API key storage
- First-launch onboarding
- Settings previews for theme, icon, and typography
- Backup / restore JSON workflow
- Seeded demo workspace

### Visual system
- ADHD-friendly light + dark mode palette
- Times New Roman typography layer
- Standard app icon
- Premium alternate icon asset set

### AI layer
- OpenAI Responses API integration
- streaming text review support
- graceful offline / API-failure fallback messaging
- rule-based mode still works when AI is unavailable

---

## Project status
This project is **implementation-ready**, but final native Apple validation still requires:
- full Xcode
- XcodeGen
- Apple signing setup
- CloudKit capability enablement
- device testing on Mac + iPad

---

## Start here
```bash
cd /Users/kerriannlark/Documents/Playground/law-admissions-native
./scripts/prepare_native_project.sh
```

If `xcodegen` is not installed yet, the script will stop and tell you what is missing.

---

## Recommended repo name
**Best default:** `law-admissions-hq-native`

Strong alternatives:
- `law-admissions-hq-ios-mac`
- `law-school-dashboard-native`
- `law-admissions-workspace-apple`

---

## Publishing / setup docs
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

## OpenAI docs used for the AI scaffold
- https://developers.openai.com/api/reference/resources/responses/methods/create
- https://developers.openai.com/api/docs/guides/migrate-to-responses
- https://developers.openai.com/api/docs/guides/streaming-responses
