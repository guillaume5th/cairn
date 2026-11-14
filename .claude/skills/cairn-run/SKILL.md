---
name: cairn-run
description: Build and launch Cairn Dev, bring its window on screen, screenshot it, click through it and inspect accessibility, to check a UI change in the real app. Use when the user asks to run, launch, screenshot, "vérifie toi-même", or to confirm a UI change works.
---

# Run and inspect Cairn Dev

Answer the user in French. Cairn Dev (Debug build, bundle `dev.cairn.Cairn.debug`, orange icon) is a separate app with
its own library: its data is disposable, destructive paths can be tested freely. Never touch the installed `Cairn.app`.

Scratchpad screenshots: use the session scratchpad directory, below written as `$S`.

## 1. Build and launch
```sh
xcodegen -q && xcodebuild -scheme Cairn -destination 'platform=macOS' -derivedDataPath build build 2>&1 | grep -E "error:|BUILD" | tail -5
pkill -f "Cairn Dev.app"; open "build/Build/Products/Debug/Cairn Dev.app"
```
Foreground `sleep` is blocked; a short `sleep 2`-`sleep 4` inside a compound command is fine.

## 2. Bring the window on screen
The window often opens on the secondary display (y around 2000), so a capture of the main screen misses it, and
`screencapture -l <window id>` fails ("could not create image from window"). Move it, then capture its rectangle:
```sh
osascript -e 'tell application "System Events" to tell process "Cairn Dev" to set position of window 1 to {200, 80}' \
          -e 'tell application "Cairn Dev" to activate'
osascript -e 'tell application "System Events" to tell process "Cairn Dev" to get size of window 1'   # w, h
screencapture -x -R200,80,<w>,<h> $S/shot.png && sips -Z 1600 $S/shot.png --out $S/shot.png
```
Then Read the png. Capture only the part you need (e.g. `-R200,80,1400,500`) and resize so image pixels match screen
points: `sips -Z <w>` on a capture `<w>` points wide gives a 1:1 mapping, so click coordinates = 200 + x, 80 + y.

## 3. Interact
- Click: `osascript -e 'tell application "System Events" to click at {x, y}'` (screen points). Clicks on buttons and
  disclosure triangles work; clicks on article-list rows did not change the selection, so prefer an article already
  shown, the keyboard (`key code`), or menu items via System Events.
- Settings written with `@AppStorage`: `defaults read dev.cairn.Cairn.debug <key>` (e.g. `articleSummaryHidden`).
- Accessibility (what VoiceOver gets): list a container's elements with
  `get {role, description, value} of every UI element of <container>`; find the container path from the result of a
  `click at`, which returns the element it hit.

## 4. Report
A table: each point checked, result (✅/❌), how it was checked. List what could not be checked (e.g. no data in
Cairn Dev for that case) and any side effect (window moved, data regenerated).
