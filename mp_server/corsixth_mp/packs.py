"""Game packs: the game's scripts and small data files of one build.

A player whose game is another build than a server's can download the
server's build in the game (CorsixTH/Lua/mp_pack.lua) instead of looking for
it on GitHub. A pack runs code on the player's computer, so the game takes
only packs signed with an OpenTH release key (CorsixTH/Src/th_packs.cpp). The
private key stays on the release maker's computer; servers only pass the
signed files on.

A pack file (openth-pack-<build>.bin) is zlib data of:

    OPENTH-PACK 1
    build <checksum of the Lua code, as in the build id>
    api <the engine's api_version the scripts need>
    engine <the lowest engine level for packs the scripts need>
    release <release name>
    file <size> <path>        (one line per file, then)
    data
    <the files' bytes, one after another>

Its signature (openth-pack-<build>.sig) is 128 hexadecimal digits: the
Ed25519 signature of the pack file's bytes.

    python -m corsixth_mp.packs make --source <tree>/CorsixTH --release mp-test-x \\
        --key ~/.openth/pack-signing-key.pem --out <folder>
    python -m corsixth_mp.packs show <folder>/openth-pack-<build>.bin
"""
from __future__ import annotations

import argparse
import os
import pathlib
import re
import sys
import zlib
from dataclasses import dataclass

from .builds import lua_checksum

MAGIC = "OPENTH-PACK 1"
# What the game installs next to the engine and a pack brings along
# (CorsixTH/CMakeLists.txt: install(DIRECTORY Campaigns Lua Levels Sounds),
# Bitmap only its data files). Fonts, the sound font and libraries stay the
# installed game's.
TOP_FILES = ("CorsixTH.lua",)
TOP_DIRS = ("Lua", "Campaigns", "Levels", "Sounds", "Bitmap")
BITMAP_RE = re.compile(r"\.(tab|pal|dat|png|pl8)$")
# Bounds the game checks too (mp_pack.lua).
MAX_RAW_BYTES = 96 * 1024 * 1024
MAX_FILES = 5000
# (Letters, digits and a few signs: "Four Corners.map", "st.peter's.level".
# No part starts with a dot, so no ".." either.)
PATH_RE = re.compile(r"^[A-Za-z0-9_][A-Za-z0-9_.' \-]*(/[A-Za-z0-9_][A-Za-z0-9_.' \-]*)*$")


def pack_name(build: str) -> str:
    return f"openth-pack-{build}.bin"


def sig_name(build: str) -> str:
    return f"openth-pack-{build}.sig"


def collect(source: str | os.PathLike[str]) -> list[tuple[str, bytes]]:
    """The files of a pack from a source tree's CorsixTH folder (or an
    installed game's data folder), sorted by path."""
    root = pathlib.Path(source)
    files: list[tuple[str, bytes]] = []
    for name in TOP_FILES:
        files.append((name, (root / name).read_bytes()))
    for top in TOP_DIRS:
        for path in sorted((root / top).rglob("*")):
            if not path.is_file():
                continue
            rel = path.relative_to(root).as_posix()
            if top == "Bitmap" and not BITMAP_RE.search(rel):
                continue
            if "__pycache__" in rel or rel.endswith((".pyc", ".orig", ".rej")):
                continue
            if not PATH_RE.match(rel):
                raise ValueError(f"file name a pack cannot carry: {rel!r}")
            files.append((rel, path.read_bytes()))
    return sorted(files)


def engine_level(source: str | os.PathLike[str]) -> int:
    """th::packs::engine_level in CorsixTH/Src/th_packs.h."""
    text = (pathlib.Path(source) / "Src" / "th_packs.h").read_text(encoding="utf-8")
    m = re.search(r"constexpr int engine_level = (\d+);", text)
    if not m:
        raise ValueError("engine_level not found in Src/th_packs.h")
    return int(m.group(1))


def api_version(source: str | os.PathLike[str]) -> int:
    text = (pathlib.Path(source) / "Lua" / "api_version.lua").read_text(encoding="utf-8")
    m = re.search(r"^return (\d+);", text, re.MULTILINE)
    if not m:
        raise ValueError("no version in Lua/api_version.lua")
    return int(m.group(1))


def container(files: list[tuple[str, bytes]], *, build: str, api: int, engine: int,
              release: str) -> bytes:
    if not re.fullmatch(r"[0-9a-f]{8}", build):
        raise ValueError(f"build must be 8 hex digits, not {build!r}")
    if not re.fullmatch(r"[A-Za-z0-9_.\-]+", release):
        raise ValueError(f"release name {release!r}")
    if len(files) > MAX_FILES:
        raise ValueError(f"{len(files)} files, at most {MAX_FILES}")
    lines = [MAGIC, f"build {build}", f"api {api}", f"engine {engine}", f"release {release}"]
    lines += [f"file {len(data)} {path}" for path, data in files]
    lines.append("data")
    raw = ("\n".join(lines) + "\n").encode("utf-8") + b"".join(data for _, data in files)
    if len(raw) > MAX_RAW_BYTES:
        raise ValueError(f"pack of {len(raw)} bytes, at most {MAX_RAW_BYTES}")
    return raw


