# BadgeThing

[![Latest release](https://img.shields.io/github/v/release/sgstq/badgething?display_name=tag&label=latest&sort=semver)](https://github.com/sgstq/badgething/releases/latest)
[![CI](https://github.com/sgstq/badgething/actions/workflows/ci.yml/badge.svg)](https://github.com/sgstq/badgething/actions/workflows/ci.yml)

Tiny macOS menu-bar app that mirrors Dock badges (e.g. Slack unread count) for any
app you pick. Single-purpose analog of [Badgeify](https://badgeify.app).

### Warning
<p align="center">
  <b>ALL CODE AND SCRIPTS IN THIS REPOSITORY—EVEN THOSE BASED ON REAL DOCUMENTATION—ARE ENTIRELY EXPERIMENTAL. ALL LOGIC WAS HALLUCINATED BY MATRIX MULTIPLICATIONS….. HAPHAZARDLY. THE FOLLOWING REPOSITORY CONTAINS UNTESTED CODE AND DUE TO ITS CONTENT IT SHOULD NOT BE USED ANYWHERE BY ANYONE ■</b>
</p>

## Install

**Download the latest DMG:** [BadgeThing.dmg](https://github.com/sgstq/badgething/releases/latest/download/BadgeThing.dmg)
([all releases](https://github.com/sgstq/badgething/releases))

### First run

1. Mount the DMG and drag **BadgeThing** to **Applications**.
2. Launch it. Until the app is notarized you'll see a Gatekeeper warning —
   open **System Settings → Privacy & Security**, scroll to the bottom,
   click **Open Anyway** next to BadgeThing.
3. Grant **Accessibility** permission when prompted
   (System Settings → Privacy & Security → Accessibility).
   This is what lets BadgeThing read Dock badges.
4. Click the **+ Badge** menu-bar item → pick Slack (or any /Applications app).

### Usage

- **Left-click** the menu-bar icon → activates the app.
- **Right-click** → menu with badge style (dot / count), add another app,
  launch-at-login, remove from menu bar, quit.

## Build from source

Requires macOS 13+ and the Swift toolchain (Xcode or Command Line Tools).

```bash
git clone git@github.com:sgstq/badgething.git
cd badgething
./release.sh          # produces BadgeThing.app and BadgeThing.dmg
open BadgeThing.app
```

For a notarized build (requires an Apple Developer ID, $99/yr):

```bash
xcrun notarytool store-credentials "badgething" \
    --apple-id "you@example.com" \
    --team-id  "YOUR_TEAM_ID" \
    --password "app-specific-password"

export DEVELOPER_ID_APP="Developer ID Application: Your Name (TEAMID)"
export NOTARY_PROFILE="badgething"
./release.sh
```

## Releases

Releases are cut **automatically** when a PR is merged to `main`. The version
is bumped according to the PR's labels:

| Label         | Result                |
|---------------|-----------------------|
| _(none)_      | Patch bump (default)  |
| `bump:minor`  | Minor bump            |
| `bump:major`  | Major bump            |
| `bump:skip`   | No release            |

The workflow computes the next version from the latest `v*` tag, builds the
DMG, and uploads it to a fresh GitHub Release with auto-generated notes.

Manual triggers:

- **Push a tag** (`git tag v0.4.0 && git push --tags`) — releases that exact version.
- **Actions → Release → Run workflow** — manual run with a bump-kind selector.

### Configuring notarized releases in CI

When you have an Apple Developer ID, add these repo secrets
([settings/secrets/actions](https://github.com/sgstq/badgething/settings/secrets/actions)):

| Secret                                | Value                                                    |
|---------------------------------------|----------------------------------------------------------|
| `DEVELOPER_ID_APP_CERT_P12_BASE64`    | `base64 -i cert.p12` of the .p12 exported from Keychain  |
| `DEVELOPER_ID_APP_CERT_PASSWORD`      | Password used when exporting that .p12                   |
| `DEVELOPER_ID_APP_IDENTITY`           | `Developer ID Application: Your Name (TEAMID)`           |
| `APPLE_ID`                            | Your Apple ID email                                      |
| `APPLE_TEAM_ID`                       | 10-character Team ID                                     |
| `APPLE_APP_SPECIFIC_PASSWORD`         | From [appleid.apple.com](https://appleid.apple.com)      |

The workflow detects them automatically — no edits needed. From the next
release onward, the DMG is notarized and installs without Gatekeeper warnings.
