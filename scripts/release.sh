#!/usr/bin/env bash
# Builds Cairn.app (Release, ad-hoc signed), packs it in a DMG and attaches it to the GitHub Release of the current tag.
# Usage: git checkout vX.Y.Z && scripts/release.sh
set -euo pipefail
cd "$(dirname "$0")/.."

tag=$(git describe --tags --exact-match) || { echo "HEAD n'est pas sur un tag de release (git checkout vX.Y.Z)" >&2; exit 1; }
version=${tag#v}
[[ -z $(git status --porcelain) ]] || { echo "Arbre de travail non propre" >&2; exit 1; }

out=build/release
rm -rf "$out"
xcodegen generate
xcodebuild -project Cairn.xcodeproj -scheme Cairn -configuration Release -destination 'platform=macOS' \
  -derivedDataPath "$out" CURRENT_PROJECT_VERSION="$(git rev-list --count HEAD)" build

app="$out/Build/Products/Release/Cairn.app"
built=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist")
[[ $built == "$version" ]] || { echo "Version de l'app ($built) ≠ tag ($version)" >&2; exit 1; }

stage="$out/dmg"
mkdir -p "$stage"
cp -R "$app" "$stage/"
ln -s /Applications "$stage/Applications"
dmg="$out/Cairn-$version.dmg"
diskutil image create from --volumeName "Cairn $version" "$stage" "$dmg"

gh release upload "$tag" "$dmg" --clobber
echo "✓ $dmg attaché à la release $tag"
