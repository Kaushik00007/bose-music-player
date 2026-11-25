# 🎵 Bose Music Player – Flutter Music Player with a Three-Band Equalizer

## 🧩 Introduction
Bose Music Player is a simple Flutter desktop music player developed as part of the **Bose Software Development Intern practical challenge**.
It combines core playback controls with a real-time, three-band equalizer that maps simple Low / Mid / High controls onto ten underlying DSP frequency bands.

**Platform targeted:** 🐧 Linux Desktop

## 🎬 Demo Video
▶️ **[Watch the demo video](ADD_YOUR_VIDEO_LINK_HERE)**

## 🎯 Features
- **Bundled Tracks** – Four audio tracks included with the application (loaded from assets).
- **Playback Controls** – Play, pause and resume playback.
- **Track Navigation** – Next and previous track controls with wrap-around.
- **Auto-Advance** – Automatically plays the next track when the current one finishes.
- **Now Playing Info** – Current track name, elapsed time and total duration.
- **Seek Bar** – Smooth, draggable progress slider; the app seeks when the drag is released.
- **Three-Band Equalizer** – Low, Mid and High sliders.
- **Real-Time Adjustments** – Gain adjustable from **-12 dB to +12 dB** in 0.5 dB steps while audio plays.
- **Reset to Flat** – One-click reset of all equalizer bands (disabled when already flat).
- **Persistent EQ Settings** – Equalizer settings are preserved when switching tracks.
- **Polished, Responsive UI** – Dark charcoal and teal design with a single-screen layout: player and equalizer are visible together without scrolling on a typical 1080p window, with a scroll fallback on smaller windows.
- **Clear Control States** – Loading and disabled states are visually distinct (dimmed controls, loading spinner, dimmed seek bar).

## 🛠️ Tech Stack

