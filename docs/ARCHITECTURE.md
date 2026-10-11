# Sonora — архитектура

Лёгкий open-source саундпад на **Qt 6 (C++ + QML)** с интерфейсом Material You (Material Design 3).

## 1. Слои

```
┌───────────────────────────── QML (UI) ─────────────────────────────┐
│ Main.qml · NavRail · LibraryPage · SettingsPage · SoundCard · Md*  │
│ Theme.qml (singleton: цвета, формы, типографика, движение)         │
└───────────────▲──────────────────────────────────────▲─────────────┘
                │ property bindings / Q_INVOKABLE      │ модели
┌───────────────┴──────────────── C++ ─────────────────┴─────────────┐
│ AppController  (фасад для QML: синглтон `App`)                     │
│   ├─ ThemeEngine     Dynamic Color: seed → тональные палитры → роли│
│   ├─ SoundLibrary    QAbstractListModel + JSON-хранилище           │
│   │    └─ SoundFilterModel  (поиск / папка / избранное / недавние) │
│   ├─ AudioEngine     пул голосов, режимы, громкость, устройство    │
│   └─ HotkeyManager   парсинг сочетаний + IHotkeyBackend            │
│        ├─ WinHotkeyBackend   RegisterHotKey (Win32)                │
│        └─ NullHotkeyBackend  заглушка (Linux/macOS, TODO)          │
└────────────────────────────────────────────────────────────────────┘
```

Принципы:

- **UI не знает про платформу.** Всё платформенное спрятано за интерфейсами (`IHotkeyBackend`, позже `IPlaybackBackend`).
- **Один фасад `App`** — единственная точка входа из QML. Дочерние объекты отдаются как `QObject*`.
- **Данные локально**: `AppDataLocation/profiles/<имя>/library.json`, настройки — `QSettings`.
- **Ноль лишней работы в простое.** Таймеры прогресса живут только у играющих карточек; пул `QMediaPlayer` создаётся лениво.

## 2. Структура репозитория

```
sonora/
├─ CMakeLists.txt
├─ docs/ARCHITECTURE.md
├─ src/
│  ├─ main.cpp
│  ├─ app/AppController.{h,cpp}
│  ├─ theme/ThemeEngine.{h,cpp}
│  ├─ library/Sound.h · SoundLibrary.{h,cpp} · SoundFilterModel.{h,cpp}
│  ├─ audio/AudioEngine.{h,cpp}
│  └─ hotkeys/IHotkeyBackend.h · HotkeyManager.{h,cpp} · HotkeyBackendWin.cpp
└─ qml/
   ├─ Main.qml · Theme.qml · Icons.qml
   ├─ Md*.qml            (компоненты: Text, Icon, IconButton, Button, Chip, SearchBar, Slider, Segmented, Switch)
   ├─ NavRail.qml · NavItem.qml · MasterBar.qml · SoundCard.qml
   └─ LibraryPage.qml · SettingsPage.qml
```

## 3. Аудио

- **Сейчас:** `QMediaPlayer` + `QAudioOutput` на каждый голос (пул до 16). Декодирование mp3/wav/ogg/flac берёт на себя бэкенд Qt Multimedia (WMF на Windows, FFmpeg в Qt ≥ 6.5).
- **Режимы:** `StopPrevious` (повторный клик по играющему — стоп), `Overlay` (наложение), `Queue` (очередь).
- **Громкость:** итог = `master² × gain(звука)`, квадрат даёт перцептивную кривую слайдера.
- **Вывод:** выбор устройства из `QMediaDevices`. Для «в микрофон» — вывод на виртуальный кабель (VB-Cable/VoiceMeeter/PipeWire loopback).
- **Следующий шаг (низкая задержка):** `IPlaybackBackend` + miniaudio (WASAPI/CoreAudio/ALSA/Pulse в одном single-header, public domain): декодирование в PCM-кэш, микширование в одном потоке, **двойной вывод** (мониторинг + виртуальный микрофон) без двойного декодирования.

## 4. Глобальные горячие клавиши

| Платформа | Реализация |
|---|---|
| Windows | `RegisterHotKey` + `QAbstractNativeEventFilter` (`WM_HOTKEY`). Работает в играх с borderless/fullscreen, не ставит хуки → не триггерит античиты. |
| Linux X11 | `XGrabKey` через xcb (TODO) |
| Linux Wayland | `xdg-desktop-portal` GlobalShortcuts по D-Bus (TODO) |
| macOS | Carbon `RegisterEventHotKey` (TODO) |

`HotkeyManager` парсит `QKeySequence`, ведёт таблицу `id ↔ int`, детектит конфликты и сообщает об отказе ОС. Зарезервирован `app:stopAll` (по умолчанию `Ctrl+Alt+S`).

## 5. Material You в Sonora

### 5.1 Dynamic Color
`ThemeEngine` строит схему из **seed-цвета**:

