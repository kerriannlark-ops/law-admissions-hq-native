# GitHub Publish Guide — Law Admissions HQ Native

## Recommended repo contents
- `Sources/`
- `Assets.xcassets/`
- `Tests/`
- `project.yml`
- `README.md`
- `.gitignore`
- `.github/workflows/swift-syntax-check.yml`
- `scripts/`
- `docs/`
- `SampleData/`

## Publish order
1. Create a new GitHub repository.
2. Copy this folder into the repo root.
3. Commit everything except generated Xcode user data.
4. Push to GitHub.
5. Use the included workflow to verify Swift syntax on every push.

## After push
- Generate the Xcode project locally with XcodeGen.
- Do signing and CloudKit in your private local environment, not in GitHub.
