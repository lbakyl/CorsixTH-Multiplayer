"""Start the headless referee game for a room (milestone S3), and the
computer players (bots) a room owner adds.

The referee is CorsixTH itself, run without a screen through
scripts/multiplayer/referee.lua. It needs a CorsixTH build, its source tree
(for the Lua code) and Theme Hospital data, none of which is part of the
server image; see docs/multiplayer/referee.md.

Configuration (environment variables; the referee is off without BINARY):
  CORSIXTH_MP_REFEREE_BINARY   path of the corsix-th executable
  CORSIXTH_MP_REFEREE_SOURCE   CorsixTH checkout (scripts/multiplayer/referee.lua)
  CORSIXTH_MP_REFEREE_DATA     Theme Hospital data folder (read only is enough)
  CORSIXTH_MP_REFEREE_LUA_CPATH, CORSIXTH_MP_REFEREE_LUA_PATH
                               where LuaSocket is, if not in the standard paths
  CORSIXTH_MP_REFEREE_WORKDIR  scratch folder for configs and logs (default /tmp/corsixth-referee)
"""

from __future__ import annotations

import asyncio
import logging
import os
import pathlib
import re
from dataclasses import dataclass

log = logging.getLogger("corsixth_mp.referee")


@dataclass(frozen=True)
class RefereeConfig:
    binary: str
    source: str
    data: str
    lua_cpath: str = ""
    lua_path: str = ""
    workdir: str = "/tmp/corsixth-referee"

    @classmethod
    def from_env(cls, env: dict[str, str] | None = None) -> "RefereeConfig | None":
        env = dict(os.environ if env is None else env)
        binary = env.get("CORSIXTH_MP_REFEREE_BINARY")
        if not binary:
            return None
        return cls(binary=binary,
                   source=env.get("CORSIXTH_MP_REFEREE_SOURCE", ""),
                   data=env.get("CORSIXTH_MP_REFEREE_DATA", ""),
                   lua_cpath=env.get("CORSIXTH_MP_REFEREE_LUA_CPATH", ""),
                   lua_path=env.get("CORSIXTH_MP_REFEREE_LUA_PATH", ""),
                   workdir=env.get("CORSIXTH_MP_REFEREE_WORKDIR", "/tmp/corsixth-referee"))


def _safe(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_-]", "_", name)[:40] or "room"


async def _start_headless(config: RefereeConfig, port: int, room: str, token: str, *,
                          script: str, what: str, player_name: str, env_extra: dict[str, str],
                          ) -> asyncio.subprocess.Process:
    """Start a headless game for `room` (the referee or a bot) that runs
    scripts/multiplayer/<script> and connects back to 127.0.0.1:`port`."""
    work = pathlib.Path(config.workdir) / f"{_safe(room)}-{what}-{token[:8]}"
    (work / "saves").mkdir(parents=True, exist_ok=True)
    (work / "config").mkdir(exist_ok=True)
    (work / "config.txt").write_text(
        f"theme_hospital_install = [[{config.data}]]\n"
        f"savegames = [[{work / 'saves'}]]\n"
        f'player_name = "{player_name}"\n'
        "fullscreen = false\nwidth = 640\nheight = 480\n"
        "language = [[English]]\n"
        "audio = false\nplay_music = false\nplay_sounds = false\n"
        "play_announcements = false\nmovies = false\nplay_intro = false\n"
        "play_demo = false\ncheck_for_updates = false\n",
        encoding="utf-8")
    env = dict(os.environ)
    env.update({
        "CORSIXTH_SOURCE": config.source,
        "MP_SERVER": f"127.0.0.1:{port}",
        "SDL_VIDEODRIVER": "dummy",
        "SDL_AUDIO_DRIVER": "dummy",
        "SDL_RENDER_DRIVER": "software",
        "XDG_CONFIG_HOME": str(work / "config"),
    })
    env.update(env_extra)
    if config.lua_cpath:
        env["MP_LUA_CPATH"] = config.lua_cpath
    if config.lua_path:
        env["MP_LUA_PATH"] = config.lua_path
    logfile = open(work / f"{what}.log", "wb")
    proc = await asyncio.create_subprocess_exec(
        config.binary,
        f"--interpreter={config.source}/scripts/multiplayer/{script}",
        f"--config-file={work / 'config.txt'}",
        stdin=asyncio.subprocess.DEVNULL, stdout=logfile, stderr=asyncio.subprocess.STDOUT,
        env=env)
    logfile.close()
    log.info("room %r: %s started (pid %d, log %s)", room, what, proc.pid, work / f"{what}.log")
    return proc


async def start_referee(config: RefereeConfig, port: int, room: str, token: str,
                        ) -> asyncio.subprocess.Process:
    """Start the referee for `room`; it connects back to 127.0.0.1:`port`."""
    return await _start_headless(config, port, room, token, script="referee.lua", what="referee",
                                 player_name="Referee",
                                 env_extra={"MP_REFEREE_ROOM": room, "MP_REFEREE_TOKEN": token})


async def start_bot(config: RefereeConfig, port: int, room: str, token: str, name: str,
                    mode: str) -> asyncio.subprocess.Process:
    """Start a computer player (scripts/multiplayer/bot.lua) for `room`: it
    joins the room under `name` like a player and plays its own hospital."""
    return await _start_headless(config, port, room, token, script="bot.lua", what="bot",
                                 player_name=name.replace('"', "'"),
                                 env_extra={"MP_BOT_ROOM": room, "MP_BOT_TOKEN": token,
                                            "MP_BOT_NAME": name, "MP_BOT_MODE": mode})
