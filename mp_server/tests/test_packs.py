import asyncio
import base64
import os
import zlib

import pytest

from corsixth_mp import packs, server as srv
from corsixth_mp.builds import BuildCheck, lua_checksum
from corsixth_mp.protocol import decode, encode

def source_tree(root):
    """A small CorsixTH folder like a source tree's."""
    (root / "Lua").mkdir(parents=True)
    (root / "CorsixTH.lua").write_bytes(b"-- bootstrap\n")
    (root / "Lua" / "app.lua").write_bytes(b"return 1\n")
    (root / "Lua" / "api_version.lua").write_bytes(b"#endif /*]] --*/\n\nreturn 2721;\n")
    (root / "Lua" / "languages").mkdir()
    (root / "Lua" / "languages" / "english.lua").write_bytes(b"x = 1\n")
    (root / "Levels").mkdir()
    (root / "Levels" / "st.peter's.level").write_bytes(b"level")
    (root / "Campaigns").mkdir()
    (root / "Campaigns" / "Four Corners.map").write_bytes(bytes(range(256)))
    (root / "Sounds").mkdir()
    (root / "Bitmap").mkdir()
    (root / "Bitmap" / "mp_icons.dat").write_bytes(b"\0\1\2")
    (root / "Bitmap" / "notes.txt").write_bytes(b"not installed")
    (root / "Src").mkdir()
    (root / "Src" / "th_packs.h").write_text("constexpr int engine_level = 3;\n")
    return root


def key_file(tmp_path):
    """A new signing key (the release side's library, not needed by servers)."""
    pytest.importorskip("cryptography")
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
    key = Ed25519PrivateKey.generate()
    path = tmp_path / "key.pem"
    path.write_bytes(key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                                       serialization.NoEncryption()))
    return key, path


def served_pack(src, out, release):
    """A pack as a server gets it, with a made-up signature (servers never
    check it; the game does)."""
    build = lua_checksum(src / "Lua")
    raw = packs.container(packs.collect(src), build=build, api=packs.api_version(src),
                          engine=packs.engine_level(src), release=release)
    out.mkdir(parents=True, exist_ok=True)
    pack_path, sig_path = out / packs.pack_name(build), out / packs.sig_name(build)
    pack_path.write_bytes(zlib.compress(raw))
    sig_path.write_text("ab" * 64 + "\n")
    return pack_path, sig_path, build


def test_pack_carries_what_the_game_installs_and_is_signed(tmp_path):
    src = source_tree(tmp_path / "CorsixTH")
    key, path = key_file(tmp_path)
    pack_path, sig_path, build = packs.make(src, "mp-test-12345678", path, tmp_path / "out")
    assert build == lua_checksum(src / "Lua")
    assert pack_path.name == f"openth-pack-{build}.bin"
    blob = pack_path.read_bytes()
    key.public_key().verify(bytes.fromhex(sig_path.read_text().strip()), blob)  # (raises if wrong)
    info, files = packs.read(blob)
    assert (info.build, info.api, info.engine, info.release) == (build, 2721, 3, "mp-test-12345678")
    assert sorted(files) == ["Bitmap/mp_icons.dat", "Campaigns/Four Corners.map", "CorsixTH.lua",
                             "Levels/st.peter's.level", "Lua/api_version.lua", "Lua/app.lua",
                             "Lua/languages/english.lua"]
    assert files["Campaigns/Four Corners.map"] == bytes(range(256))


def test_names_a_pack_cannot_carry(tmp_path):
    src = source_tree(tmp_path / "CorsixTH")
    (src / "Lua" / ".hidden.lua").write_bytes(b"")
    with pytest.raises(ValueError):
        packs.collect(src)


def test_server_sends_its_pack_and_offers_it_to_other_builds(tmp_path):
    src = source_tree(tmp_path / "CorsixTH")
    (src / "Levels" / "big.map").write_bytes(os.urandom(3 * srv.PACK_CHUNK))  # (several pieces)
    pack_path, sig_path, build = served_pack(src, tmp_path / "packs", "mp-test-12345678")
    blob = pack_path.read_bytes()

    async def main():
        server = srv.Server(build_check=BuildCheck(checksum=build, release="mp-test-12345678"),
                            packs_dir=str(tmp_path / "packs"))
        port = await server.start("127.0.0.1", 0)
        try:
            # A player of another build is told the size of the download.
            r, w = await asyncio.open_connection("127.0.0.1", port)
            w.write(encode("HELLO", proto=1, name="Old", build="v-mp1-00000000").encode() + b"\n")
            verb, f = decode((await r.readline()).decode())
            assert verb == "ERROR" and f["code"] == "build_mismatch"
            assert f["need"] == build and f["pack"] == str(len(blob))
            assert f["pack_api"] == "2721" and f["pack_engine"] == "3"
            w.close()

            async def download(start=0):
                r, w = await asyncio.open_connection("127.0.0.1", port)
                w.write(encode("PACK", build=build, **{"from": start}).encode() + b"\n")
                verb, info = decode((await r.readline()).decode())
                assert verb == "PACKINFO"
                assert info["sig"] == sig_path.read_text().strip()
                assert info["size"] == str(len(blob)) and info["release"] == "mp-test-12345678"
                data = b""
                while True:
                    verb, f = decode((await r.readline()).decode())
                    if verb == "PACKEND":
                        break
                    assert verb == "PACKDATA"
                    data += base64.b64decode(f["d"])
                # The server leaves the connection open until the game, which
                # may still be reading, closes it (then the server does too).
                with pytest.raises(asyncio.TimeoutError):
                    await asyncio.wait_for(r.read(1), 0.3)
                w.close()
                assert await asyncio.wait_for(r.read(), 5) == b""
                return int(info["from"]), data

            assert await download() == (0, blob)
            # Going on after a cut: from the start of the piece it was in.
            start, rest = await download(srv.PACK_CHUNK + 5)
            assert start == srv.PACK_CHUNK and rest == blob[start:]

            r, w = await asyncio.open_connection("127.0.0.1", port)
            w.write(b"PACK build=0badf00d\n")
            verb, f = decode((await r.readline()).decode())
            assert verb == "ERROR" and f["code"] == "no_pack"
            w.close()
            assert server.players == {} and server.pack_sends == 0
        finally:
            await server.close()
    asyncio.run(main())


def test_a_pack_of_another_build_is_not_served(tmp_path):
    src = source_tree(tmp_path / "CorsixTH")
    pack_path, sig_path, build = served_pack(src, tmp_path / "packs", "mp-test-1")
    pack_path.rename(tmp_path / "packs" / packs.pack_name("0badf00d"))
    sig_path.rename(tmp_path / "packs" / packs.sig_name("0badf00d"))
    server = srv.Server(packs_dir=str(tmp_path / "packs"))
    assert server.pack("0badf00d") is None
    assert server.pack(build) is None


def test_corrupt_pack_is_refused_when_read():
    with pytest.raises(zlib.error):
        packs.read(b"not a pack")
