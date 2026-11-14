#!/usr/bin/env bash
# Puts lpeg-1.1.0.tar.gz into vcpkg's downloads folder before vcpkg builds,
# from lpeg's own site or a distribution's mirror, and only the file vcpkg's
# lpeg port expects (its SHA-512). vcpkg takes a download already in that
# folder when the checksum matches, so a build no longer stops when lpeg's
# own site does not answer (www.inf.puc-rio.br was down for hours on
# 2026-11-14, and the build cache gave back no packages, so every build
# fetched every source again).
# Usage: bash ci_lpeg_mirror.sh <vcpkg downloads folder>
set -u
dir=${1:?usage: ci_lpeg_mirror.sh <vcpkg downloads folder>}
mkdir -p "$dir"
file="$dir/lpeg-1.1.0.tar.gz"
# (vcpkg's ports/lpeg/portfile.cmake at the baseline in vcpkg-configuration.json)
sha=01b2a4ceb2d110e143603bc63c84a59736ea735dd0ed9866286ba115d41be48d09c9ff21c8e2327974d2296944f6508d50a5c3a18f26ac1d81b8b2fc41f61222
if [ -f "$file" ] && [ "$(sha512sum "$file" | cut -d' ' -f1)" = "$sha" ]; then
  echo "lpeg: already in $dir"
  exit 0
fi
for url in \
    https://www.inf.puc-rio.br/~roberto/lpeg/lpeg-1.1.0.tar.gz \
    https://distfiles.macports.org/lpeg/lpeg-1.1.0.tar.gz \
    https://distcache.freebsd.org/ports-distfiles/lpeg-1.1.0.tar.gz \
    https://ftp.openbsd.org/pub/OpenBSD/distfiles/lpeg-1.1.0.tar.gz \
    https://deb.debian.org/debian/pool/main/l/lua-lpeg/lua-lpeg_1.1.0.orig.tar.gz; do
  if curl -fsSL --connect-timeout 10 -m 90 -o "$file.part" "$url" &&
      [ "$(sha512sum "$file.part" | cut -d' ' -f1)" = "$sha" ]; then
    mv "$file.part" "$file"
    echo "lpeg: from $url"
    exit 0
  fi
  echo "lpeg: not from $url"
done
rm -f "$file.part"
echo "lpeg: no copy with the right checksum; vcpkg tries lpeg's own site itself"
exit 0
