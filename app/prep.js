// Copies web/ into app/www/ for the APK: controller.html becomes index.html, game.html is dropped.
const fs = require("fs"), path = require("path");
fs.rmSync("www", { recursive: true, force: true });
fs.cpSync("../web", "www", { recursive: true });
fs.renameSync(path.join("www", "controller.html"), path.join("www", "index.html"));
fs.rmSync(path.join("www", "game.html"), { force: true });
console.log("www/ ready");
