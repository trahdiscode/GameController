# 🎮 Tilt Arena — Official Gameplay Guide & Player Manual

Welcome to **Tilt Arena**, a real-time multiplayer marble labyrinth game where your smartphone transforms into a high-precision, low-latency physical motion controller.

---

## 📖 Table of Contents
1. [Quick Start (3-Step Setup)](#-quick-start-3-step-setup)
2. [Game Objective & Rules](#-game-objective--rules)
3. [Arena Elements & Mechanics](#-arena-elements--mechanics)
4. [Control Schemes & Controller Modes](#-control-schemes--controller-modes)
5. [Haptic & Audio Feedback](#-haptic--audio-feedback)
6. [Multiplayer Battle (Up to 4 Players)](#-multiplayer-battle-up-to-4-players)
7. [Pro Tips & Winning Strategies](#-pro-tips--winning-strategies)
8. [Troubleshooting & Calibration](#-troubleshooting--calibration)

---

## ⚡ Quick Start (3-Step Setup)

```
[ Laptop: Browser Game ] <==== (Local Wi-Fi / WebSockets) ====> [ Phone: Motion Controller ]
     http://localhost:8000                                          APK or Mobile Web
```

1. **Host the Game (Laptop)**:
   - Run the server: `python -m uvicorn server.server:app --host 0.0.0.0 --port 8000`
   - Open `http://localhost:8000` in Chrome, Edge, or Safari.
   - Note the **4-digit room code** and **QR code** on your screen.

2. **Connect the Controller (Phone)**:
   - Ensure your phone is connected to the **same Wi-Fi network**.
   - **Recommended (Android APK):** Download and install from `http://<LAPTOP_IP>:8000/apk`. Open the app, enter your laptop's IP and room code, and tap **Connect**.
   - **Alternative (Mobile Browser):** Scan the QR code with your camera (requires an HTTPS tunnel like Cloudflare Tunnel or ngrok for web sensor permissions).

3. **Calibrate & Play**:
   - Hold your phone comfortably in both hands at your natural resting angle.
   - Tap **Calibrate** to set your neutral zero-tilt position.
   - Tilt your phone to roll your marble across the arena!

---

## 🎯 Game Objective & Rules

- **Goal**: Score the highest points by maneuvering your marble to collect **Amber Relics (Star Gems)** scattered across the arena floor before your opponents do.
- **Scoring**:
  - Each collected Relic awards **+10 points**.
  - A collected relic immediately respawns in a new random safe location in the labyrinth.
- **Round Duration**: Unlimited freeplay / endless arena tournament. The player with the highest score displayed on the live scoreboard wins!

---

## 🗺️ Arena Elements & Mechanics

| Element | Appearance | Function |
| :--- | :--- | :--- |
| **Player Marbles** | Spheres with realistic 3D lighting & shadows | Your avatar in the arena. P1 is Pure White, P2 is Terracotta, P3 is Caramel Amber, P4 is Roasted Mocha. |
| **Amber Relics** | Glowing gold diamonds with white specular centers | Worth **+10 pts**. Drives score competition. Emits particle bursts and sends a vibration pulse when collected. |
| **Timber Obstacles** | Solid roasted walnut timber blocks | Hard boundaries. Colliding at high speed bounces your marble back and triggers a vibration bump on your phone. |
| **Speed Boost Pads** | Terracotta arrow strips (`▲` / `▼`) | Rocket accelerators! Rolling across a pad launches your marble forward with intense directional thrust. |
| **Shockwave Hop** | Expanding concentric energy ring | Triggered when you jump or shake. Elevates your marble above the arena floor. |
| **Outer Perimeter** | Arena boundary cushions | Prevents your marble from rolling out of bounds; provides elastic bounce. |

---

## 🕹️ Control Schemes & Controller Modes

Tilt Arena supports multiple input styles selectable directly from the controller's top mode bar:

### 1. 📱 Motion & Tilt Mode (Recommended Default)
- **Steer / Roll**: Tilt your phone in any direction.
  - Tilt forward/backward $\rightarrow$ Accelerate up/down.
  - Tilt left/right $\rightarrow$ Steer left/right.
- **Hop & Leap (Airborne)**:
  - **Quick Shake**: Give your phone a brisk upward flick/shake to leap into the air.
  - **JUMP Button**: Tap the large tactile on-screen **JUMP** button.
  - *Airborne perk*: While airborne (~600ms), your marble hops completely **over internal walls and obstacles** without colliding!
- **Calibrate**: Tap the **Calibrate** button at any time to re-center your resting posture.

### 2. 🎮 Gamepad Pro Mode
- **Left Analog Stick**: Full 360° fluid directional thumbstick steering.
- **4-Way D-Pad**: Crisp cardinal directional taps.
- **A Button / Fire**: Jump / hop over walls.
- **B Button / Nitro (RT)**: Activate 103% turbo nitro speed boost with flame trail particles.
- **Left Trigger (LT)**: Handbrake / drift brake to quickly slow down around sharp corners.

### 3. 🏎️ Racing Wheel Mode
- **Steering Wheel**: Rotate the on-screen steering wheel or tilt your phone like a physical racecar wheel.
- **Gas Pedal (Green)**: Progressive acceleration forward.
- **Brake Pedal (Red)**: Deceleration / reverse.
- **Handbrake**: Instant 180° drift spin.
- **Nitro Toggle**: Sudden speed explosion.

### 4. ⌨️ Action Deck & Trackpad Modes
- **Trackpad**: Swipe across the tactile pad surface to flick and direct the marble.
- **Throttle Lever**: Set steady forward cruising speed with tactical macro buttons.

### 5. 💻 Keyboard Fallback (Player 0)
No phone? A spectator on the laptop can join as a 5th player using physical keyboard keys:
- **Steer**: <kbd>▲</kbd> <kbd>◀</kbd> <kbd>▼</kbd> <kbd>▶</kbd> Arrow Keys or <kbd>W</kbd> <kbd>A</kbd> <kbd>S</kbd> <kbd>D</kbd>.
- **Hop / Jump**: <kbd>Spacebar</kbd>.

---

## 📳 Haptic & Audio Feedback

Tilt Arena features sensory haptic integration sent over WebSockets back to your mobile hardware:

1. **Wall Impact**:
   - Severe impact against a wall triggers a physical vibration bump (`40ms`) and a low-pitch acoustic percussion thud.
2. **Speed Boost Pad Launch**:
   - Triggering a boost pad fires an amber particle shower, vibration buzz (`50ms`), and high-speed swoosh.
3. **Relic Collection**:
   - Grabbing an amber relic plays an acoustic marimba chime (`580Hz`), spawns 16 radiant particles, and gives a haptic reward pulse (`60ms`).

---

## 👥 Multiplayer Battle (Up to 4 Players)

You can connect up to **4 mobile phones simultaneously** to a single laptop display:

| Slot | Color Tag | Marble Material | Default Hue |
| :---: | :---: | :--- | :--- |
| **Player 1** | `P1` | Brilliant Pure White Porcelain | White & Ivory |
| **Player 2** | `P2` | Terracotta Sienna Ceramic | Warm Terracotta |
| **Player 3** | `P3` | Caramel Amber Stone | Golden Sand |
| **Player 4** | `P4` | Roasted Mocha Quartz | Dark Roasted Brown |
| **Player 0** | `KB` | Slate Ash Taupe | Keyboard Standby |

- **Real-Time Scoreboard**: Located at the top of the game screen, tracking live points, controller mode badge, and latency (RTT in milliseconds).
- **Slot Reclamation**: If a player temporarily disconnects, their slot and score are safely preserved upon reconnecting.

---

## 💡 Pro Tips & Winning Strategies

1. **Wall Hopping Shortcut**:
   - Don't navigate the entire maze corridor! Face a wall, initiate forward tilt, and tap **JUMP** or shake your phone to sail cleanly over the wall directly toward a relic on the opposite side.
2. **Boost Pad Slingshot**:
   - Steer directly into a boost pad while tilting in the direction of the arrow to achieve super-terminal velocity across the arena.
3. **Corner Drifting**:
   - When approaching a sharp turn at high speed, use the Handbrake button or tilt opposite your momentum to execute a snappy slide.
4. **Re-Calibrate When Switching Posture**:
   - If you switch from sitting upright to leaning back on a sofa, tap **Calibrate** immediately so your neutral tilt angle adapts to your new body posture.

---

## 🔧 Troubleshooting & Calibration

- **Marble drifting on its own?**
  - Hold the phone still in your desired neutral position and tap **Calibrate**.
- **Lag or high latency (>30ms)?**
  - Verify that both laptop and phone are on the **5GHz Wi-Fi band** of the same router rather than a congested 2.4GHz network.
  - Use the native APK rather than an online tunnel for direct LAN speed (<10ms).
- **Need to pause or reset?**
  - Simply disconnect or refresh the browser. The room code persists in `sessionStorage` so you won't lose your session.

Enjoy playing **Tilt Arena**! 🏆
