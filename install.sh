#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${ROOT}/build"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"

red()  { printf '\033[1;31m%s\033[0m\n' "$*"; }
grn()  { printf '\033[1;32m%s\033[0m\n' "$*"; }
ylw()  { printf '\033[1;33m%s\033[0m\n' "$*"; }
info() { printf '→ %s\n' "$*"; }

# --- куда ставить ---
# По умолчанию: ~/.local (пользователь)
# Система:      ./install.sh --system   или  PREFIX=/usr/local sudo ./install.sh
SYSTEM=0
for arg in "$@"; do
  case "$arg" in
    --system|-s) SYSTEM=1 ;;
    --user|-u)   SYSTEM=0 ;;
    --help|-h)
      echo "Использование: ./install.sh [--user|--system]"
      echo "  --user    в ~/.local (по умолчанию)"
      echo "  --system  в /usr/local (нужен root/sudo)"
      echo "  PREFIX=/opt/sonora ./install.sh  — свой путь"
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

# Для системной установки нужен root
if [[ "$PREFIX" == /usr* || "$PREFIX" == /opt* ]]; then
  if [[ "$(id -u)" -ne 0 ]]; then
    ylw "Системная установка в ${PREFIX} — нужен root. Перезапуск через sudo…"
    exec sudo env "PREFIX=$PREFIX" "JOBS=$JOBS" bash "$0" --system
  fi
fi

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    red "Не найден: $1"
    return 1
  fi
}

info "Проверка зависимостей…"
MISSING=0
for bin in cmake ninja g++ pkg-config; do
  if ! need "$bin"; then MISSING=1; fi
done

if ! pkg-config --exists Qt6Core Qt6Gui Qt6Widgets Qt6Qml Qt6Quick Qt6QuickControls2 Qt6Multimedia 2>/dev/null; then
  if ! command -v qmake6 >/dev/null 2>&1 && ! command -v qtpaths6 >/dev/null 2>&1; then
    red "Не найдены Qt6 dev-пакеты"
    ylw "Arch:   sudo pacman -S qt6-base qt6-declarative qt6-multimedia cmake ninja gcc"
    ylw "Fedora: sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtmultimedia-devel cmake ninja-build gcc-c++"
    ylw "Ubuntu: sudo apt install qt6-base-dev qt6-declarative-dev qt6-multimedia-dev cmake ninja-build g++"
    MISSING=1
  fi
fi

if [[ "$MISSING" -ne 0 ]]; then
  red "Установи зависимости и запусти снова: ./install.sh"
  exit 1
fi
grn "Зависимости OK"

info "Сборка (Ninja, ${JOBS} потоков)…"
cmake -S "$ROOT" -B "$BUILD_DIR" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX"
cmake --build "$BUILD_DIR" -j"$JOBS"

info "Установка в ${PREFIX}…"
cmake --install "$BUILD_DIR"

BIN_SRC="${PREFIX}/bin/Sonora"
BIN_DST="${PREFIX}/bin/sonora"
if [[ -x "$BIN_SRC" ]]; then
  ln -sfn "Sonora" "$BIN_DST"
fi

# Desktop
APP_DIR="${PREFIX}/share/applications"
mkdir -p "$APP_DIR"
cat > "${APP_DIR}/sonora.desktop" << DESKTOP
[Desktop Entry]
Type=Application
Name=Sonora
GenericName=Music Player
Comment=Лёгкий плеер и библиотека звуков
Exec=${PREFIX}/bin/sonora %F
TryExec=${PREFIX}/bin/sonora
Icon=audio-headphones
Terminal=false
Categories=AudioVideo;Audio;Player;
Keywords=music;soundboard;playlist;audio;плеер;музыка;
StartupNotify=true
MimeType=audio/mpeg;audio/mp3;audio/x-mp3;audio/flac;audio/x-flac;audio/ogg;audio/x-vorbis+ogg;audio/opus;audio/aac;audio/mp4;audio/x-m4a;audio/wav;audio/x-wav;audio/x-aiff;audio/aiff;audio/x-ms-wma;audio/webm;inode/directory;
DESKTOP

# Для user-install — PATH; для system /usr/local/bin обычно уже в PATH
if [[ "$PREFIX" == "$HOME/.local" ]]; then
  if [[ ":$PATH:" != *":${PREFIX}/bin:"* ]]; then
    ylw "Добавь в ~/.bashrc (или ~/.zshrc):"
    echo "  export PATH=\"${PREFIX}/bin:\$PATH\""
    echo
    export PATH="${PREFIX}/bin:$PATH"
  fi
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "${PREFIX}/share/applications" 2>/dev/null || true
fi
# системная база desktop (если ставим в /usr/local)
if [[ -d /usr/share/applications ]] && [[ "$PREFIX" == /usr* ]]; then
  update-desktop-database /usr/share/applications 2>/dev/null || true
  update-desktop-database "${PREFIX}/share/applications" 2>/dev/null || true
fi

info "Проверка установки…"
if [[ -x "$BIN_DST" ]]; then
  grn "Бинарник установлен и исполняемый: ${BIN_DST}"
else
  red "Бинарник не найден или не исполняемый: ${BIN_DST}"
  exit 1
fi

# Не запускаем GUI в offscreen-режиме для smoke-теста: Qt Multimedia может
# печатать необязательные предупреждения (например, VDPAU/NVIDIA) и завершаться
# иначе, чем в реальной пользовательской сессии. Это приводило к ложному
# сообщению об ошибке, хотя установленное приложение нормально работает.

grn "Готово!"
echo
echo "  Установка: ${PREFIX}"
echo "  Запуск:    ${PREFIX}/bin/sonora"
echo "  Или:       sonora"
if [[ "$PREFIX" == /usr* || "$PREFIX" == /opt* ]]; then
  echo "  Удалить:   sudo rm -f ${PREFIX}/bin/Sonora ${PREFIX}/bin/sonora ${APP_DIR}/sonora.desktop"
  echo "             sudo rm -rf ${PREFIX}/share/sonora"
else
  echo "  Удалить:   rm -f ${PREFIX}/bin/Sonora ${PREFIX}/bin/sonora ${APP_DIR}/sonora.desktop"
  echo "             rm -rf ${PREFIX}/share/sonora"
fi
echo
echo "  Пользовательская: ./install.sh"
echo "  В систему:        ./install.sh --system"
echo
