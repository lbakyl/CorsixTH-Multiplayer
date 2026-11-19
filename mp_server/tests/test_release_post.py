import json

from corsixth_mp import release_post

BODY = """Test build of CorsixTH with network multiplayer for **Windows 64-bit, Linux and macOS**, from the branch `mp/team-hospitals` at 03fbbe02: a pixel font for other alphabets.

**Windows:** download `CorsixTH-Multiplayer-test-03fbbe02-win64.zip`, unzip it. SHA-256: `3ecc`

**Play:** main menu, Multiplayer, **EU2: test builds** (`eu2.openth.org:47800` runs this build) and your name. Full guide: [PLAYING.md](https://example.org/PLAYING.md).

**New since e8248864**
- **A pixel font:** text the game's fonts cannot show is drawn with [Fusion Pixel](https://example.org).
- Invisible characters no longer show as a box.

Earlier changes are listed in the notes of the releases before it.
"""


def release(**changes):
    r = {
        "tag_name": "mp-test-03fbbe02",
        "name": "Multiplayer test build 03fbbe02 pixel font",
        "html_url": "https://github.com/openth-org/openth/releases/tag/mp-test-03fbbe02",
        "body": BODY,
        "prerelease": True,
        "published_at": "2026-11-18T11:45:00Z",
        "assets": [{"name": "CorsixTH-Multiplayer-test-03fbbe02-win64.zip"},
                   {"name": "CorsixTH-Multiplayer-03fbbe02-linux-x86_64.tar.gz"},
                   {"name": "CorsixTH-Multiplayer-03fbbe02-macos-arm64.zip"}],
    }
    r.update(changes)
    return r


def test_post_has_whats_new_and_where_to_play():
    payload = release_post.message(release())
    embed = payload["embeds"][0]
    assert payload["content"] == "New multiplayer test build: **mp-test-03fbbe02**"
    assert embed["title"] == "Multiplayer test build 03fbbe02 pixel font"
    assert embed["url"].endswith("/mp-test-03fbbe02")
    assert embed["description"].startswith("A pixel font for other alphabets.")
    assert "**New since e8248864**" in embed["description"]
    assert "- Invisible characters no longer show as a box." in embed["description"]
    assert "Earlier changes" not in embed["description"]
    fields = {f["name"]: f["value"] for f in embed["fields"]}
    assert fields["Download"].startswith("[Windows, Linux, macOS](")
    assert fields["Play"] == ("Main menu, Multiplayer, **EU2: test builds** "
                              "(`eu2.openth.org:47800` runs this build) and your name.")
    assert embed["color"] == release_post.TEST_COLOUR
    assert payload["allowed_mentions"] == {"parse": []}  # (no @everyone from release notes)


def test_missing_platform_is_named():
    assets = [{"name": "CorsixTH-Multiplayer-test-03fbbe02-win64.zip"},
              {"name": "CorsixTH-Multiplayer-03fbbe02-linux-x86_64.tar.gz"}]
    assert release_post.platforms(assets) == "Windows, Linux (macOS still being built)"
    assert release_post.platforms([]) == "none yet"


def test_stable_build_colour_and_word():
    payload = release_post.message(release(prerelease=False, tag_name="mp-stable-03fbbe02"))
    assert payload["embeds"][0]["color"] == release_post.STABLE_COLOUR
    assert payload["content"] == "New multiplayer stable build: **mp-stable-03fbbe02**"


def test_long_notes_stop_at_a_whole_point_within_discords_limit():
    many = "\n".join(f"- Point {i}: " + "x" * 300 for i in range(40))
    body = BODY.replace("- Invisible characters no longer show as a box.", many)
    description = release_post.message(release(body=body))["embeds"][0]["description"]
    assert len(description) <= release_post.DESCRIPTION_LIMIT
    assert description.endswith("...and more in the [release notes]"
                                "(https://github.com/openth-org/openth/releases/tag/mp-test-03fbbe02).")
    assert "x" * 300 + "\n" in description  # (whole points only)


def test_without_webhook_nothing_is_posted(monkeypatch, capsys):
    monkeypatch.delenv("DISCORD_RELEASES_WEBHOOK", raising=False)
    monkeypatch.setattr(release_post, "fetch_release", lambda repo, tag, token: release())
    posted = []
    monkeypatch.setattr(release_post, "post", lambda url, payload: posted.append(payload))
    assert release_post.main(["--tag", "mp-test-03fbbe02"]) == 0
    assert posted == [] and "nothing posted" in capsys.readouterr().out


def test_with_webhook_posts_once(monkeypatch):
    monkeypatch.setenv("DISCORD_RELEASES_WEBHOOK", "https://discord.example/api/webhooks/1/x")
    monkeypatch.setattr(release_post, "fetch_release", lambda repo, tag, token: release())
    posted = []
    monkeypatch.setattr(release_post, "post", lambda url, payload: posted.append((url, payload)))
    assert release_post.main(["--tag", "mp-test-03fbbe02"]) == 0
    assert len(posted) == 1 and json.dumps(posted[0][1])
