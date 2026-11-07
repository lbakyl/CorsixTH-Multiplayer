"""Encryption of the player connections (docs/multiplayer/ENCRYPTION.md).

A player may ask for TLS on the same port: the first line it sends is
`STARTTLS`; the server answers `STARTTLS ok` and both sides switch to TLS
(Server._starttls); `HELLO` and everything after it then travels encrypted.
A server without a certificate answers `ERROR code=no_tls` and the player
may go on in clear. Old players never send STARTTLS and keep working unless
the operator sets CORSIXTH_MP_TLS_REQUIRED.

Settings (environment variables, or the matching command line options):
  CORSIXTH_MP_TLS_CERT      PEM file with the server certificate (and chain)
  CORSIXTH_MP_TLS_KEY       PEM file with its private key (default: the same
                            file as the certificate, if it holds both)
  CORSIXTH_MP_TLS_REQUIRED  1: refuse players that stay in clear. Connections
                            from this machine (the server's own bots and
                            referee) and the HEALTH check are still allowed.

Standard library only (the `ssl` module, OpenSSL underneath): no encryption
code of our own.
"""

from __future__ import annotations

import hashlib
import os
import re
import ssl
from dataclasses import dataclass

# How long a player may take for the TLS handshake (seconds).
HANDSHAKE_TIMEOUT = 10.0

_PEM_CERT = re.compile(r"-----BEGIN CERTIFICATE-----(.+?)-----END CERTIFICATE-----", re.S)


@dataclass
class TlsConfig:
    context: ssl.SSLContext
    required: bool
    fingerprint: str  # SHA-256 of the server certificate, lower case hex

    @classmethod
    def load(cls, cert: str, key: str | None = None, required: bool = False) -> "TlsConfig":
        """Read the certificate and key (raises OSError or ssl.SSLError)."""
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        # TLS 1.2 is the oldest version still considered safe; the players'
        # OpenSSL (LuaSec) speaks 1.2 and 1.3.
        context.minimum_version = ssl.TLSVersion.TLSv1_2
        context.load_cert_chain(cert, key or None)
        return cls(context=context, required=required, fingerprint=certificate_fingerprint(cert))

    @classmethod
    def from_env(cls, env: dict[str, str] | None = None) -> "TlsConfig | None":
        env = os.environ if env is None else env
        cert = env.get("CORSIXTH_MP_TLS_CERT", "").strip()
        if not cert:
            if env.get("CORSIXTH_MP_TLS_REQUIRED", "").strip() not in ("", "0"):
                raise ValueError("CORSIXTH_MP_TLS_REQUIRED needs CORSIXTH_MP_TLS_CERT")
            return None
        required = env.get("CORSIXTH_MP_TLS_REQUIRED", "").strip() not in ("", "0")
        return cls.load(cert, env.get("CORSIXTH_MP_TLS_KEY", "").strip() or None, required)


def certificate_fingerprint(cert_file: str) -> str:
    """SHA-256 of the first certificate in a PEM file (what the players pin)."""
    with open(cert_file, encoding="ascii", errors="replace") as fh:
        match = _PEM_CERT.search(fh.read())
    if match is None:
        raise ValueError(f"no certificate in {cert_file}")
    der = ssl.PEM_cert_to_DER_cert(match.group(0))
    return hashlib.sha256(der).hexdigest()


def format_fingerprint(fingerprint: str) -> str:
    """aa:bb:cc... for display."""
    return ":".join(fingerprint[i:i + 2] for i in range(0, len(fingerprint), 2))
