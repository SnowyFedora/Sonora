#!/usr/bin/env python3
"""Sonora ↔ YouTube Music bridge. CLI, JSON on stdout.

Usage:
  ytm.py search "query" [limit]
  ytm.py home [limit]
  ytm.py stream VIDEO_ID
  ytm.py check
"""
from __future__ import annotations

import json
import sys


def ok(data):
    print(json.dumps({"ok": True, "data": data}, ensure_ascii=False))
    sys.exit(0)


def fail(msg: str, code: int = 1):
    print(json.dumps({"ok": False, "error": msg}, ensure_ascii=False))
    sys.exit(code)


def check():
    missing = []
    try:
        import ytmusicapi  # noqa: F401
    except ImportError:
        missing.append("ytmusicapi")
    try:
        import yt_dlp  # noqa: F401
    except ImportError:
        missing.append("yt-dlp")
    if missing:
        fail("Нужны пакеты: pip install " + " ".join(missing), 2)
    ok({"python": sys.executable, "ytmusicapi": True, "yt_dlp": True})


def _client():
    from ytmusicapi import YTMusic
    return YTMusic()


def _track(item: dict) -> dict:
    """Normalize search / chart item to a flat dict."""
    vid = item.get("videoId") or ""
    artists = item.get("artists") or []
    artist = ", ".join(a.get("name", "") for a in artists if a.get("name"))
    if not artist and item.get("artist"):
        artist = item["artist"] if isinstance(item["artist"], str) else item["artist"].get("name", "")
    thumbs = item.get("thumbnails") or []
    thumb = thumbs[-1]["url"] if thumbs else ""
    duration = item.get("duration") or item.get("length") or ""
    return {
        "id": vid,
        "title": item.get("title") or item.get("name") or "Unknown",
        "artist": artist,
        "album": (item.get("album") or {}).get("name", "") if isinstance(item.get("album"), dict) else (item.get("album") or ""),
        "duration": duration,
        "thumb": thumb,
    }


def search(query: str, limit: int = 20):
    if not query.strip():
        ok([])
    ytm = _client()
    raw = ytm.search(query, filter="songs", limit=limit)
    tracks = [_track(x) for x in raw if x.get("videoId")]
    ok(tracks)


def home(limit: int = 30):
    ytm = _client()
    tracks = []
    # Charts / popular
    try:
        charts = ytm.get_charts(country="RU")
        for section in (charts or {}).values() if isinstance(charts, dict) else []:
            if not isinstance(section, list):
                continue
            for item in section:
                if isinstance(item, dict) and item.get("videoId"):
                    tracks.append(_track(item))
                elif isinstance(item, dict) and item.get("items"):
                    for sub in item["items"]:
                        if sub.get("videoId"):
                            tracks.append(_track(sub))
                if len(tracks) >= limit:
                    break
            if len(tracks) >= limit:
                break
    except Exception:
        pass
    # Fallback: search popular queries
    if len(tracks) < 10:
        try:
            raw = ytm.search("топ хиты", filter="songs", limit=limit)
            for x in raw:
                if x.get("videoId"):
                    tracks.append(_track(x))
        except Exception as e:
            if not tracks:
                fail(f"home failed: {e}")
    # dedupe
    seen = set()
    unique = []
    for t in tracks:
        if t["id"] and t["id"] not in seen:
            seen.add(t["id"])
            unique.append(t)
    ok(unique[:limit])


def stream(video_id: str):
    if not video_id:
        fail("empty video id")
    import yt_dlp

    url = f"https://www.youtube.com/watch?v={video_id}"
    opts = {
        "format": "bestaudio/best",
        "quiet": True,
        "no_warnings": True,
        "skip_download": True,
        "noplaylist": True,
    }
    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=False)
            # Prefer direct URL
            stream_url = info.get("url")
            if not stream_url and info.get("formats"):
                # pick best audio
                formats = [f for f in info["formats"] if f.get("acodec") != "none" and f.get("url")]
                formats.sort(key=lambda f: f.get("abr") or 0, reverse=True)
                if formats:
                    stream_url = formats[0]["url"]
            if not stream_url:
                fail("no stream url")
            ok({
                "id": video_id,
                "url": stream_url,
                "title": info.get("title") or "",
                "ext": info.get("ext") or "m4a",
            })
    except Exception as e:
        fail(str(e))


def main():
    if len(sys.argv) < 2:
        fail("usage: ytm.py search|home|stream|check ...")
    cmd = sys.argv[1]
    try:
        if cmd == "check":
            check()
        elif cmd == "search":
            q = sys.argv[2] if len(sys.argv) > 2 else ""
            lim = int(sys.argv[3]) if len(sys.argv) > 3 else 20
            search(q, lim)
        elif cmd == "home":
            lim = int(sys.argv[2]) if len(sys.argv) > 2 else 30
            home(lim)
        elif cmd == "stream":
            stream(sys.argv[2] if len(sys.argv) > 2 else "")
        else:
            fail(f"unknown command: {cmd}")
    except Exception as e:
        fail(str(e))


if __name__ == "__main__":
    main()
