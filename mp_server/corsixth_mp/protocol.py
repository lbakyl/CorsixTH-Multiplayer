"""Line codec shared with the game (CorsixTH/Lua/mp_lobby.lua, mp_session.lua).

Every message is one UTF-8 line: a verb followed by ``key=value`` fields.
Values are percent-encoded for ``%``, ``=`` and whitespace, exactly like
``MultiplayerSession.encodeCommand`` in the game, so a value never contains a
space and fields can be split on single spaces.

Game lines (``C ...`` commands and ``S <peer> <step> <fp>`` step reports) use
the session's own format and are relayed verbatim; see server.py.
"""

from __future__ import annotations

import re

PROTOCOL_VERSION = 1
MAX_LINE_BYTES = 64 * 1024

_ENCODE_RE = re.compile(r"[%\s=]")
_FIELD_RE = re.compile(r"^([A-Za-z0-9_]+)=(\S*)$")


def encode_value(value: object) -> str:
    if isinstance(value, bool):
        value = 1 if value else 0
    text = str(value)
    return _ENCODE_RE.sub(lambda m: "".join(f"%{b:02X}" for b in m.group(0).encode("utf-8")), text)


_DECODE_BYTES_RE = re.compile(rb"%([0-9A-Fa-f]{2})")


def decode_value(text: str) -> str:
    # Percent escapes stand for bytes of the UTF-8 encoding.
    raw = _DECODE_BYTES_RE.sub(lambda m: bytes([int(m.group(1), 16)]), text.encode("utf-8"))
    return raw.decode("utf-8", errors="replace")


def encode(verb: str, **fields: object) -> str:
    """Build one message line (without the trailing newline)."""
    parts = [verb]
    for key in sorted(fields):
        if fields[key] is None:
            continue
        parts.append(f"{key}={encode_value(fields[key])}")
    return " ".join(parts)


class ProtocolError(ValueError):
    pass


def decode(line: str) -> tuple[str, dict[str, str]]:
    """Split a message line into its verb and decoded fields."""
    line = line.rstrip("\r\n")
    if not line:
        raise ProtocolError("empty line")
    verb, _, rest = line.partition(" ")
    fields: dict[str, str] = {}
    for part in rest.split(" ") if rest else []:
        if not part:
            continue
        m = _FIELD_RE.match(part)
        if not m:
            raise ProtocolError(f"bad field {part!r}")
        fields[m.group(1)] = decode_value(m.group(2))
    return verb, fields


def is_game_line(line: str) -> bool:
    return line.startswith("C ") or line.startswith("S ")


_STEP_RE = re.compile(r"^S (\d+) (\d+) (.*)$")


def parse_step_report(line: str) -> tuple[int, int, str] | None:
    """``S <peer> <step> <fingerprint>`` -> (peer, step, fingerprint)."""
    m = _STEP_RE.match(line)
    if not m:
        return None
    return int(m.group(1)), int(m.group(2)), m.group(3)


def command_peer(line: str) -> int | None:
    """The ``peer`` field of a ``C`` command line, if present."""
    m = re.search(r"(?:^C | )peer=(\d+)(?: |$)", line)
    return int(m.group(1)) if m else None
