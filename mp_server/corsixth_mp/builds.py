"""Which game build a server lets in.

A player's build id (MultiplayerLobby.buildId in CorsixTH/Lua/mp_lobby.lua)
looks like "v0.70.1-dev269-sv269-lua5.5-mp1-english-210d8203". Its last part
is a checksum of all Lua game code; it changes with every release. A server
with a headless referee can only referee (and run bots for) players whose
game code is the referee's, so it turns other builds away when they say
HELLO and tells them which release to get, instead of letting them make
rooms nobody can referee. The language part does not count: players of one
release with other languages can still play with each other.

Configuration (environment variables):
  CORSIXTH_MP_BUILD        the checksum players must have (8 hex digits), "any"
                           for no check; default: the checksum of the referee's
                           Lua code (<CORSIXTH_MP_REFEREE_SOURCE>/CorsixTH/Lua),
                           no check without a referee
  CORSIXTH_MP_RELEASE      the release players must get, e.g. mp-test-6d85201a
                           (setup-referee-host.sh writes it)
  CORSIXTH_MP_RELEASE_URL  its download page (default: the GitHub release page)
"""

from __future__ import annotations

import os
import pathlib
import re
import zlib
from dataclasses import dataclass

from .referee import RefereeConfig

REPO_URL = "https://github.com/lbakyl/CorsixTH-Multiplayer"


def lua_checksum(lua_dir: str | os.PathLike[str]) -> str:
    """The checksum MultiplayerLobby.buildId computes over a Lua folder: CRC-32
    of every .lua file's path and content (no CR), sorted by path."""
    root = pathlib.Path(lua_dir)
    files = sorted((p.relative_to(root).as_posix(), p) for p in root.rglob("*.lua") if p.is_file())
    if not files:
        raise FileNotFoundError(f"no Lua code in {root}")
    parts = [rel.encode("utf-8") + b"\0" + path.read_bytes().replace(b"\r", b"")
             for rel, path in files]
    return "%08x" % zlib.crc32(b"\0".join(parts))


def checksum_of(build: str) -> str:
    """The Lua code checksum at the end of a build id ("" if there is none)."""
    last = build.rsplit("-", 1)[-1]
    return last if re.fullmatch(r"[0-9a-f]{8}", last) else ""


@dataclass(frozen=True)
class BuildCheck:
    checksum: str
    release: str = ""
    url: str = ""

    @classmethod
    def from_env(cls, env: dict[str, str] | None = None,
                 referee: RefereeConfig | None = None) -> "BuildCheck | None":
        env = dict(os.environ if env is None else env)
        wanted = env.get("CORSIXTH_MP_BUILD", "").strip().lower()
        if wanted == "any":
            return None
        if wanted:
            if not re.fullmatch(r"[0-9a-f]{8}", wanted):
                raise ValueError(f"CORSIXTH_MP_BUILD must be 8 hex digits or 'any', not {wanted!r}")
            checksum = wanted
        elif referee is not None and referee.source:
            checksum = lua_checksum(pathlib.Path(referee.source) / "CorsixTH" / "Lua")
        else:
            return None
        release = env.get("CORSIXTH_MP_RELEASE", "").strip()
        url = env.get("CORSIXTH_MP_RELEASE_URL", "").strip()
        if not url and release:
            url = f"{REPO_URL}/releases/tag/{release}"
        return cls(checksum=checksum, release=release, url=url)

    def accepts(self, build: str) -> bool:
        return checksum_of(build) == self.checksum

    def refusal(self) -> dict[str, str]:
        """ERROR fields for a player of another build. The text is short
        enough for the one-line status of the lobby window; newer games
        offer the release's download page (release, url)."""
        if self.release:
            text = f"Other game version: get {self.release} on GitHub"
        else:
            text = f"Other game version: this server needs build {self.checksum}"
        fields = {"code": "build_mismatch", "text": text, "need": self.checksum}
        if self.release:
            fields["release"] = self.release
        if self.url:
            fields["url"] = self.url
        return fields
