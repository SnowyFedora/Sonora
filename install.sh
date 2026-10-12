#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${ROOT}/build"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"

red()  { printf '\033[1;31m%s\033[0m\n' "$*"; }
grn()  { printf '\033[1;32m%s\033[0m\n' "$*"; }
ylw()  { printf '\033[1;33m%s\033[0m\n' "$*"; }
info() { printf '→ %s\n' "$*"; }

SYSTEM=0
for arg in "$@"; do
  case "$arg" in
    --system|-s) SYSTEM=1 ;;
    --user|-u)   SYSTEM=0 ;;
    --help|-h)
      echo "Usage: ./install.sh [--user|--system]"
      exit 0
      ;;
  esac
done

if [[ -n "${PREFIX:-}" ]]; then
  :
elif [[ "$SYSTEM" -eq 1 ]]; then
  PREFIX="/usr/local"
else
  PREFIX="$HOME/.local"
fi

if [[ "$PREFIX" == /usr* || "$PREFIX" == /opt* ]]; then
  if [[ "$(id -u)" -ne 0 ]]; then
    ylw "System install to ${PREFIX} needs root. Re-running with sudo…"
    exec sudo env "PREFIX=$PREFIX" "JOBS=$JOBS" bash "$0" --system
  fi
fi

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    red "Missing: $1"
    return 1
  fi
}

info "Checking dependencies…"
MISSING=0
for bin in cmake ninja g++ pkg-config; do
  if ! need "$bin"; then MISSING=1; fi
done

if ! pkg-config --exists Qt6Core Qt6Gui Qt6Widgets Qt6Qml Qt6Quick Qt6QuickControls2 Qt6Multimedia 2>/dev/null; then
  if ! command -v qmake6 >/dev/null 2>&1 && ! command -v qtpaths6 >/dev/null 2>&1; then
    red "Qt6 dev packages not found"
    ylw "Arch:   sudo pacman -S qt6-base qt6-declarative qt6-multimedia cmake ninja gcc"
    ylw "Fedora: sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtmultimedia-devel cmake ninja-build gcc-c++"
    ylw "Ubuntu: sudo apt install qt6-base-dev qt6-declarative-dev qt6-multimedia-dev cmake ninja-build g++"
    MISSING=1
  fi
fi

if [[ "$MISSING" -ne 0 ]]; then
  red "Install dependencies and run again: ./install.sh"
  exit 1
fi
grn "Dependencies OK"

info "Clean build…"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

info "Building (Ninja, ${JOBS} jobs)…"
cmake -S "$ROOT" -B "$BUILD_DIR" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX"
cmake --build "$BUILD_DIR" -j"$JOBS"

info "Installing to ${PREFIX}…"
cmake --install "$BUILD_DIR"

BIN_SRC="${PREFIX}/bin/Sonora"
BIN_DST="${PREFIX}/bin/sonora"
if [[ -x "$BIN_SRC" ]]; then
  ln -sfn "Sonora" "$BIN_DST"
fi

APP_DIR="${PREFIX}/share/applications"
mkdir -p "$APP_DIR"
cat > "${APP_DIR}/sonora.desktop" << DESKTOP
[Desktop Entry]
Type=Application
Name=Sonora
GenericName=Music Player
Comment=Lightweight music player and sound library
Exec=${PREFIX}/bin/sonora %F
TryExec=${PREFIX}/bin/sonora
Icon=audio-headphones
Terminal=false
Categories=AudioVideo;Audio;Player;
Keywords=music;soundboard;playlist;audio;
StartupNotify=true
MimeType=audio/mpeg;audio/mp3;audio/x-mp3;audio/flac;audio/x-flac;audio/ogg;audio/x-vorbis+ogg;audio/opus;audio/aac;audio/mp4;audio/x-m4a;audio/wav;audio/x-wav;audio/x-aiff;audio/aiff;audio/x-ms-wma;audio/webm;inode/directory;
DESKTOP

if [[ "$PREFIX" == "$HOME/.local" ]]; then
  if [[ ":$PATH:" != *":${PREFIX}/bin:"* ]]; then
    ylw "Add to ~/.bashrc:"
    echo "  export PATH=\"${PREFIX}/bin:\$PATH\""
    export PATH="${PREFIX}/bin:$PATH"
  fi
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${PREFIX}/share/applications" 2>/dev/null || true
fi

info "Smoke test…"
if [[ -x "$BIN_DST" ]]; then
  if strings "$BIN_DST" 2>/dev/null | grep -q "0.2.1"; then
    grn "Binary has 0.2.1 marker — OK"
  else
    ylw "Warning: 0.2.1 marker not found in binary"
  fi
  if QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-offscreen}" timeout 3 "$BIN_DST" >/tmp/sonora-smoke.log 2>&1; then
    grn "Launch OK"
  else
    code=$?
    if [[ $code -eq 124 ]]; then
      grn "Launch OK (timeout — GUI started)"
    else
      ylw "Exit code $code"
    fi
  fi
else
  red "Binary not found: $BIN_DST"
  exit 1
fi

grn "Done! Sonora 0.2.1"
echo
echo "  Install:  ${PREFIX}"
echo "  Run:      ${PREFIX}/bin/sonora"
echo "  Or:       sonora"
echo
echo "  User:     ./install.sh"
echo "  System:   ./install.sh --system"
echo
