"""STARTTLS on the player port (corsixth_mp/tls.py, docs/multiplayer/ENCRYPTION.md).

Certificates are made at test time with the openssl command into a temporary
folder; nothing secret is kept in the repository.
"""

import asyncio
import hashlib
import shutil
import ssl
import subprocess

import pytest

from corsixth_mp import server as srv
from corsixth_mp.protocol import decode, encode
from corsixth_mp.tls import TlsConfig, certificate_fingerprint, format_fingerprint

pytestmark = pytest.mark.skipif(shutil.which("openssl") is None, reason="needs the openssl command")


@pytest.fixture(scope="module")
def cert(tmp_path_factory):
    d = tmp_path_factory.mktemp("tls")
    crt, key = d / "server.crt", d / "server.key"
    subprocess.run(["openssl", "req", "-x509", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:prime256v1",
                    "-nodes", "-keyout", str(key), "-out", str(crt), "-days", "2", "-subj", "/CN=test"],
                   check=True, capture_output=True)
    return str(crt), str(key)


def client_context():
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE  # like the game: the certificate is pinned, not validated
    return ctx


async def line(reader, timeout=3.0):
    raw = await asyncio.wait_for(reader.readline(), timeout)
    return raw.decode().rstrip("\n")


async def next_message(reader, verb):
    """Fields of the next line with this verb (pings are skipped)."""
    while True:
        text = await line(reader)
        if text.split(" ")[0] == verb:
            return decode(text)[1]


def serve(coro_fn, tls=None, **server_args):
    async def main():
        server = srv.Server(tls=tls, **server_args)
        port = await server.start("127.0.0.1", 0)
        try:
            await coro_fn(server, port)
        finally:
            await server.close()
    asyncio.run(main())


async def open_tls(port):
    r, w = await asyncio.open_connection("127.0.0.1", port)
    w.write(b"STARTTLS\n")
    assert await line(r) == "STARTTLS ok"
    await w.start_tls(client_context())
    return r, w


def send(w, verb, **fields):
    w.write(encode(verb, **fields).encode() + b"\n")


def hello(w, name="p"):
    send(w, "HELLO", proto=1, name=name, build="b1")


def test_starttls_then_hello_and_a_password_room(cert):
    tls = TlsConfig.load(*cert)

    async def body(server, port):
        r, w = await open_tls(port)
        ssl_object = w.get_extra_info("ssl_object")
        assert hashlib.sha256(ssl_object.getpeercert(binary_form=True)).hexdigest() == tls.fingerprint
        assert ssl_object.version() in ("TLSv1.2", "TLSv1.3")
        hello(w, "ann")
        await next_message(r, "WELCOME")
        send(w, "CREATE", room="r", password="secret pw", max=2)
        assert (await next_message(r, "JOINED"))["room"] == "r"
        # A second player, also encrypted, needs the password.
        r2, w2 = await open_tls(port)
        hello(w2, "bob")
        await next_message(r2, "WELCOME")
        send(w2, "JOIN", room="r", password="wrong")
        assert (await next_message(r2, "ERROR"))["code"] == "bad_password"
        send(w2, "JOIN", room="r", password="secret pw")
        assert (await next_message(r2, "JOINED"))["room"] == "r"
        w.close()
        w2.close()
    serve(body, tls)


def test_the_password_is_not_on_the_wire_in_tls(cert):
    """A listener between the player and the server sees no password (and no
    room name): the bytes after STARTTLS are TLS records."""
    tls = TlsConfig.load(*cert)
    seen = bytearray()

    async def body(server, port):
        async def pipe(src, dst):
            try:
                while data := await src.read(4096):
                    seen.extend(data)
                    dst.write(data)
                    await dst.drain()
            except ConnectionError:
                pass
            dst.close()

        async def handle(cr, cw):
            sr, sw = await asyncio.open_connection("127.0.0.1", port)
            await asyncio.gather(pipe(cr, sw), pipe(sr, cw))

        mitm = await asyncio.start_server(handle, "127.0.0.1", 0)
        mport = mitm.sockets[0].getsockname()[1]
        r, w = await open_tls(mport)
        hello(w, "ann")
        await next_message(r, "WELCOME")
        send(w, "CREATE", room="visibleroom", password="hunter2hunter2", max=2)
        await next_message(r, "JOINED")
        w.close()
        mitm.close()
    serve(body, tls)
    assert b"STARTTLS" in seen  # the one line in clear
    assert b"hunter2hunter2" not in seen and b"visibleroom" not in seen and b"HELLO" not in seen


