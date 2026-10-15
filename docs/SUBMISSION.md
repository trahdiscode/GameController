# Submission checklist

1. **Drop in your files:** put the Antigravity output in `web/` (`game.html`, `controller.html`, extras). Do not rename these two.
2. **Local test:** `uvicorn server.server:app --host 0.0.0.0 --port 8000`. Open `http://localhost:8000`, pair, play.
3. **Firewall:** allow port 8000 on Private networks (see README) so the phone can reach the laptop.
4. **Build the APK** (Node 20+, Android Studio):
   ```
   cd app
   npm install
   npx cap add android
   ```
   Add `<uses-permission android:name="android.permission.VIBRATE"/>` to `app/android/app/src/main/AndroidManifest.xml`, then:
   ```
   npm run android
   ```
   In Android Studio: **Build > Build Bundle(s) / APK(s) > Build APK(s)**. File: `app/android/app/build/outputs/apk/debug/app-debug.apk`. Rerun `npm run android` after every controller change. Install on the phone (allow unknown apps).
5. **Play with the APK:** laptop opens `http://localhost:8000`; in the app enter `LAPTOP_IP:8000` (from `ipconfig`) and the room code.
6. **Screen recording:** show the laptop game and the phone in one shot. Options: film the phone and laptop with a second phone, or record the laptop with Win+G and the phone with its built-in screen recorder, then side by side. Show: pairing by code or QR, tilt steering, shake jump, calibration, a disconnect and automatic recovery (turn Wi-Fi off and on), the latency number.
7. **README:** edit `README.md` so the game description matches your game. Keep tech stack, pairing, latency and reliability sections.
8. **GitHub:**
   ```
   git init
   git add .
   git commit -m "Phone motion controller"
   git branch -M main
   git remote add origin https://github.com/<you>/<repo>.git
   git push -u origin main
   ```
   Upload `app-debug.apk` under **Releases > Draft a new release**, and put the video link in the README.
9. **Final check:** repo has app, game, server; APK link works; video attached; README covers stack, pairing, latency.
