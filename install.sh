#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${ROOT}/build"
PREFIX="${PREFIX:-$HOME/.local}"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"

red()  { printf '\033[1;31m%s\033[0m\n' "$*"; }
grn()  { printf '\033[1;32m%s\033[0m\n' "$*"; }
ylw()  { printf '\033[1;33m%s\033[0m\n' "$*"; }
info() { printf '-> %s\n' "$*"; }

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    red "Missing: $1"
    return 1
  fi
}

info "Checking dependencies..."
MISSING=0
for bin in cmake ninja g++ pkg-config; do
  if ! need "$bin"; then MISSING=1; fi
done

if ! pkg-config --exists Qt6Core Qt6Gui Qt6Widgets Qt6Qml Qt6Quick Qt6QuickControls2 Qt6Multimedia 2>/dev/null; then
  if ! command -v qmake6 >/dev/null 2>&1 && ! command -v qtpaths6 >/dev/null 2>&1; then
    red "Qt6 dev packages not found"
    ylw "Arch:   sudo pacman -S qt6-base qt6-declarative qt6-multimedia cmake ninja gcc"
    ylw "Ubuntu: sudo apt install qt6-base-dev qt6-declarative-dev qt6-multimedia-dev cmake ninja-build g++"
    MISSING=1
  fi
fi

if [[ "$MISSING" -ne 0 ]]; then
  red "Install dependencies and run: ./install.sh"
  exit 1
fi
grn "Dependencies OK"

info "Building (Ninja, ${JOBS} jobs)..."
cmake -S "$ROOT" -B "$BUILD_DIR" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX"
cmake --build "$BUILD_DIR" -j"$JOBS"

info "Installing to ${PREFIX}..."
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
Comment=Light music player and sound library
Exec=${PREFIX}/bin/sonora
Icon=audio-headphones
Terminal=false
Categories=AudioVideo;Audio;Player;
Keywords=music;soundboard;playlist;audio;
StartupNotify=true
DESKTOP

if [[ ":$PATH:" != *":${PREFIX}/bin:"* ]]; then
  ylw "Add to ~/.bashrc:"
  echo "  export PATH=\"${PREFIX}/bin:\$PATH\""
  export PATH="${PREFIX}/bin:$PATH"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${PREFIX}/share/applications" 2>/dev/null || true
fi

info "Smoke test..."
if [[ -x "$BIN_DST" ]]; then
  if QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-offscreen}" timeout 3 "$BIN_DST" >/tmp/sonora-smoke.log 2>&1; then
    grn "Launch OK"
  else
    code=$?
    if [[ $code -eq 124 ]]; then
      grn "Launch OK (timeout - GUI started)"
    else
      ylw "Exit code $code. Try: ${PREFIX}/bin/sonora"
      cat /tmp/sonora-smoke.log 2>/dev/null || true
    fi
  fi
else
  red "Binary not found: $BIN_DST"
  exit 1
fi

grn "Done!"
echo
echo "  Run:  ${PREFIX}/bin/sonora"
echo "  Or:   sonora"
echo