1. seed → OKLCH (hue, chroma).
2. Пять тональных палитр: primary (hue, C≈0.13), secondary (C≈0.045), tertiary (hue+60°, C≈0.07), neutral (C≈0.012), neutral-variant (C≈0.024), плюс error.
3. Тон `T` (0–100, как CIE L\*) → OKLab `L = ∛Y`; цвет приводится в sRGB с gamut-mapping (уменьшение chroma бисекцией).
4. Роли M3 берутся по таблице тонов (light: primary 40, container 90; dark: primary 80, container 30; surface-container-* 4…94).

Источники seed: пресеты, **акцентный цвет ОС** (`QPalette::Accent`), **доминирующий цвет изображения**. Смена схемы анимируется в C++ (380 мс, интерполяция по ролям), поэтому весь интерфейс плавно «перекрашивается».

> Позже можно заменить OKLCH-приближение на настоящий HCT из `material-color-utilities` (C++) — публичный API `ThemeEngine` не изменится.

### 5.2 Компоненты
Своя библиотека `Md*` поверх базового Qt Quick (стиль Controls — `Basic`, чтобы не бороться с чужой стилизацией):

- State layers (hover 8 %, press 10 %) вместо ripple, **shape morph при нажатии** (пилюля → 12 dp) в духе M3 Expressive.
- Кнопки: filled / tonal / outlined / text. Chips (filter), Segmented с «скользящим» индикатором, Switch с растущим handle, Slider с выразительным толстым треком и узким хэндлом.
- Карточка звука: радиус 28 → 20 и цвет `surfaceContainerHigh → primaryContainer` при воспроизведении, эквалайзер-анимация, линия прогресса.
- Иконки — SVG-пути Material Symbols в `Icons.qml` (отрисовка через `QtQuick.Shapes`, без шрифтовых зависимостей).
- Elevation выражается **тоном поверхности**, а не тенями (как в M3).

### 5.3 Движение
Токены в `Theme.qml`: `emphasized` `[0.2,0,0,1]`, `emphasizedDecelerate`, `emphasizedAccelerate`; длительности 100/200/300/500 мс.

- **Fade through** — переключение разделов (старая страница гаснет 90 мс, новая появляется с scale 0.92→1).
- **Shared axis** — вход вложенных экранов (редактор/папка): сдвиг по X на 30 dp + fade.
- **Container transform** — карточка звука → редактор (запланировано: общий прямоугольник растёт до размера панели).
- **Staggered entrance** карточек (задержка `min(index,12) × 24 мс`).

### 5.4 Типографика
`MdText` с типами M3 (`displaySmall … labelSmall`); семейство `Roboto Flex → Segoe UI Variable → системное`.

## 6. Главные экраны

### Библиотека (desktop ≥ 840 dp)
```
┌────┬──────────────────────────────────────────────────────────┐
│ ＋ │  Библиотека                       ( Стоп │ Наложение │ Очередь )
│    │  214 звуков                                              │
│ 📁 │  ╭───────────────────────────────────────────────╮       │
│ ★  │  │ 🔍  Поиск по звукам, папкам и тегам          ✕ │       │
│ 🕘 │  ╰───────────────────────────────────────────────╯       │
│    │  (Все) (Мемы) (Игры) (Мемы / Видео) …  ← filter chips    │
│    │  ╭────────╮ ╭────────╮ ╭────────╮ ╭────────╮             │
│    │  │▶  Ctrl1│ │▶       │ │ ▮▮▮    │ │▶       │ ← сетка      │
│    │  │Vine boom│ │Airhorn │ │Bruh   ★│ │Sad…    │   карточек  │
│ ⚙  │  ╰────────╯ ╰────────╯ ╰────────╯ ╰────────╯             │
│    │      ╭─────────────────────────────────────╮             │
│    │      │ 🔊 ━━━━━━●━━━━━━ 72%    ■ Стоп всё  │  ← MasterBar│
└────┴──────────────────────────────────────────────────────────┘
```

### Настройки
Карточки-секции: **Оформление** (тема, палитра-свотчи, «акцент системы», «из картинки»), **Звук** (режим, громкость, устройство вывода), **Система** (поверх окон, бэкенд хоткеев).

### Редактор звука (запланирован)
Container transform из карточки → полноэкранная панель: волна (`Canvas`/`QQuickPaintedItem` по пиковому кэшу), маркеры обрезки, fade in/out, громкость, теги, назначение хоткея.

### Compact (< 600 dp)
`NavRail` → нижний `NavigationBar`, сетка 2 колонки, `MasterBar` над баром.

## 7. Дорожная карта

1. ✅ Каркас, тема, сетка, хоткеи (Win), режимы воспроизведения
2. Диалог назначения хоткея, контекстное меню карточки, удаление/переименование
3. Теги и фильтры, профили (папка на профиль + переключатель)
4. Редактор: волна + обрезка + fade (оффлайн-рендер в кэш)
5. miniaudio-бэкенд, двойной вывод, запись с микрофона
6. Linux (X11/Wayland-портал) и macOS хоткеи, MIDI (`RtMidi`)
