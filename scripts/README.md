# Scripts

> **Read this first.** Before every QA build: bump `pubspec.yaml` version.

## Version bump (required before QA builds)

```yaml
# pubspec.yaml
version: 1.0.5+6   # format: semver+buildNumber
```

Increment build number every release build. Increment semver on meaningful changes.

## Scripts

| Script | When to use |
|--------|-------------|
| `dev_run.sh` | Daily dev — debug build, hot reload, live logs |
| `qa_install.sh` | QA / release testing — release build, split-per-abi, auto-installs matching ABI |
| `phone_connect.sh` | Helper only — sourced by other scripts, don't run directly |

## Usage

```bash
# Dev (hot reload available)
bash scripts/dev_run.sh

# QA release (bump version first!)
bash scripts/qa_install.sh
```

## Requirements

- Phone connected via USB **or** reachable via Tailscale (Android)
- ADB in PATH
- For Tailscale: `C:\Program Files\Tailscale\tailscale.exe` present

## QA build checklist

1. Bump `pubspec.yaml` version
2. Run `flutter analyze` — fix all warnings
3. `bash scripts/qa_install.sh`
4. Copy output APK with versioned name (e.g. `app-1.0.5+6-arm64-release.apk`)