### 🖥️ Application
![Flutter](https://img.shields.io/static/v1?label=Framework&message=Flutter&color=02569B&logo=flutter&style=flat-square)
![Dart](https://img.shields.io/static/v1?label=Language&message=Dart&color=0175C2&logo=dart&style=flat-square)
![Material UI](https://img.shields.io/static/v1?label=UI&message=material_ui&color=757575&logo=materialdesign&style=flat-square)

### 🔊 Audio & DSP
![miniaudio_player](https://img.shields.io/static/v1?label=Audio&message=miniaudio_player&color=FF6F00&style=flat-square)

### 🐧 Target Platform
![Linux](https://img.shields.io/static/v1?label=Platform&message=Linux%20Desktop&color=FCC624&logo=linux&logoColor=black&style=flat-square)

### 📦 Packages Used
| Package | Purpose |
|---------|---------|
| `miniaudio_player` | Audio playback, seeking, position/duration/completion streams, and the 10-band equalizer |
| `material_ui` | UI components and theming |

## 🏗️ Architecture
The app is intentionally small and lives in `lib/main.dart`, organised as follows:

| Component | Responsibility |
|-----------|----------------|
| `main()` | Initialises Flutter and configures the asset loader so bundled audio can be played by `miniaudio_player` |
| `BoseMusicApp` | App root: dark theme, teal accent, slider styling (including disabled states) |
| `PlayerScreen` / `_PlayerScreenState` | Owns the player instance and all state: current track, loading, playing, seeking, and EQ gains. Contains playback logic (load, play/pause, next/previous, auto-advance, seek) and equalizer logic |
| `_ControlButton` | Round previous / next button with a consistent size and dimmed disabled state |
| `_PlayPauseButton` | Primary play/pause button with animated icon and loading spinner |

**Data flow:** UI widgets call methods on `_PlayerScreenState` (play, seek, set EQ band) → the state calls `player.action.*` on `miniaudio_player` → the position, duration and completion streams from `player.stream` update the UI (seek bar, time labels, auto-advance).

**Design decisions**
- **Bundled assets over streaming/API:** the challenge allows bundled audio. Local files keep playback and seeking reliable and the app fully offline.
- **Single source of truth for EQ:** the Low / Mid / High values are held in state and the equalizer gains are rebuilt from the player's current EQ on every change.
- **Guarded track switching:** a flag prevents overlapping track loads from rapid taps or auto-advance.

## 🎚️ Equalizer Implementation
The player exposes three user-facing frequency controls, each driving a group of the ten DSP bands provided by `miniaudio_player`:

| Control | DSP Bands | Gain Range |
|---------|-----------|------------|
| 🔈 **Low** | Bands 0–2 | -12 dB to +12 dB |
| 🔉 **Mid** | Bands 3–6 | -12 dB to +12 dB |
| 🔊 **High** | Bands 7–9 | -12 dB to +12 dB |

**How it works**
1. On a slider change, the app reads the current gains from `player.state.equalizer`.
2. It sets every band in that control's group to the slider value.
3. It applies the result with `player.action.setEqualizer(Equalizer.fromList(gains))`, so the change is heard immediately while audio plays.
4. **Reset** applies `Equalizer.flat`, returning all bands to 0 dB.
5. When a new track is opened, the current equalizer is re-applied, so EQ settings persist across tracks.

The ±12 dB range gives a clearly audible change without excessive distortion.

## 📁 Project Structure
```
bose_music_player/
├── assets/
│   └── musics/
│       ├── sample.mp3
│       ├── track2.mp3
│       ├── track3.mp3
│       └── track4.mp3
├── lib/
│   └── main.dart
├── test/
│   └── widget_test.dart
├── pubspec.yaml
└── README.md
```

## 🎧 Audio Assets
The bundled tracks are included for demonstration purposes only. To use your own audio, place files in `assets/musics/`, declare them in `pubspec.yaml`, and update the track lists in `lib/main.dart`.

## ⚙️ Installation & Running

### Requirements
- Flutter SDK
- Dart SDK
- Linux desktop development dependencies (for the Linux target)

Clone the repository:
```bash
git clone https://github.com/Kaushik00007/bose-music-player.git
cd bose-music-player
```

Install dependencies:
```bash
flutter pub get
```

Run the application:
```bash
flutter run -d linux
```

## 💻 Usage
1. Launch the app on Linux desktop.
2. Press **Play** to start the first track; use **Pause** to pause and **Play** again to resume.
3. Use **Next** and **Previous** to move between tracks.
4. Drag the **progress slider** to seek within the current track.
5. Adjust the **Low**, **Mid** and **High** sliders to shape the sound in real time.
6. Press **Reset** to return the equalizer to a flat response.

## 📚 Challenges & Learnings
- **Seeking reliably:** the seek bar must not be overwritten by position updates while the user drags. The app keeps a local drag position during scrubbing and performs the actual seek only when the drag ends.
- **Track switching and completion:** handling asynchronous load, auto-advance and rapid taps without overlapping track loads.
- **Keeping the EQ across tracks:** opening a new source resets the audio pipeline, so the current equalizer is re-applied after each load.
- **Three controls, ten bands:** mapping Low / Mid / High to groups of DSP bands so each slider produces an audible, predictable change.
- **Fitting everything on one screen:** the artwork height and spacing scale with the window so the player and equalizer stay visible together on a typical 1080p window, with a scroll fallback on smaller windows.

## 🤖 AI Tools Disclosure
AI tools were used as assistants during development:

- **ChatGPT** – Planning and debugging help.
- **Kilo Code with OmniRoute** – Code inspection and playlist implementation.
- **Claude** – UI spacing/layout polish and README help.

I reviewed and tested all changes and made the final design decisions.

## 📄 License
This project was developed as an internship practical challenge.

## 📩 Contact
For queries or collaboration, reach out via:
- <img src="https://skillicons.dev/icons?i=gmail" width="20" valign="middle" /> Email: [kaushi00007@gmail.com](mailto:kaushi00007@gmail.com)
- <img src="https://skillicons.dev/icons?i=linkedin" width="20" valign="middle" /> LinkedIn: [Kaushik K](https://www.linkedin.com/in/kaushik-k-dev)
- <img src="https://skillicons.dev/icons?i=github" width="20" valign="middle" /> GitHub: [Kaushik00007](https://github.com/Kaushik00007)

---

<p align="center">
  <b>Bose Music Player</b> – Simple playback, precise sound control.<br>
  <img src="https://img.shields.io/static/v1?label=Built%20With&message=Flutter&color=02569B&logo=flutter&style=for-the-badge" />
  <img src="https://img.shields.io/static/v1?label=Built%20With&message=Dart&color=0175C2&logo=dart&style=for-the-badge" />
  <img src="https://img.shields.io/static/v1?label=Platform&message=Linux&color=FCC624&logo=linux&logoColor=black&style=for-the-badge" />
</p>
