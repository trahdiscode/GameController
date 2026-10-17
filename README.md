<div align="center">

# 🎮 TILT ARENA
### High-Performance Smartphone Motion Controller & Local Multiplayer Arena

[![Release](https://img.shields.io/badge/Release-v1.0.0-E3B382?style=for-the-badge&logo=github&logoColor=110E0C)](https://github.com/trahdiscode/GameController/releases/tag/v1.0.0)
[![Android APK](https://img.shields.io/badge/Android_APK-30.1_MB-D9825B?style=for-the-badge&logo=android&logoColor=white)](https://github.com/trahdiscode/GameController/releases/download/v1.0.0/TiltArenaController.apk)
[![Flutter](https://img.shields.io/badge/Flutter-3.5+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.143+-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Latency](https://img.shields.io/badge/Latency-%3C15ms_LAN-22C55E?style=for-the-badge&logo=speedtest&logoColor=white)](#-low-latency-engineering)

<p align="center">
  <b>Turn your Android phone into an ultra-responsive, 60Hz physical motion gamepad.</b><br>
  Pilot customized marbles through a dark timber labyrinth, jump over walls, collect relics, and battle up to 4 players on a shared laptop screen with sub-15ms local Wi-Fi latency.
</p>

[📥 **Download Controller APK (v1.0.0)**](https://github.com/trahdiscode/GameController/releases/download/v1.0.0/TiltArenaController.apk) • [📖 **Gameplay Manual**](GAMEPLAY_GUIDE.md) • [⚡ **Quick Start**](#-quick-start-in-60-seconds)

---

</div>

## 🌟 Key Highlights

- **⚡ Sub-15ms Real-Time Telemetry:** Low-latency local WebSockets stream raw 60Hz gyroscope and accelerometer packets directly into the HTML5 Canvas physics engine.
- **📷 Instant QR Code Pairing:** Built-in landscape QR scanner reads the host IP and room code directly off your laptop screen to auto-pair in under 1 second.
- **🔄 Inbuilt Natural Inverted Steering:** Gyro roll steering is mathematically inverted by default so that natural wrist tilting rolls the marble intuitively in the expected direction.
- **🕹️ 5 Pro Controller Decks:** Switch anytime between **Motion & Tilt**, **Console Gamepad Pro**, **Racing Wheel with Pedals**, **Precision Trackpad**, and **Action Deck**.
- **💥 Dual Haptic Feedback:** Real-time vibration rumble pulses on your phone for collisions, gem pickups, speed boosts, wall skips, and jumps.
- **👥 4-Player Local Multiplayer:** Up to 4 phones can connect to a single laptop arena simultaneously (P1 White, P2 Terracotta, P3 Amber, P4 Mocha).

---

## 🏗️ Architecture

```
┌─────────────────────────────────┐                 ┌─────────────────────────────────┐
│     ANDROID SMARTPHONE          │                 │         LAPTOP / HOST           │
│  Tilt Arena Controller (Flutter)│                 │    Tilt Arena Game (FastAPI)    │
│                                 │                 │                                 │
│  • 60Hz Gyro & Accelerometer    │  WebSocket LAN  │  • Python Raw Text Relay Server │
│  • Low-Pass Filter (alpha=0.40) ├────────────────►│  • HTML5 Canvas 60 FPS Physics  │
│  • Landscape-Locked Neumorphic  │  (<15ms RTT)    │  • Real-Time Multi-Carom Engine │
│  • Native Camera QR Auto-Pair   │◄────────────────┤  • Live Ping & Score Tracking   │
│  • Dual Haptic Vibration Motor  │  Haptic Events  │  • SVG QR Code Generator        │
└─────────────────────────────────┘                 └─────────────────────────────────┘
```

---

## ⚡ Quick Start in 60 Seconds

### Step 1: Start the Game on Laptop
Clone the repository and launch the local WebSocket game server:
```bash
# 1. Clone repository
git clone https://github.com/trahdiscode/GameController.git
cd GameController

# 2. Install dependencies & launch
pip install -r requirements.txt
uvicorn server.server:app --host 0.0.0.0 --port 8000
```
Open **`http://localhost:8000`** in your browser (Chrome, Edge, Firefox, or Safari). You will see the live arena with your **LAN IP**, **4-Digit Room Code**, and **Pairing QR Code**.

---

### Step 2: Connect Your Phone
1. **Download & Install the Controller:**
   - Grab the pre-built APK: [**TiltArenaController.apk**](https://github.com/trahdiscode/GameController/releases/download/v1.0.0/TiltArenaController.apk) *(or scan the QR code with your phone camera to download directly from the local LAN portal)*.
2. **Auto-Pair Instantly:**
   - Launch **Tilt Arena Controller** on your phone.
   - Tap the **QR Scanner icon** next to the Connect button.
   - Point your camera at the laptop screen — the app immediately reads the IP and Room Code and connects in 1 tap!

---

## 🎮 How to Play

> For advanced tournament rules and pro strategies, check the [Complete Gameplay Guide](GAMEPLAY_GUIDE.md).

| Maneuver | Action | Description |
| :--- | :--- | :--- |
| **Tilt Steering** | **Tilt Phone ↔ ↕** | Naturally tilt forward/backward to accelerate and left/right to steer your marble. |
| **Wall Jump** | **Tap JUMP or Shake Phone** | Hop into the air (~600ms). While airborne, your marble **flies cleanly over walls and obstacles**! |
| **Collect Relics** | **Drive over Amber Stars** | Each Amber Relic collected grants **+10 points** and triggers haptic celebration pulses. |
| **Boost Pads** | **Roll over Arrows (`▲`)** | Drive over terracotta arrow pads for rocket acceleration across corridors. |
| **Calibrate Neutral** | **Tap Calibrate** | Tap at any moment while resting comfortably to set your current wrist pose as zero neutral. |

---

## 🕹️ 5 Pro Controller Decks

Switch between 5 custom Neumorphic control decks right from the top navigation bar:

| Deck | Primary Use | Features |
| :--- | :--- | :--- |
| **📱 Motion & Tilt** | Physical Marble Racing *(Default)* | Artificial horizon, 3D spirit level, live roll/pitch degrees, neutral calibrate, giant tactile JUMP button, and shake detection. |
| **🎮 Gamepad Pro** | Classic Arcade & Twin-Stick | Dual 360° analog thumbsticks (L3/R3), 4-way D-Pad, ABXY diamond cluster, bumpers (LB/RB), triggers (LT/RT), and Turbo toggle. |
| **🏎️ Racing Wheel** | Precision Driving Simulation | Interactive on-screen touch wheel + physical gyro steering, progressive gas & brake pedals, and Nitro boost. |
| **🖱️ Trackpad** | Smooth Laptop Precision | Laptop-style low-friction trackpad surface with left, middle, and right mouse click triggers. |
| **⌨️ Action Deck** | Tactical / Flight Combat | Vertical throttle lever (0–100%), POV hat switch, primary fire, missiles, flares, and airbrake. |

> **Settings Sheet (⚙️):** Customize controller button skins (Xbox, PlayStation, Nintendo), Southpaw inverted layout, haptic rumble strength, deadzones, sensitivity curves, and steer inversion.

---

## ⚡ Low-Latency Engineering

1. **Zero-Parsing Raw Relay:** The Python server never parses sensor JSON frames. It forwards raw telemetry strings directly to the browser, eliminating deserialization bottlenecks.
2. **High-Frequency Full-State Packets:** The phone broadcasts lightweight (~100 byte) full-state frames at 60Hz. Late or dropped packets are seamlessly overwritten by the subsequent frame with zero queue latency.
3. **Continuous Exponential Moving Average:** Sensors use an optimized EMA low-pass filter (`alpha = 0.40`) to eliminate hand jitter while preserving lightning-fast physical responsiveness.
4. **Hardware Gyroscope Priority:** The app accesses Android's raw `TYPE_GYROSCOPE` and `TYPE_ACCELEROMETER` hardware sensors via NDK-level bindings.
5. **Live RTT Telemetry:** Each controller pings every second; the game echoes it back through the WebSocket relay so players can monitor real-time round-trip latency on both screens.

---

## 🛠️ Verification & Diagnostic Suite

The project includes an automated 6-suite diagnostic verification tool to ensure all endpoints, websockets, and network interfaces are functioning properly:

```bash
python diagnose.py
```

```
[1] Python modules...           [PASS] fastapi, uvicorn, segno, websockets
[2] File layout...              [PASS] server.py, game.html, controller.html
[3] HTML content checks...      [PASS] 16 critical frontend tokens verified
[4] HTTP endpoints...           [PASS] GET /, GET /controller, GET /info, GET /qr
[5] WebSocket round-trip...     [PASS] Join, sensor relay, ping/pong, haptics, leave
[6] Firewall / LAN check...     [PASS] Port 8000 reachable on LAN IP

==============================================================
  ALL CHECKS PASSED!
==============================================================
```

---

## 📦 Building the Android Controller from Source

If you wish to modify or build the Flutter application yourself:

```bash
cd flutter_app
flutter pub get
flutter run                  # Runs on connected Android device
flutter build apk --release  # Compiles to build/app/outputs/flutter-apk/app-release.apk
```

---

<div align="center">

Made with ❤️ for competitive local multiplayer gaming.

</div>
