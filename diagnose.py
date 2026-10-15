# -*- coding: utf-8 -*-
"""GameController full diagnostic. Run from C:/Users/HP/Desktop/GameController"""
import sys, os, socket, json, asyncio
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

REPO = os.path.dirname(os.path.abspath(__file__))
BASE_HTTP = "http://127.0.0.1:8000"
BASE_WS   = "ws://127.0.0.1:8000"

PASS = "[PASS]"; FAIL = "[FAIL]"; INFO = "[INFO]"

def ok(msg):   print(f"  {PASS} {msg}")
def fail(msg): print(f"  {FAIL} {msg}")
def info(msg): print(f"  {INFO} {msg}")

# ── 1. Python modules ─────────────────────────────────────────────────────────
print("\n[1] Python modules...")
missing = []
for m in ["fastapi", "uvicorn", "segno", "websockets"]:
    try:
        mod = __import__(m)
        ok(f"{m} {getattr(mod, '__version__', 'ok')}")
    except ImportError:
        fail(f"{m} MISSING")
        missing.append(m)

if missing:
    import subprocess
    print(f"\n  Installing: {' '.join(missing)}")
    subprocess.check_call([sys.executable, "-m", "pip", "install"] + missing)
    print("  Done. Re-run this script.")
    sys.exit(0)

# ── 2. File layout ────────────────────────────────────────────────────────────
print("\n[2] File layout...")
all_files_ok = True
for f in ["server/server.py", "web/game.html", "web/controller.html", "requirements.txt"]:
    path = os.path.join(REPO, f)
    if os.path.exists(path):
        ok(f"{f} ({os.path.getsize(path):,} bytes)")
    else:
        fail(f"{f} MISSING"); all_files_ok = False

init = os.path.join(REPO, "server", "__init__.py")
if not os.path.exists(init):
    open(init, "w").close()
    info("Created server/__init__.py (was missing - fixes ModuleNotFoundError)")
else:
    ok("server/__init__.py")

# ── 3. HTML content checks ────────────────────────────────────────────────────
print("\n[3] HTML content checks...")
with open(os.path.join(REPO, "web", "game.html"), encoding="utf-8") as f: gh = f.read()
with open(os.path.join(REPO, "web", "controller.html"), encoding="utf-8") as f: ch = f.read()

checks = [
    ("game.html: WebSocket connect function",    "connectBrowserWs" in gh),
    ("game.html: ping handler -> pong reply",    "pong" in gh and "ping" in gh),
    ("game.html: join / leave events",           "join" in gh and "leave" in gh),
    ("game.html: /info fetch for LAN IP",        "/info" in gh),
    ("game.html: auto-reconnect timer",          "setTimeout(connectBrowserWs" in gh),
    ("game.html: sessionStorage room code",      "room_code" in gh),
    ("game.html: QR code display",               "/qr" in gh),
    ("controller.html: 60Hz setInterval",        "setInterval" in ch),
    ("controller.html: ping/pong latency",       "ping" in ch and "pong" in ch and "rtt" in ch),
    ("controller.html: vib handler",             "vib" in ch),
    ("controller.html: auto-reconnect backoff",  "scheduleReconnect" in ch),
    ("controller.html: calibrate button",        "doCalibrate" in ch),
    ("controller.html: iOS requestPermission",   "requestPermission" in ch),
    ("controller.html: shake detection",         "shakeMagnitude" in ch),
    ("controller.html: jump counter (j)",        "jumps++" in ch),
    ("controller.html: WakeLock",                "wakeLock" in ch),
]
content_ok = True
for desc, result in checks:
    (ok if result else fail)(desc)
    if not result: content_ok = False

# ── 4. HTTP endpoints ─────────────────────────────────────────────────────────
print("\n[4] HTTP endpoints...")
import urllib.request, urllib.error

def http_get(path, timeout=4):
    try:
        with urllib.request.urlopen(BASE_HTTP + path, timeout=timeout) as r:
            return r.status, r.read(), r.headers.get("content-type","")
    except urllib.error.URLError as e:
        return None, None, str(e)

status, body, ct = http_get("/")
if status == 200 and b"Neon Tilt Arena" in body:
    ok("GET /  -> game.html (Neon Tilt Arena)")
elif status is None:
    fail(f"GET /  -> NO RESPONSE: {ct}")
    print("\n  *** SERVER NOT RUNNING ***")
    print("  In your terminal, run:")
    print("    python -m uvicorn server.server:app --host 0.0.0.0 --port 8000")
    sys.exit(1)
else:
    fail(f"GET /  -> status={status}, missing expected title")

status, body, ct = http_get("/controller")
if status == 200 and b"Phone Motion Controller" in body:
    ok("GET /controller -> controller.html")
else:
    fail(f"GET /controller -> status={status}")

