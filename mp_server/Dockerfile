# Relay and lobby server for CorsixTH multiplayer (mp_server/).
# Standard library only; no game code and no Theme Hospital data in the image.
#
#   docker build -t corsixth-mp-server mp_server
#   docker run -p 47800:47800 corsixth-mp-server
FROM python:3.13-slim

LABEL org.opencontainers.image.title="corsixth-mp-server" \
      org.opencontainers.image.description="Relay and lobby server for the experimental CorsixTH multiplayer mode" \
      org.opencontainers.image.source="https://github.com/lbakyl/CorsixTH-Multiplayer" \
      org.opencontainers.image.licenses="MIT"

# Unprivileged user with a fixed id (the compose file runs as it too).
RUN groupadd --system --gid 10001 corsixth \
 && useradd --system --uid 10001 --gid corsixth --home-dir /srv --no-create-home corsixth

WORKDIR /srv
COPY corsixth_mp ./corsixth_mp

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    CORSIXTH_MP_HOST=0.0.0.0 \
    CORSIXTH_MP_PORT=47800 \
    CORSIXTH_MP_LOG=INFO

USER 10001:10001
EXPOSE 47800/tcp
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD ["python", "-m", "corsixth_mp.health"]
CMD ["python", "-m", "corsixth_mp"]
