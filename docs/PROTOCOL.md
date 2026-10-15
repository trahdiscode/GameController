# Protocol (the contract between server, game, controller)

The server is finished. Your game (`web/game.html`) and controller (`web/controller.html`) only need to follow this.
All WebSocket messages are **JSON text frames**. The server forwards them untouched, so you may add fields.

## Endpoints
| URL | Purpose |
|---|---|
| `GET /` | serves `web/game.html` (or `web/index.html`) |
| `GET /controller` | serves `web/controller.html` |
| `GET /qr?data=<text>` | returns an SVG QR code (use as `<img src>`) |
| `GET /info` | `{"ip":"192.168.x.x"}` laptop LAN IP (so the QR does not say localhost) |
| `WS /ws/browser?code=NNNN` | game connects here |
| `WS /ws/mobile/<code>?pid=N` | phone connects here |
Any other file in `web/` (js, css, images) is served at `/<filename>`; use relative paths.

## Game side (`/ws/browser`)
- Open `ws(s)://<location.host>/ws/browser?code=<saved code or empty>`. Use `wss` when the page is https.
- First message from server: `{"type":"room","code":"0728","players":[1,2]}`. Show the code and a QR of `<base>/controller?code=0728`. Save the code in `sessionStorage` and send it back on every reconnect so the room survives.
- Server notices: `{"type":"join","id":N}` and `{"type":"leave","id":N}` (N = player 1 to 4).
- Sensor packets from phones arrive as sent (below). Everything the game sends is broadcast to all phones, which filter on `to`.
- Reconnect automatically (about 1 s delay) and show a connection status.

## Phone side (`/ws/mobile/<code>?pid=N`)
- `pid` = 0 on first connect; after the `hello` message reuse the assigned id so the same slot is reclaimed on reconnect.
- First message from server: `{"type":"hello","id":N}`.
- Close codes: `4404` room not found (keep retrying, the laptop may be reconnecting), `4409` room full (stop), `4000` replaced by a newer connection of the same player (do not reconnect), `1001` room closed.
- Reconnect with backoff 0.5 s up to 3 s. Show status (connecting / connected / reconnecting) and the assigned player number.

## Phone to game messages
Sensor packet, about 60 per second:
```
{"id":1,"b":-3.2,"g":12.5,"a":[0.1,9.7,0.3],"r":[0,1.2,0],"j":4,"l":18}
```
`id` player id · `b` pitch degrees (calibrated) · `g` roll degrees (calibrated) · `a` accelerometer incl. gravity · `r` gyroscope rotationRate · `j` jump counter (increment on shake or button; game jumps when it increases, and treats its first value as baseline) · `l` last measured round-trip ms.
Latency ping, once per second: `{"type":"ping","id":1,"ts":<performance.now()>}`.

## Game to phone messages
- Pong (required for latency display): `{"type":"pong","to":1,"ts":<same ts>}`. The phone computes `RTT = performance.now() - ts`.
- Vibration: `{"type":"vib","to":1,"ms":60}`. Omit `to` to buzz every phone.

## Calibration
Phone keeps `offset = current beta/gamma` (tap button, store in localStorage) and sends `raw - offset` as `b`/`g`.

## Platform constraints
- Phone sensors (DeviceMotion/DeviceOrientation) work only on secure pages: HTTPS, or the APK (Capacitor WebView, origin `https://localhost`).
- Inside the APK, `window.Capacitor` exists and `location.host` is NOT the server. The controller must show a field to type `LAPTOP_IP:8000`, then connect to `ws://<that>/ws/mobile/<code>`.
- iOS needs `DeviceMotionEvent.requestPermission()` called from a tap.
- `navigator.vibrate` works on Android only.
