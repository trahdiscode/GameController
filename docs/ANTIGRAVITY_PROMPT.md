# Prompt for Antigravity (paste as-is)

Build the browser game and the phone controller for this repo. **Do not modify `server/` or `app/`.** Read `docs/PROTOCOL.md` first; it defines every endpoint and message. Output files go in `web/`:
- `web/game.html`: the laptop game (extra js/css/assets allowed in `web/`, use relative paths).
- `web/controller.html`: the phone controller, a single self-contained file.

**Game requirements:** a simple game controlled entirely by phone tilt (racing, maze or ball-balancing). Shake or an on-screen button = jump/boost. Show the 4-digit room code and a QR code (`/qr?data=`) pointing to `<base>/controller?code=NNNN`. Show server connection status and, per player, connection status and latency (from the `l` field). Support up to 4 phones as separate players. Answer `ping` with `pong`. Send a `vib` message on game events. Auto-reconnect and resume the same room code.

**Controller requirements:** server address field (needed inside the Capacitor APK), room code field (prefill from `?code=`), Connect button that also requests iOS sensor permission. Read DeviceOrientation (tilt) and DeviceMotion (accelerometer, gyroscope). Detect shake to jump. Calibrate button that sets the neutral pose (persist it). Send the sensor packet about 60 times per second as defined in the protocol. On-screen JUMP button. Status pill (connecting / connected as Player N / reconnecting) and live latency. Auto-reconnect with backoff and reclaim the same player slot. Vibrate on `vib` messages.

**Acceptance test:** run `uvicorn server.server:app --host 0.0.0.0 --port 8000`, open `http://localhost:8000`, pair two controller tabs or phones with the code, confirm tilt moves players, shake jumps, a dropped connection recovers by itself, and latency shows on both screens.
