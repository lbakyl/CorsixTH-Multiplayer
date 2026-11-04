"""The server's daily report to Discord: the games of a day (how many, how
long, people and bots) and what the bots' advice cost, from the files the
server keeps (stats.py), posted to a Discord webhook.

    python -m corsixth_mp.daily_report [--date YYYY-MM-DD] [--dry-run]

Without --date: yesterday (local day, CORSIXTH_MP_REPORT_TZ). The webhook is
DISCORD_WEBHOOK_URL (in /etc/corsixth-mp-secrets.env on a server; never in
a log). CORSIXTH_MP_SERVER_NAME names the server in the report (default:
the host's name). --dry-run prints the report instead of posting it.
A systemd timer runs it every morning (deploy/setup-referee-host.sh).
"""

from __future__ import annotations

import argparse
import datetime
import json
import os
import socket
import sys
import urllib.error
import urllib.request

from . import stats

MAX_GAMES_LISTED = 8
DISCORD_LIMIT = 2000


def _duration(seconds: float) -> str:
    minutes = int(round(seconds / 60))
    hours, minutes = divmod(minutes, 60)
    return f"{hours} h {minutes:02d} min" if hours else f"{minutes} min"


def games_of(day: str, env: dict[str, str] | None = None) -> list[dict]:
    """The games that ended on that local day."""
    folder = stats.stats_dir(env)
    path = folder / "games.jsonl" if folder else None
    games = []
    if path and path.is_file():
        for line in path.read_text(encoding="utf-8").splitlines():
            try:
                game = json.loads(line)
            except ValueError:
                continue
            if stats.local_day(float(game.get("ended", 0)), env) == day:
                games.append(game)
    return games


def advice_of(day: str, env: dict[str, str] | None = None) -> dict:
    folder = stats.stats_dir(env)
    path = folder / "ai-daily.json" if folder else None
    try:
        data = json.loads(path.read_text(encoding="utf-8")) if path and path.is_file() else {}
    except (OSError, ValueError):
        data = {}
    entry = data.get(day) or {}
    return {"usd": float(entry.get("usd", 0)), "answers": int(entry.get("answers", 0))}


def report(day: str, env: dict[str, str] | None = None) -> str:
    env = os.environ if env is None else env
    server = env.get("CORSIXTH_MP_SERVER_NAME") or socket.gethostname()
    games = games_of(day, env)
    advice = advice_of(day, env)
    when = datetime.date.fromisoformat(day).strftime("%a %d %b %Y")
    lines = [f"**{server}: {when}**"]
    if not games:
        lines.append("No games played.")
    else:
        total = sum(float(g["ended"]) - float(g["started"]) for g in games)
        longest = max(float(g["ended"]) - float(g["started"]) for g in games)
        people = {n.lower() for g in games for n in g.get("humans", [])}
        seats = sum(len(g.get("humans", [])) for g in games)
        bots = sum(len(g.get("bots", [])) for g in games)
        repairs = sum(int(g.get("repairs", 0)) for g in games)
        lines.append(f"Games: {len(games)}, {_duration(total)} in all (longest {_duration(longest)})")
        lines.append(f"Human players: {len(people)} different ({seats} in all games together)")
        lines.append(f"Bots: {bots}")
        if repairs:
            lines.append(f"Desync repairs: {repairs}")
    lines.append(f"Bot advice (Haiku): ${advice['usd']:.2f} for {advice['answers']} answers")
    if games:
        lines.append("")
        ordered = sorted(games, key=lambda g: float(g["started"]))
        for g in ordered[:MAX_GAMES_LISTED]:
            who = ", ".join(g.get("humans", [])) or "nobody"
            nbots = len(g.get("bots", []))
            extra = f" + {nbots} bot{'s' if nbots != 1 else ''}" if nbots else ""
            lines.append(f"- {g.get('room', '?')}: {_duration(float(g['ended']) - float(g['started']))}, "
                         f"{g.get('mode', '?')}, level {g.get('level', '?')}; {who}{extra}")
        if len(ordered) > MAX_GAMES_LISTED:
            lines.append(f"... and {len(ordered) - MAX_GAMES_LISTED} more")
    text = "\n".join(lines)
    return text if len(text) <= DISCORD_LIMIT else text[:DISCORD_LIMIT - 3] + "..."


def post(url: str, text: str) -> None:
    body = json.dumps({"username": "CorsixTH multiplayer", "content": text}).encode("utf-8")
    request = urllib.request.Request(url, data=body, method="POST", headers={
        "Content-Type": "application/json", "User-Agent": "corsixth-mp-report/1"})
    with urllib.request.urlopen(request, timeout=20) as response:
        response.read()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--date", help="the local day (YYYY-MM-DD); default yesterday")
    parser.add_argument("--dry-run", action="store_true", help="print it, do not post it")
    args = parser.parse_args(argv)
    day = args.date
    if not day:
        today = datetime.datetime.now(stats.timezone()).date()
        day = (today - datetime.timedelta(days=1)).isoformat()
    text = report(day)
    if args.dry_run:
        print(text)
        return 0
    url = os.environ.get("DISCORD_WEBHOOK_URL", "")
    if not url:
        print("DISCORD_WEBHOOK_URL is not set: nothing posted", file=sys.stderr)
        print(text)
        return 1
    try:
        post(url, text)
    except (urllib.error.URLError, OSError) as exc:
        # (Never the URL: it is a secret.)
        print(f"posting the report failed: {exc.__class__.__name__}: {getattr(exc, 'code', '')}",
              file=sys.stderr)
        return 1
    print(f"report for {day} posted")
    return 0


if __name__ == "__main__":
    sys.exit(main())
