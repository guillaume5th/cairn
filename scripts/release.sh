#!/usr/bin/env bash
# Builds Cairn.app (Release, ad-hoc signed), packs it in a DMG and attaches it to the GitHub Release of the current tag,
# with the Sparkle appcast that announces it (signed with the EdDSA key of this Mac's keychain).
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

# The app reads releases/latest/download/appcast.xml: each release carries the appcast of its own version.
build=$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$app/Contents/Info.plist")
signature=$("$out/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update" "$dmg")
repo=https://github.com/guillaume5th/cairn
cat > "$out/appcast.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Cairn</title>
    <item>
      <title>Cairn $version</title>
      <pubDate>$(LC_ALL=C date -R)</pubDate>
      <sparkle:version>$build</sparkle:version>
      <sparkle:shortVersionString>$version</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>27.0</sparkle:minimumSystemVersion>
      <sparkle:fullReleaseNotesLink>$repo/releases/tag/$tag</sparkle:fullReleaseNotesLink>
      <enclosure url="$repo/releases/download/$tag/Cairn-$version.dmg" type="application/octet-stream" $signature/>
    </item>
  </channel>
</rss>
EOF

gh release upload "$tag" "$dmg" "$out/appcast.xml" --clobber
echo "✓ $dmg et appcast.xml attachés à la release $tag"