def test_no_certificate_the_player_goes_on_in_clear():
    async def body(server, port):
        r, w = await asyncio.open_connection("127.0.0.1", port)
        w.write(b"STARTTLS\n")
        assert decode(await line(r))[1]["code"] == "no_tls"
        hello(w)  # on the same connection
        assert (await next_message(r, "WELCOME"))["proto"] == "1"
        w.close()
    serve(body)


def test_clear_players_still_work_with_a_certificate(cert):
    async def body(server, port):
        r, w = await asyncio.open_connection("127.0.0.1", port)
        hello(w)
        await next_message(r, "WELCOME")
        w.close()
    serve(body, TlsConfig.load(*cert))


def test_required_refuses_clear_players_but_not_this_machine(cert):
    tls = TlsConfig.load(*cert, required=True)

    async def body(server, port):
        # 127.0.0.1 is the server's own address (its bots and referee).
        r, w = await asyncio.open_connection("127.0.0.1", port)
        hello(w)
        await next_message(r, "WELCOME")
        w.close()
        # Any other address: refused, with a reason an old game can show.
        server.own_addresses = ()
        r, w = await asyncio.open_connection("127.0.0.1", port)
        hello(w)
        assert (await next_message(r, "ERROR"))["code"] == "tls_required"
        assert await r.read() == b""
        # Encrypted: fine. HEALTH in clear: fine.
        r, w = await open_tls(port)
        hello(w)
        await next_message(r, "WELCOME")
        w.close()
        r, w = await asyncio.open_connection("127.0.0.1", port)
        w.write(b"HEALTH\n")
        assert (await line(r)).startswith("OK ")
        w.close()
    serve(body, tls)


def test_a_failed_handshake_does_not_hurt_the_server(cert):
    async def body(server, port):
        r, w = await asyncio.open_connection("127.0.0.1", port)
        w.write(b"STARTTLS\n")
        assert await line(r) == "STARTTLS ok"
        w.write(b"this is not a client hello\n" * 4)
        await asyncio.wait_for(r.read(), 5)  # an alert, then the server hangs up
        w.close()
        r, w = await open_tls(port)
        hello(w)
        await next_message(r, "WELCOME")
        w.close()
    serve(body, TlsConfig.load(*cert))


def test_old_tls_versions_are_refused(cert):
    async def body(server, port):
        r, w = await asyncio.open_connection("127.0.0.1", port)
        w.write(b"STARTTLS\n")
        assert await line(r) == "STARTTLS ok"
        ctx = client_context()
        try:
            ctx.minimum_version = ssl.TLSVersion.TLSv1
            ctx.maximum_version = ssl.TLSVersion.TLSv1_1
        except ValueError:
            pytest.skip("this OpenSSL cannot speak TLS 1.1")
        with pytest.raises((ssl.SSLError, ConnectionError, OSError)):
            await w.start_tls(ctx)
    serve(body, TlsConfig.load(*cert))


def test_many_large_lines_in_both_directions(cert):
    """A shared save is hundreds of kilobytes in one line: partial writes and
    reads over TLS."""
    async def body(server, port):
        r, w = await open_tls(port)
        hello(w)
        await next_message(r, "WELCOME")
        big = "x" * 60000
        count = 60  # 3.6 MB of requests, as many error answers
        for _ in range(count):
            w.write(f"NOSUCHVERB pad={big}\n".encode())
        await w.drain()
        errors = 0
        while errors < count:
            if (await line(r, 10)).startswith("ERROR"):
                errors += 1
        w.close()
    serve(body, TlsConfig.load(*cert))


def test_config_from_env(cert):
    assert TlsConfig.from_env({}) is None
    with pytest.raises(ValueError):
        TlsConfig.from_env({"CORSIXTH_MP_TLS_REQUIRED": "1"})
    cfg = TlsConfig.from_env({"CORSIXTH_MP_TLS_CERT": cert[0], "CORSIXTH_MP_TLS_KEY": cert[1],
                              "CORSIXTH_MP_TLS_REQUIRED": "1"})
    assert cfg.required and cfg.fingerprint == certificate_fingerprint(cert[0])
    assert len(cfg.fingerprint) == 64
    assert format_fingerprint("abcd") == "ab:cd"
    with pytest.raises(OSError):
        TlsConfig.load("/nonexistent.pem")
