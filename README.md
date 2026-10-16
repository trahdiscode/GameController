# Tilt Arena: phone as a motion controller

Your phone becomes a gyro/accelerometer controller for a browser game on your laptop.

**Stack:** Python 3.10+ · FastAPI + uvicorn (WebSockets) · Flutter (Dart motion controller with sensors_plus, low-pass filter, wake lock, haptics) · Vanilla JS (HTML5 Canvas game, DeviceMotion/Orientation APIs) · Capacitor (alternative web wrapper) · segno (QR codes).

```
server/server.py        relay + serves game pages   web/game.html      laptop browser game
flutter_app/            Flutter mobile controller   app/               Capacitor APK wrapper
```

## Run
```
python -m venv venv && venv\Scripts\activate      (macOS/Linux: source venv/bin/activate)
pip install -r requirements.txt
uvicorn server.server:app --host 0.0.0.0 --port 8000
```
1. Laptop: open `http://localhost:8000`. It shows a **4-digit room code and a QR code**.
2. Phone (same Wi-Fi), pick one:
   - **APK (recommended):** Download directly from `http://<LAPTOP_IP>:8000/apk` (or build via `flutter build apk`). Open the app, enter `LAPTOP_IP:8000` and the 4-digit code. Works with zero setup over local Wi-Fi.
   - **Browser:** scan the QR. Phones only expose motion sensors on **HTTPS**, so tunnel first: `cloudflared tunnel --url http://localhost:8000`, then open the game via the tunnel URL so the QR points to it.
3. Tap **Connect**. The first connect auto-calibrates. Re-tap **Calibrate** any time while holding the phone in your neutral pose.

Controls & Layouts:
- **🎮 Gamepad (Pro Console):** Dual 360° analog thumbsticks (L3/R3), 4-way D-Pad, ABXY diamond cluster, bumpers (LB/RB), triggers (LT/RT), Select, Start, Home, and Turbo toggle.
- **🏎️ Racing Wheel:** Interactive touch steering wheel + physical gyro-tilt steering, progressive accelerator & brake pedals, Nitro boost, handbrake drift, and flappy paddle shifter.
- **📱 Motion & Tilt:** Artificial horizon / 3D spirit level, live roll/pitch degrees, neutral calibration, giant JUMP button, and shake detection.
- **🖱️ Trackpad:** Laptop-style precision trackpad surface with left, middle, right click buttons and swipe gesture steering.
- **⌨️ Action Deck:** Vertical throttle lever (0-100%), POV hat switch, primary fire, missiles, flares, airbrake, and programmable M1/M2 macros.
- **⚙️ Every Control Option:** Slide-out settings drawer with button skins (Xbox / PS / Nintendo), Southpaw mode, haptic intensity, tactile sound clicks, tilt deadzone/sensitivity, invert pitch/roll, stick deadzone/sensitivity/inversion, and screen wake lock.

Up to 4 phones per room. Arrow keys + space work as a fifth, keyboard player.

## Run the Flutter Mobile Controller
```powershell
cd flutter_app
flutter run                  # runs directly on connected Android phone
flutter build apk --debug    # outputs to flutter_app/build/app/outputs/flutter-apk/app-debug.apk
```

## Build the Capacitor APK (Alternative)
Needs Node 20+, Android Studio (SDK).
```
cd app && npm install && npx cap add android
```
Add `<uses-permission android:name="android.permission.VIBRATE"/>` to `app/android/app/src/main/AndroidManifest.xml`, then:
```
npm run android          # opens Android Studio -> Build > Build APK(s)
```
Output: `app/android/app/build/outputs/apk/debug/app-debug.apk`. Enable "install unknown apps" on the phone to sideload.
The app bundles the controller page, so its origin is secure (sensors allowed) while it talks to your LAN server over `ws://`.

## Pairing
Browser connects to `/ws/browser`, the server mints an unused 4-digit code. Phones connect to `/ws/mobile/<code>` and are assigned player slots 1-4 (`hello` message). The QR encodes `http(s)://host/controller?code=NNNN`.

## Latency approach
- **Raw relay:** the server never parses sensor JSON. It forwards the text frame as received.
- **State, not events:** the phone sends a small (~100 B) full-state packet at ~60 Hz, so a dropped or late packet is replaced by the next one.
- **Game reads the latest tilt each frame** (no queues), physics runs on `requestAnimationFrame`.
- **Live RTT:** each phone pings once per second, the game echoes it through the relay, and the phone measures the round trip. It is shown on the phone and in the game scoreboard.
- Same-LAN Wi-Fi is the intended setup. A tunnel adds internet round-trip time.

## Reliability
Both sides auto-reconnect with backoff. A phone reclaims its player slot (`?pid=`). The laptop page reclaims its room code (kept in `sessionStorage`). Rooms survive 60 s without a browser. Status pills show the state on both screens.

## Bonus features done
Multiplayer (up to 4 phones) · on-screen JUMP button · vibration feedback (coin pickup, shake, calibrate) · live latency display.