@dataclass(frozen=True)
class PackInfo:
    build: str
    api: int
    engine: int
    release: str
    files: list[tuple[str, int]]


def read(blob: bytes) -> tuple[PackInfo, dict[str, bytes]]:
    """Unpack a pack file (no signature check): its header and files."""
    raw = zlib.decompress(blob)
    head, sep, body = raw.partition(b"\ndata\n")
    if not sep:
        raise ValueError("no data line")
    lines = head.decode("utf-8").split("\n")
    if lines[0] != MAGIC:
        raise ValueError("not a game pack")
    fields: dict[str, str] = {}
    files: list[tuple[str, int]] = []
    for line in lines[1:]:
        key, _, value = line.partition(" ")
        if key == "file":
            size, _, path = value.partition(" ")
            files.append((path, int(size)))
        else:
            fields[key] = value
    contents: dict[str, bytes] = {}
    at = 0
    for path, size in files:
        contents[path] = body[at:at + size]
        at += size
    if at != len(body):
        raise ValueError("file sizes do not add up")
    info = PackInfo(build=fields["build"], api=int(fields["api"]), engine=int(fields["engine"]),
                    release=fields["release"], files=files)
    return info, contents


def make(source: str | os.PathLike[str], release: str, key_file: str | os.PathLike[str],
         out: str | os.PathLike[str]) -> tuple[pathlib.Path, pathlib.Path, str]:
    """Write a signed pack of a source tree's CorsixTH folder: (pack, sig, build)."""
    from cryptography.hazmat.primitives import serialization  # (only on the release side)
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

    source = pathlib.Path(source)
    build = lua_checksum(source / "Lua")
    raw = container(collect(source), build=build, api=api_version(source),
                    engine=engine_level(source), release=release)
    blob = zlib.compress(raw, 9)
    key = serialization.load_pem_private_key(pathlib.Path(key_file).read_bytes(), password=None)
    if not isinstance(key, Ed25519PrivateKey):
        raise ValueError("the signing key is not an Ed25519 key")
    signature = key.sign(blob).hex()
    out = pathlib.Path(out)
    out.mkdir(parents=True, exist_ok=True)
    pack_path, sig_path = out / pack_name(build), out / sig_name(build)
    pack_path.write_bytes(blob)
    sig_path.write_text(signature + "\n", encoding="ascii")
    return pack_path, sig_path, build


@dataclass(frozen=True)
class ServedPack:
    """A pack a server hands out: its bytes and signature."""
    build: str
    blob: bytes
    signature: str
    release: str
    api: int = 0
    engine: int = 0

    @classmethod
    def load(cls, folder: str | os.PathLike[str], build: str) -> "ServedPack | None":
        folder = pathlib.Path(folder)
        pack_path, sig_path = folder / pack_name(build), folder / sig_name(build)
        if not pack_path.is_file() or not sig_path.is_file():
            return None
        signature = sig_path.read_text(encoding="ascii").strip()
        if not re.fullmatch(r"[0-9a-f]{128}", signature):
            raise ValueError(f"{sig_path}: not a signature")
        blob = pack_path.read_bytes()
        info, _ = read(blob)
        if info.build != build:
            raise ValueError(f"{pack_path} is the pack of build {info.build}")
        return cls(build=build, blob=blob, signature=signature, release=info.release, api=info.api,
                   engine=info.engine)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)
    mk = sub.add_parser("make", help="make and sign the pack of a source tree")
    mk.add_argument("--source", required=True, help="the tree's CorsixTH folder")
    mk.add_argument("--release", required=True)
    mk.add_argument("--key", required=True, help="the Ed25519 private key (PEM)")
    mk.add_argument("--out", required=True)
    show = sub.add_parser("show", help="print a pack's header")
    show.add_argument("pack")
    args = parser.parse_args(argv)
    if args.command == "make":
        pack_path, sig_path, build = make(args.source, args.release, args.key, args.out)
        print(f"build {build}: {pack_path} ({pack_path.stat().st_size} bytes), {sig_path.name}")
        return 0
    info, contents = read(pathlib.Path(args.pack).read_bytes())
    print(f"build {info.build} api {info.api} engine {info.engine} release {info.release}: "
          f"{len(info.files)} files, {sum(len(c) for c in contents.values())} bytes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
