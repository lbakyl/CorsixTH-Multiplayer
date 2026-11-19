#!/usr/bin/env bash
# Sign the macOS app in a zip made by build_macos_app.sh with a Developer ID
# certificate, have Apple notarize it and staple the ticket, so that players
# open it with a double click (no System Settings > Open Anyway). Used by
# .github/workflows/sign-macos.yml on GitHub's own Macs; the one-time setup
# is in docs/multiplayer/macos-signing.md.
#
# Usage: bash scripts/multiplayer/sign_macos_app.sh IN.zip OUT.zip
# Environment:
#   SIGN_IDENTITY  the certificate ("Developer ID Application: Name (TEAMID)"),
#                  or - to sign ad hoc (a test: nothing goes to Apple)
#   SIGN_KEYCHAIN  the keychain that holds it (optional)
#   ENTITLEMENTS   an entitlements file for the program (optional; the game
#                  needs none, the ad hoc test needs library validation off)
#   NOTARY_KEY, NOTARY_KEY_ID, NOTARY_ISSUER
#                  App Store Connect API key (.p8 file, key id, issuer id);
#                  without NOTARY_KEY the app is signed but not notarized
# Every library, Lua module and program in the app gets the hardened runtime
# (Apple notarizes nothing without it) and, with a certificate, a secure
# timestamp, so the signature stays valid after the certificate expires.
set -euo pipefail
in=$1
mkdir -p "$(dirname "$2")"
out=$(cd "$(dirname "$2")" && pwd)/$(basename "$2")
id=${SIGN_IDENTITY:?SIGN_IDENTITY: a Developer ID identity, or - for ad hoc}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

ditto -x -k "$in" "$work/x"
app=$(find "$work/x" -maxdepth 3 -type d -name '*.app' | head -n 1)
if [[ -z "$app" ]]; then
  echo "No .app in $in"
  exit 1
fi
top=$(dirname "$app")
main=$app/Contents/MacOS/$(defaults read "$app/Contents/Info" CFBundleExecutable)

opts=(--force --options runtime --sign "$id")
if [[ $id == - ]]; then
  opts+=(--timestamp=none)
else
  opts+=(--timestamp)
fi
if [[ -n ${SIGN_KEYCHAIN:-} ]]; then
  opts+=(--keychain "$SIGN_KEYCHAIN")
fi

# Inside out: libraries and Lua modules, any other program, then the app
# (which signs its main program, with the entitlements).
find "$app" -type f \( -name '*.dylib' -o -name '*.so' \) -print0 |
  xargs -0 -n1 codesign "${opts[@]}"
while IFS= read -r -d '' f; do
  case $f in *.dylib | *.so | "$main") continue ;; esac
  if file -b "$f" | grep -q Mach-O; then
    codesign "${opts[@]}" "$f"
  fi
done < <(find "$app/Contents" -type f -perm -u+x -print0)
if [[ -n ${ENTITLEMENTS:-} ]]; then
  codesign "${opts[@]}" --entitlements "$ENTITLEMENTS" "$app"
else
  codesign "${opts[@]}" "$app"
fi
codesign --verify --strict --deep --verbose=2 "$app"
codesign --display --verbose=2 "$app" 2>&1 |
  grep -E "^(Authority|TeamIdentifier|Timestamp|CodeDirectory)" || true

if [[ $id != - && -n ${NOTARY_KEY:-} ]]; then
  # Apple checks a zip of the app; the ticket is then stapled to the app
  # itself, so that it opens without asking Apple (offline too).
  ditto -c -k --keepParent "$app" "$work/notarize.zip"
  xcrun notarytool submit "$work/notarize.zip" --key "$NOTARY_KEY" \
    --key-id "${NOTARY_KEY_ID:?NOTARY_KEY_ID}" --issuer "${NOTARY_ISSUER:?NOTARY_ISSUER}" \
    --wait --timeout 1h --output-format json > "$work/notary.json" || true
  cat "$work/notary.json"
  echo
  status=$(plutil -extract status raw -o - "$work/notary.json" 2>/dev/null || echo none)
  sub=$(plutil -extract id raw -o - "$work/notary.json" 2>/dev/null || echo "")
  if [[ $status != Accepted ]]; then
    echo "Apple did not notarize the app (status: $status)"
    if [[ -n "$sub" ]]; then
      xcrun notarytool log "$sub" --key "$NOTARY_KEY" --key-id "$NOTARY_KEY_ID" \
        --issuer "$NOTARY_ISSUER" || true
    fi
    exit 1
  fi
  xcrun stapler staple "$app"
  xcrun stapler validate "$app"
  spctl --assess --type execute --verbose=4 "$app"
  # The note for players no longer needs Open Anyway.
  readme=$top/README-MULTIPLAYER.txt
  if [[ -f "$readme" ]]; then
    perl -0pi -e 's/The app is not\nnotarized by Apple:.*?CorsixTH\.app\n/The app is signed and notarized by Apple: it opens with a double click.\n/s' "$readme"
  fi
else
  echo "Not notarized (ad hoc signature or no NOTARY_KEY)"
fi

rm -f "$out"
(cd "$(dirname "$top")" && ditto -c -k --keepParent "$(basename "$top")" "$out")
echo "Signed: $out"
