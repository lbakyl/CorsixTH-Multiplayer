"""A new release on Discord: its name, what is new in it (the "New since"
part of the release notes), the platforms it has and where to play it,
posted to a Discord webhook when a release is published
(.github/workflows/discord-release.yml).

    python -m corsixth_mp.release_post --tag mp-test-03fbbe02 [--repo owner/name] [--dry-run]

The webhook is DISCORD_RELEASES_WEBHOOK (a repository secret; never in a log).
Without it nothing is posted and the run still succeeds, so a fork or a
repository without the secret does not fail. GITHUB_TOKEN (or GH_TOKEN), if
set, is used to read the release. --dry-run prints the message instead.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.request

DESCRIPTION_LIMIT = 4096  # Discord's limit for an embed's description
FIELD_LIMIT = 1024
TEST_COLOUR = 0xE8A33D
STABLE_COLOUR = 0x3BA55C
PLATFORMS = (("win64", "Windows"), ("linux", "Linux"), ("macos", "macOS"))


def fetch_release(repo: str, tag: str, token: str = "") -> dict:
    headers = {"Accept": "application/vnd.github+json", "User-Agent": "openth-release-post/1"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(f"https://api.github.com/repos/{repo}/releases/tags/{tag}",
                                     headers=headers)
    with urllib.request.urlopen(request, timeout=20) as response:
        return json.load(response)


def _section(body: str, heading: str) -> str:
    """The text of a paragraph that starts with **heading** (up to the next blank line)."""
    m = re.search(r"^\*\*" + re.escape(heading) + r"[^\n]*", body, re.MULTILINE)
    if not m:
        return ""
    end = body.find("\n\n", m.start())
    return body[m.start():end if end >= 0 else len(body)].strip()


def whats_new(body: str) -> tuple[str, list[str]]:
    """The "New since ..." heading and its bullet points."""
    body = body.replace("\r\n", "\n")
    m = re.search(r"^\*\*(New since [^*]+)\*\*\s*\n", body, re.MULTILINE)
    if not m:
        return "", []
    bullets: list[str] = []
    for line in body[m.end():].split("\n"):
        if line.startswith("- "):
            bullets.append(line[2:].strip())
        elif line.startswith("  ") and bullets:
            bullets[-1] += " " + line.strip()
        elif line.strip():
            break
    return m.group(1).strip(), bullets


def summary(body: str) -> str:
    """The first sentence's theme: the words after "at <sha>:" in the first line."""
    first = body.replace("\r\n", "\n").split("\n", 1)[0]
    m = re.search(r"\bat [0-9a-f]{7,40}`?:\s*(.+)$", first)
    return m.group(1).strip() if m else ""


def where_to_play(body: str) -> str:
    """The **Play:** paragraph, without its links to the guides."""
    text = _section(body.replace("\r\n", "\n"), "Play:")
    text = re.sub(r"^\*\*Play:\*\*\s*", "", text)
    text = re.sub(r"\s*Full guide:.*$", "", text, flags=re.DOTALL).strip()
    return text[:1].upper() + text[1:]


def platforms(assets: list[dict]) -> str:
    names = [str(a.get("name", "")).lower() for a in assets]
    have = [label for key, label in PLATFORMS if any(key in n for n in names)]
    missing = [label for key, label in PLATFORMS if label not in have]
    text = ", ".join(have) if have else "none yet"
    if have and missing:
        text += " (" + ", ".join(missing) + " still being built)"
    return text


def _clip(text: str, limit: int) -> str:
    return text if len(text) <= limit else text[:limit - 3].rstrip() + "..."


def message(release: dict) -> dict:
    """The Discord webhook payload for a release (GitHub's release JSON)."""
    body = release.get("body") or ""
    url = release.get("html_url", "")
    heading, bullets = whats_new(body)
    lines = []
    theme = summary(body)
    if theme:
        lines.append(theme[0].upper() + theme[1:])
    if heading:
        lines.append(f"\n**{heading}**")
    more = f"\n...and more in the [release notes]({url})."
    for bullet in bullets:
        line = "- " + bullet
        if len("\n".join(lines + [line])) + len(more) > DESCRIPTION_LIMIT:
            lines.append(more.strip())
            break
        lines.append(line)
    stable = not release.get("prerelease", False)
    fields = [{"name": "Download", "value": _clip(f"[{platforms(release.get('assets', []))}]({url})",
                                                   FIELD_LIMIT), "inline": False}]
    play = where_to_play(body)
    if play:
        fields.append({"name": "Play", "value": _clip(play, FIELD_LIMIT), "inline": False})
    kind = "stable" if stable else "test"
    embed = {
        "title": _clip(release.get("name") or release.get("tag_name", "New build"), 256),
        "url": url,
        "description": _clip("\n".join(lines), DESCRIPTION_LIMIT),
        "color": STABLE_COLOUR if stable else TEST_COLOUR,
        "fields": fields,
    }
    if release.get("published_at"):
        embed["timestamp"] = release["published_at"]
    return {
        "username": "OpenTH builds",
        "content": f"New multiplayer {kind} build: **{release.get('tag_name', '')}**",
        "embeds": [embed],
        "allowed_mentions": {"parse": []},
    }


def post(url: str, payload: dict) -> None:
    request = urllib.request.Request(url + ("&" if "?" in url else "?") + "wait=true",
                                     data=json.dumps(payload).encode("utf-8"), method="POST",
                                     headers={"Content-Type": "application/json",
                                              "User-Agent": "openth-release-post/1"})
    with urllib.request.urlopen(request, timeout=20) as response:
        response.read()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--tag", required=True, help="the release's tag, e.g. mp-test-03fbbe02")
    parser.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY", "openth-org/openth"))
    parser.add_argument("--dry-run", action="store_true", help="print the message, do not post it")
    args = parser.parse_args(argv)
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN") or ""
    payload = message(fetch_release(args.repo, args.tag, token))
    if args.dry_run:
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        return 0
    url = os.environ.get("DISCORD_RELEASES_WEBHOOK", "")
    if not url:
        print("DISCORD_RELEASES_WEBHOOK is not set: nothing posted")
        return 0
    try:
        post(url, payload)
    except (urllib.error.URLError, OSError) as exc:
        # (Never the URL: it is a secret.)
        print(f"posting failed: {exc.__class__.__name__}: {getattr(exc, 'code', '')}", file=sys.stderr)
        return 1
    print(f"{args.tag} posted")
    return 0


if __name__ == "__main__":
    sys.exit(main())
