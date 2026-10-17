# Relay and lobby server for CorsixTH multiplayer. No game data in this image.
FROM python:3.13-slim
RUN useradd --system --home /srv corsixth
WORKDIR /srv
COPY corsixth_mp ./corsixth_mp
USER corsixth
ENV CORSIXTH_MP_PORT=47800
EXPOSE 47800
CMD ["python", "-m", "corsixth_mp"]
