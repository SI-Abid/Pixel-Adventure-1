# Pixel Adventure

A pixel-art infinite side-scrolling runner built with [LÖVE 2D](https://love2d.org/) (version 11.4).

Run, jump, stomp enemies, collect fruit combos, and activate character specials to survive an endlessly scrolling world with rising difficulty.

---

## Playing the Game

### Requirements

- **LÖVE 2D 11.4** — download from [love2d.org](https://love2d.org/)

### Run from source

```bash
# Clone or extract the project, then:
love "Pixel Adventure 1"

# Or from inside the project directory:
love .
```

### Visual test window

```bash
love . --test
```

---

## Controls

| Key | Action |
|-----|--------|
| Arrow Right / D | Move right |
| Arrow Left / A | Move left |
| Space / Up / W | Jump (double-jump supported) |
| E or F | Activate special power (when Power Bar is full) |
| Escape | Quit |
| R (game over screen) | Return to menu |

---

## Characters

Each character has unique stats and a special power charged by collecting the same fruit in a row.

| Character | Speed | Jump | Favorite Fruit | Special Power |
|-----------|-------|------|----------------|---------------|
| Mask Dude | Fast | Mid | Apple | **Speed Surge** — 1.6× speed for 8s |
| Ninja Frog | Fastest | Low | Kiwi | **Triple Jump** — 3 mid-air jumps for 12s |
| Pink Man | Slow | Highest | Strawberry | **Shield** — full invincibility for 10s |
| Virtual Guy | Balanced | Mid | Melon | **Score Rush** — 2× score multiplier for 15s |

---

## Enemies & Hazards

- **Chicken / Mushroom / Pig** — patrol platforms; stomp from above to kill (+20 pts)
- **Saw** — oscillates on a track; instant damage on contact
- **Fire Trap** — triggers on first touch and cycles on/off

---

## Project Structure

```
Pixel Adventure 1/
├── main.lua              # Love2D callbacks, game state machine
├── conf.lua              # Window config (800×450, vsync, title)
├── test.lua              # Visual test window entry point
├── src/                  # Pure Lua game logic (no love.graphics)
│   ├── player.lua
│   ├── player_state.lua
│   ├── char_profiles.lua
│   ├── animation.lua
│   ├── animation_controller.lua
│   ├── level.lua
│   ├── runner_level.lua
│   ├── enemy_base.lua
│   ├── enemy_chicken.lua
│   ├── enemy_mushroom.lua
│   ├── enemy_pig.lua
│   ├── pig.lua
│   ├── saw_logic.lua
│   ├── fire_logic.lua
│   ├── trap_fire.lua
│   ├── trap.lua
│   └── menu.lua
├── spec/                 # busted unit tests
├── assets/               # Sprites, tilemaps, sounds
└── docs/                 # Design plans
```

---

## Running Tests

Tests use the [busted](https://lunarmodules.github.io/busted/) framework.

```bash
# Install busted (requires LuaRocks)
luarocks install busted

# Run all tests
busted spec/
```

---

## Building for Distribution

All distribution formats start from a `.love` file — a ZIP archive containing the game with `main.lua` at its root.

### Step 1 — Create the `.love` file

From the project's **parent** directory:

```bash
# Linux / macOS
cd "Pixel Adventure 1"
zip -9 -r ../PixelAdventure.love . --exclude "*.git*" --exclude "spec/*" --exclude "docs/*"

# Windows (PowerShell)
Compress-Archive -Path ".\*" -DestinationPath "..\PixelAdventure.zip"
Rename-Item "..\PixelAdventure.zip" "PixelAdventure.love"
```

`main.lua` must be at the **root** of the archive (not inside a subfolder).

---

### Windows

1. Download the official **LÖVE 11.4 Windows** zip from [love2d.org](https://love2d.org/).
2. Extract it; note `love.exe` and the DLL files.
3. Fuse the `.love` file into a standalone executable:

   ```bat
   copy /b love.exe+PixelAdventure.love PixelAdventure.exe
   ```

4. Distribute **`PixelAdventure.exe`** alongside all DLL files from the Love2D zip.
5. *(Optional)* Wrap in an installer with [InnoSetup](https://jrsoftware.org/isinfo.php).

---

### macOS

1. Download the official **LÖVE 11.4 macOS** `.app` bundle from [love2d.org](https://love2d.org/).
2. Copy the bundle and embed the game:

   ```bash
   cp -r love.app PixelAdventure.app
   cp PixelAdventure.love PixelAdventure.app/Contents/Resources/
   ```

3. Update `PixelAdventure.app/Contents/Info.plist`:
   - `CFBundleName` → `Pixel Adventure`
   - `CFBundleIdentifier` → e.g. `com.yourname.pixeladventure`
   - `CFBundleShortVersionString` → `1.0.0`

4. Zip and distribute:

   ```bash
   zip -r PixelAdventure-mac.zip PixelAdventure.app
   ```

> **Note:** macOS 12+ requires apps to be notarized with an Apple Developer account to run without Gatekeeper warnings. See [Apple's notarization guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution).

---

### Linux

**Option A — AppImage (recommended, no install required)**

Use [love-appimage-starter](https://github.com/love2d-community/love-appimage-starter) or bundle LÖVE manually into an AppImage. The result runs on any glibc 2.17+ distro (Ubuntu 14.04+, Fedora 20+).

**Option B — Distribute the `.love` file directly**

Users install LÖVE themselves, then run:

```bash
love PixelAdventure.love
```

Package managers: `sudo apt install love` / `sudo pacman -S love` / `sudo dnf install love`

**Option C — Automated builds with GitHub Actions**

Use the community [love-actions](https://github.com/marketplace?query=love-action) GitHub Actions to build all platforms automatically on push.

---

### Android

> Requires Android Studio and the [love-android](https://github.com/love2d/love-android) source.

1. Clone the love-android repository and open it in Android Studio.
2. Rename your `.love` file to exactly **`game.love`**.
3. Place it in `app/src/embed/assets/game.love`.
4. Edit `app/build.gradle`:
   ```groovy
   applicationId "com.yourname.pixeladventure"
   versionCode 1
   versionName "1.0.0"
   ```
5. Edit `app/src/main/AndroidManifest.xml` — set `android:label="Pixel Adventure"`.
6. Build the APK:
   ```bash
   ./gradlew assembleEmbedNoRecordRelease
   ```
   For Google Play (AAB format):
   ```bash
   ./gradlew bundleEmbedNoRecordRelease
   ```

---

### iOS

> Requires Xcode and an Apple Developer account.

1. Clone [love-ios](https://github.com/love2d/love-ios) and open in Xcode.
2. Place your `.love` file in the project's resources directory.
3. Configure signing, bundle identifier, and display name in Xcode project settings.
4. Archive and distribute via TestFlight or the App Store.

---

### Automated cross-platform builds (recommended)

[love-build](https://github.com/ellraiser/love-build) can compile Windows, macOS, Linux, and Steam Deck builds from a single `build.lua` config file — runnable from any OS.

---

## Dependencies

| Dependency | Purpose | Install |
|------------|---------|---------|
| LÖVE 2D 11.4 | Game runtime | [love2d.org](https://love2d.org/) |
| Lua 5.1+ | Scripting (bundled with LÖVE) | — |
| busted | Unit testing | `luarocks install busted` |

---

## License

Assets are from the **Pixel Adventure** asset pack by [Pixelfrog](https://pixelfrog-assets.itch.io/pixel-adventure-1) (free for personal and commercial use — check the pack's license for details).

Game source code: see [LICENSE](LICENSE) if present, otherwise all rights reserved.
