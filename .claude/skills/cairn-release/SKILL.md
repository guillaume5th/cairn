---
name: cairn-release
description: Publish a new Cairn version end to end - merge the release-please PR, wait for the tag, build the DMG and attach it with the Sparkle appcast. Use when the user asks to release, publish a version, ship, or "générer la release / le DMG".
model: sonnet
---

# Release Cairn

Answer the user in French (keep git/GitHub terms in English). Every `gh` call needs the personal account:
`export GH_TOKEN=$(gh auth token --user guillaume5th)` (the active gh account is the work one and cannot see the repo).
Foreground `sleep` is blocked: wait with `gh run watch <id> --exit-status`.

## 1. Preconditions
- `git status --short` is empty and the branch is `main`, up to date with `origin/main` (`git pull`).
- Unpushed commits on `main`: push them (`git push origin main`), then wait for the `release-please` run they trigger.

## 2. Release PR
- `gh pr list --state open --label "autorelease: pending" --json number,title`.
- None: release-please only releases `feat`/`fix` (and `!`). If only `refactor`/`docs`/`chore` landed since the last tag,
  ask the user which version to force, then push an empty commit with a `Release-As: X.Y.Z` footer:
  `git commit --allow-empty -m "chore: release X.Y.Z" -m "Release-As: X.Y.Z"` (plus the attribution trailer), push,
  and wait for the run. Never invent a version without asking.
- Review `gh pr diff <n>`: only `.release-please-manifest.json`, `CHANGELOG.md` and `MARKETING_VERSION` in `project.yml`
  change, all to the same version. Anything else: stop and report.

## 3. Merge and tag
- `gh pr merge <n> --squash --delete-branch`.
- The merge triggers a new `release-please` run; it can take a few seconds to appear. Get its id with
  `gh run list --limit 3` (title `chore(main): release X.Y.Z (#n)`), then `gh run watch <id> --exit-status`.
- `gh release view vX.Y.Z` must succeed.

## 4. DMG
- `git pull && git checkout vX.Y.Z`
- `GH_TOKEN=... scripts/release.sh` (timeout 600000; output is huge: keep only the tail). It builds Release, makes
  `build/release/Cairn-X.Y.Z.dmg`, signs the appcast with the EdDSA key from the keychain and uploads both.
  A keychain prompt may appear on the user's screen: tell them if the script seems stuck.

## 5. Verify, then back to main
```sh
gh release view vX.Y.Z --json assets -q '.assets[] | "\(.name) \(.size)"'   # DMG + appcast.xml
m=$(diskutil image attach --mountOptions nobrowse --readOnly build/release/Cairn-X.Y.Z.dmg | tail -1 | cut -f3)
codesign --verify --deep --strict "$m/Cairn.app" && /usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$m/Cairn.app/Contents/Info.plist"
hdiutil detach -quiet "$m"
git checkout main
```
If `diskutil image attach` is unavailable, fall back to `hdiutil attach -nobrowse -readonly`.

Report: release URL, asset sizes, codesign result. Say plainly that the installed app and the Sparkle update were not
launched (v2.3.1 fixed a DMG launch crash: offer to launch the mounted app if the user wants that check).
