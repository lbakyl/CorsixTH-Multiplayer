#!/usr/bin/env bash
# Make apt on Ubuntu (GitHub's runners, a clean ubuntu:24.04 container) take
# the next mirror when one fails or sends nothing for 20 seconds, instead of
# waiting: GitHub's own mirror (us-east-2.ec2.archive.ubuntu.com) hung the
# Linux builds for an hour more than once. Run before `apt-get update`, as
# root or with sudo. The security pocket keeps its own server.
set -euo pipefail
sudo=""
if [ "$(id -u)" != 0 ]; then sudo=sudo; fi

list=/etc/apt/openth-mirrors.txt
printf '%s\n' \
  "http://archive.ubuntu.com/ubuntu/" \
  "http://mirrors.edge.kernel.org/ubuntu/" \
  "http://azure.archive.ubuntu.com/ubuntu/" | $sudo tee "$list" > /dev/null
for f in /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list; do
  if [ -f "$f" ]; then
    $sudo sed -i -E "s#https?://([a-z0-9.-]*\.)?archive\.ubuntu\.com/ubuntu/?#mirror+file:$list#g" "$f"
  fi
done
printf '%s\n' 'Acquire::http::Timeout "20";' 'Acquire::Retries "3";' |
  $sudo tee /etc/apt/apt.conf.d/80openth-mirrors > /dev/null
grep -h -E "^(URIs:|deb )" /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list 2>/dev/null || true
