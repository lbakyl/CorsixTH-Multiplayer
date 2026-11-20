#!/usr/bin/env bash
# Give apt on Ubuntu (GitHub's runners, a clean ubuntu:24.04 container) a
# list of independent mirrors to try in order, and make it move on when one
# fails or sends nothing for 20 seconds. On 2026-11-19 Canonical's servers
# failed GitHub's runners all day: GitHub's own mirror answered "503 Service
# Unavailable" and archive.ubuntu.com and security.ubuntu.com sent 20 kB/s,
# so a Linux build waited for an hour or gave up.
#
# GitHub's runners already read their mirrors from a list
# (mirror+file:/etc/apt/apt-mirrors.txt); ours go in front of its entries.
# Elsewhere archive.ubuntu.com and security.ubuntu.com are replaced by a list
# of ours. The mirrors carry every pocket (-security too) and Ubuntu 26.04's
# amd64v3 packages; a file one of them lacks comes from the next.
# Run before `apt-get update`, as root or with sudo.
set -euo pipefail
sudo=""
if [ "$(id -u)" != 0 ]; then sudo=sudo; fi

ours="http://mirrors.edge.kernel.org/ubuntu/
http://mirrors.mit.edu/ubuntu/
http://mirror.us.leaseweb.net/ubuntu/
http://mirror.math.princeton.edu/pub/ubuntu/
http://archive.ubuntu.com/ubuntu/"

sources=""
for f in /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list; do
  if [ -f "$f" ]; then sources="$sources $f"; fi
done

github=/etc/apt/apt-mirrors.txt
# shellcheck disable=SC2086
if [ -n "$sources" ] && grep -qs "mirror+file:$github" $sources; then
  list=$github
else
  list=/etc/apt/openth-mirrors.txt
  for f in $sources; do
    $sudo sed -i -E "s#https?://([a-z0-9.-]*\.)?(archive|security)\.ubuntu\.com/ubuntu/?#mirror+file:$list#g" "$f"
  done
fi

# Ours first, then whatever the list had (GitHub's own mirrors), once each,
# each with its own priority: apt tries the lowest first and shuffles mirrors
# of equal priority, which would send some files to a failing one.
old=""
if [ -f "$list" ]; then old=$(cut -f1 "$list" | sed 's#/*$#/#'); fi
printf '%s\n%s\n' "$ours" "$old" |
  awk 'NF && !seen[$1]++ {n++; printf "%s\tpriority:%d\n", $1, n}' | $sudo tee "$list.new" > /dev/null
$sudo mv "$list.new" "$list"

printf '%s\n' 'Acquire::http::Timeout "20";' 'Acquire::https::Timeout "20";' 'Acquire::Retries "3";' |
  $sudo tee /etc/apt/apt.conf.d/80openth-mirrors > /dev/null
echo "apt mirrors ($list):"
cat "$list"
