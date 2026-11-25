# 🎵 Bose Music Player – Flutter Music Player with a Three-Band Equalizer

## 🧩 Introduction
Bose Music Player is a simple Flutter-based desktop music player developed as part of the **Bose Software Development Intern practical challenge**.
It combines core playback controls with a real-time, three-band equalizer that maps simple Low / Mid / High controls onto ten underlying DSP frequency bands.

## 🎯 Features
- **Bundled Tracks** – Four audio tracks included with the application.
- **Playback Controls** – Play, pause and resume playback.
- **Track Navigation** – Next and previous track controls.
- **Auto-Advance** – Automatically plays the next track when the current one finishes.
- **Progress Slider** – Seekable slider with elapsed and total duration.
- **Three-Band Equalizer** – Low, Mid and High controls.
- **Real-Time Adjustments** – Gain adjustable from **-12 dB to +12 dB** while audio plays.
- **Reset to Flat** – One-click reset of all equalizer bands.
- **Persistent EQ Settings** – Equalizer settings are preserved when switching tracks.

## 🛠️ Tech Stack

### 🖥️ Application
![Flutter](https://img.shields.io/static/v1?label=Framework&message=Flutter&color=02569B&logo=flutter&style=flat-square)
![Dart](https://img.shields.io/static/v1?label=Language&message=Dart&color=0175C2&logo=dart&style=flat-square)
![Material UI](https://img.shields.io/static/v1?label=UI&message=material_ui&color=757575&logo=materialdesign&style=flat-square)

### 🔊 Audio & DSP
![miniaudio_player](https://img.shields.io/static/v1?label=Audio&message=miniaudio_player&color=FF6F00&style=flat-square)

### 🐧 Target Platform
![Linux](https://img.shields.io/static/v1?label=Platform&message=Linux%20Desktop&color=FCC624&logo=linux&logoColor=black&style=flat-square)

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

## 🎚️ Equalizer Implementation
The player exposes three user-facing frequency controls, each driving a group of DSP bands:

| Control | DSP Bands | Gain Range |
|---------|-----------|------------|
| 🔈 **Low** | Bands 0–2 | -12 dB to +12 dB |
| 🔉 **Mid** | Bands 3–6 | -12 dB to +12 dB |
| 🔊 **High** | Bands 7–9 | -12 dB to +12 dB |

Each control adjusts its corresponding bands in real time, and the equalizer can be reset to a flat response at any point.

## ⚙️ Installation

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
- Integrating audio playback into a Flutter application.
- Managing track switching and playback completion.
- Maintaining equalizer settings across track changes.
- Mapping three user-facing equalizer controls to ten DSP frequency bands.
- Handling asynchronous audio operations and preventing overlapping track switches.

## 🤖 AI Tools Disclosure
AI tools were used during development:

- **ChatGPT** – Planning, technical guidance, debugging assistance, and reviewing implementation decisions.
- **Kilo Code with OmniRoute** – Code inspection and implementation of playlist functionality.

All generated changes were reviewed and the application was manually tested.

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