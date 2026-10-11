# Sonora

Light Qt6/QML music player and sound library with playlists, Material You theme, and system hotkeys.

## Features

- Audio library (mp3, flac, m4a, opus, wav, and more)
- Playlists (create, delete, add tracks)
- Play modes: replace / overlay / queue
- Dynamic Color (system accent or from image)
- Native folder/file dialogs (Dolphin / Explorer)
- Drag & drop files and folders

## Build and install

```bash
./install.sh
```

Installs to `~/.local/bin/sonora` and adds a desktop menu entry.

Dependencies: Qt 6.6+ (Core, Gui, Widgets, Qml, Quick, Multimedia), CMake, Ninja, g++.

```bash
# Arch
sudo pacman -S qt6-base qt6-declarative qt6-multimedia cmake ninja gcc

# Ubuntu
sudo apt install qt6-base-dev qt6-declarative-dev qt6-multimedia-dev cmake ninja-build g++
```

Manual build:

```bash
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
./build/Sonora
```

## Structure

- `qml/` — UI (Material 3)
- `src/library/` — library, playlists, filters
- `src/audio/` — playback (QMediaPlayer)
- `src/theme/` — Dynamic Color (OKLCH)
- `src/hotkeys/` — global hotkeys (Windows)
