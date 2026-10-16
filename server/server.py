"""Motion-controller relay. Run from the repo root:
   uvicorn server.server:app --host 0.0.0.0 --port 8000
Hot path = raw text passthrough (no JSON parsing). Phones -> browser, browser -> phones."""
import asyncio, io, secrets, socket
from contextlib import suppress
from pathlib import Path

import segno
from fastapi import FastAPI, WebSocket
from fastapi.responses import FileResponse, Response
from fastapi.staticfiles import StaticFiles

WEB = Path(__file__).resolve().parent.parent / "web"
MAX_PLAYERS, GRACE = 4, 60  # phones per room; seconds a room outlives its browser
app = FastAPI()


class Room:
    __slots__ = ("browser", "phones", "reaper")

    def __init__(self):
        self.browser = None
        self.phones = {}  # player id -> WebSocket
        self.reaper = None


rooms: dict[str, Room] = {}


def new_code():
    if len(rooms) >= 10_000:
        return None
    while True:
        c = f"{secrets.randbelow(10_000):04d}"
        if c not in rooms:
            return c


async def reap(code, room):
    await asyncio.sleep(GRACE)
    if rooms.get(code) is room and room.browser is None:
        del rooms[code]
        for p in list(room.phones.values()):
            with suppress(Exception):
                await p.close(code=1001)


async def tell_browser(room, text):
    if room.browser:
        with suppress(Exception):
            await room.browser.send_text(text)


@app.websocket("/ws/browser")
async def browser_ws(ws: WebSocket, code: str = ""):
    await ws.accept()
    room = rooms.get(code)  # reclaim an existing room after a reconnect
    if room is None:
        code = new_code()
        if code is None:
            await ws.close(code=1013)
            return
        room = rooms[code] = Room()
    if room.reaper:
        room.reaper.cancel()
        room.reaper = None
    old, room.browser = room.browser, ws
    if old:
        with suppress(Exception):
            await old.close(code=4000)
    await ws.send_json({"type": "room", "code": code, "players": sorted(room.phones)})
    try:
        while True:
            msg = await ws.receive_text()  # pong / vibrate -> every phone (they filter by "to")
            for p in tuple(room.phones.values()):
                with suppress(Exception):
                    await p.send_text(msg)
    except Exception:
        pass
    finally:
        if room.browser is ws:
            room.browser = None
            room.reaper = asyncio.create_task(reap(code, room))


@app.websocket("/ws/mobile/{code}")
async def mobile_ws(ws: WebSocket, code: str, pid: int = 0):
    await ws.accept()
    room = rooms.get(code)
    if room is None:
        await ws.close(code=4404)
        return
    if 1 <= pid <= MAX_PLAYERS:  # reconnecting phone reclaims its slot
        slot = pid
    else:
        slot = next((i for i in range(1, MAX_PLAYERS + 1) if i not in room.phones), 0)
        if not slot:
            await ws.close(code=4409)
            return
    old, room.phones[slot] = room.phones.get(slot), ws
    if old:
        with suppress(Exception):
            await old.close(code=4000)
    await ws.send_text(f'{{"type":"hello","id":{slot}}}')
    await tell_browser(room, f'{{"type":"join","id":{slot}}}')
    try:
        while True:
            msg = await ws.receive_text()
            b = room.browser
            if b is not None:
                try:
                    await b.send_text(msg)  # raw passthrough
                except Exception:
                    pass
    except Exception:
        pass
    finally:
        if room.phones.get(slot) is ws:
            del room.phones[slot]
            await tell_browser(room, f'{{"type":"leave","id":{slot}}}')


@app.get("/")
def game():  # your game: web/game.html (or web/index.html)
    f = WEB / "game.html"
    return FileResponse(f if f.exists() else WEB / "index.html")


@app.get("/controller")
def controller():
    return FileResponse(WEB / "controller.html")


@app.get("/info")
def info():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1))
        return {"ip": s.getsockname()[0]}
    except Exception:
        return {"ip": "127.0.0.1"}
    finally:
        s.close()


@app.get("/qr")
def qr(data: str):
    buf = io.BytesIO()
    segno.make(data).save(buf, kind="svg", scale=6, border=1)
    return Response(buf.getvalue(), media_type="image/svg+xml")


@app.get("/apk")
@app.get("/download")
def download_apk():
    apk_path = Path(__file__).resolve().parent.parent / "flutter_app" / "build" / "app" / "outputs" / "flutter-apk" / "app-debug.apk"
    if apk_path.exists():
        return FileResponse(apk_path, media_type="application/vnd.android.package-archive", filename="GameController.apk")
    return Response("APK not built yet. Run 'flutter build apk' inside flutter_app directory.", status_code=404)


# Must stay LAST: serves extra game/controller files (js, css, images) from web/
app.mount("/", StaticFiles(directory=WEB), name="web")
