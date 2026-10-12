# Sonora 0.2.1

Лёгкий музыкальный плеер и библиотека звуков на **Qt 6 / QML** (Material You).

## Возможности

- **Библиотека** — импорт папок и файлов (mp3, flac, m4a, opus, wav…)
- **Плеер** — нижняя панель + **полноэкранный режим** (prev / pause / next, прогресс, seek)
- **Автопереход** на следующий трек (watchdog + EndOfMedia)
- **Плейлисты** — создать, переименовать, удалить, добавить/убрать треки
- **Избранное** и **Недавние**
- Удаление треков из библиотеки
- Пауза / resume, перемотка
- Dynamic Color, нативные диалоги (Dolphin), drag & drop
- `./install.sh` и `./install.sh --system`

## Установка

```bash
./install.sh          # ~/.local
./install.sh --system # /usr/local (sudo)
```

При старте в терминале должно быть: `Sonora 0.2.1 starting`
В заголовке окна: **Sonora 0.2.1**

### Зависимости

```bash
# Arch
sudo pacman -S qt6-base qt6-declarative qt6-multimedia cmake ninja gcc

# Ubuntu
sudo apt install qt6-base-dev qt6-declarative-dev qt6-multimedia-dev cmake ninja-build g++
```

## Запуск

```bash
~/.local/bin/sonora
```

## Структура

```
qml/          — UI
src/library/  — библиотека, плейлисты
src/audio/    — AudioEngine
src/app/      — AppController
```

## Лицензия

Открытый проект.