status, body, ct = http_get("/info")
if status == 200:
    ip_data = json.loads(body)
    LAN_IP = ip_data.get("ip", "127.0.0.1")
    ok(f"GET /info -> ip={LAN_IP}")
else:
    fail(f"GET /info -> status={status}")
    LAN_IP = "127.0.0.1"

status, body, ct = http_get("/qr?data=http%3A%2F%2Ftest")
if status == 200 and (b"<svg" in body or b"SVG" in body):
    ok("GET /qr -> SVG QR code returned")
else:
    fail(f"GET /qr -> status={status}, ct={ct}")

# ── 5. WebSocket round-trip ───────────────────────────────────────────────────
print("\n[5] WebSocket round-trip test...")
import websockets as _ws

async def ws_full_test():
    errs = []
    try:
        async with _ws.connect(f"{BASE_WS}/ws/browser") as bws:
            msg = json.loads(await asyncio.wait_for(bws.recv(), 5))
            assert msg["type"] == "room" and len(msg["code"]) == 4
            code = msg["code"]
            ok(f"Browser WebSocket connected, room={code}")

            async with _ws.connect(f"{BASE_WS}/ws/mobile/{code}?pid=0") as mws:
                h = json.loads(await asyncio.wait_for(mws.recv(), 5))
                assert h["type"] == "hello" and h["id"] == 1
                ok(f"Mobile connected, slot={h['id']}")

                j = json.loads(await asyncio.wait_for(bws.recv(), 5))
                assert j["type"] == "join" and j["id"] == 1
                ok("Browser received join event")

                # Sensor packet pass-through
                pkt = {"id":1,"b":5.5,"g":-2.1,"a":[0.1,9.7,0.2],"r":[0,0,0],"j":0,"l":0}
                await mws.send(json.dumps(pkt))
                got = json.loads(await asyncio.wait_for(bws.recv(), 5))
                assert got == pkt
                ok("Sensor packet relayed verbatim")

                # Ping -> Pong
                ping = {"type":"ping","id":1,"ts":12345.0}
                await mws.send(json.dumps(ping))
                bp = json.loads(await asyncio.wait_for(bws.recv(), 5))
                assert bp == ping
                pong = {"type":"pong","to":1,"ts":12345.0}
                await bws.send(json.dumps(pong))
                mp = json.loads(await asyncio.wait_for(mws.recv(), 5))
                assert mp == pong
                ok("Ping/Pong round-trip successful")

                # Vibration
                vib = {"type":"vib","to":1,"ms":60}
                await bws.send(json.dumps(vib))
                mv = json.loads(await asyncio.wait_for(mws.recv(), 5))
                assert mv == vib
                ok("Vibration event delivered to mobile")

            leave = json.loads(await asyncio.wait_for(bws.recv(), 5))
            assert leave["type"] == "leave" and leave["id"] == 1
            ok("Leave event received on disconnect")

        # Browser reconnect preserves room
        async with _ws.connect(f"{BASE_WS}/ws/browser?code={code}") as bws2:
            r2 = json.loads(await asyncio.wait_for(bws2.recv(), 5))
            assert r2["code"] == code
            ok(f"Browser reconnect same room code={code}")

        # Mobile reconnect reclaims slot
        async with _ws.connect(f"{BASE_WS}/ws/browser?code={code}") as bws3:
            await asyncio.wait_for(bws3.recv(), 5)  # room msg
            async with _ws.connect(f"{BASE_WS}/ws/mobile/{code}?pid=1") as mws2:
                h2 = json.loads(await asyncio.wait_for(mws2.recv(), 5))
                assert h2["id"] == 1
                ok("Mobile reconnect reclaimed slot 1 (pid reclaim works)")

    except Exception as e:
        errs.append(str(e))
        fail(f"WebSocket test error: {e}")
    return errs

ws_errors = asyncio.run(ws_full_test())

# ── 6. Firewall / LAN check ───────────────────────────────────────────────────
print("\n[6] Firewall / LAN check...")
try:
    s = socket.create_connection((LAN_IP, 8000), timeout=2); s.close()
    ok(f"Port 8000 reachable on LAN IP {LAN_IP}")
    info(f"Phone should open: http://{LAN_IP}:8000/controller?code=XXXX")
except Exception as e:
    fail(f"Port 8000 NOT reachable on LAN IP {LAN_IP}: {e}")
    info("Fix (Admin PowerShell):")
    info('  New-NetFirewallRule -DisplayName "GameController8000" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow')

# ── Summary ───────────────────────────────────────────────────────────────────
print("\n" + "="*62)
if not ws_errors and all_files_ok and content_ok:
    print("  ALL CHECKS PASSED!")
    print(f"  Laptop:  http://localhost:8000")
    print(f"  Phone:   http://{LAN_IP}:8000/controller?code=XXXX")
    print("  (Replace XXXX with the code shown on the game screen)")
else:
    print("  SOME CHECKS FAILED -- see [FAIL] lines above.")
print("="*62)
