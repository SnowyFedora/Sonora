pragma Singleton
import QtQuick
import Sonora.Core

// Токены Material 3: цвета (Dynamic Color из C++), формы, движение, типографика.
QtObject {
    id: root

    readonly property var s: App.theme.scheme
    readonly property bool dark: App.theme.dark

    // Яркость фона → надёжно определяем, нужен ли белый текст
    readonly property bool isDarkBg: {
        const c = s.background
        if (c === undefined || c === null)
            return true
        // c.r/g/b в QML — 0..1
        return (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) < 0.45
    }

    readonly property color textPrimary:   isDarkBg ? "#FFFFFF" : "#000000"
    readonly property color textSecondary: isDarkBg ? "#F0F0F0" : "#333333"
    readonly property color textOnAccent:  isDarkBg ? "#FFFFFF" : "#1A1A1A"
    readonly property color textOnFilled:  isDarkBg ? "#1A1A1A" : "#FFFFFF"

    // ── Цвета ────────────────────────────────────────────────────────────
    readonly property color primary: s.primary
    readonly property color onPrimary: textOnFilled
    readonly property color primaryContainer: s.primaryContainer
    readonly property color onPrimaryContainer: textOnAccent
    readonly property color secondary: s.secondary
    readonly property color onSecondary: textOnFilled
    readonly property color secondaryContainer: s.secondaryContainer
    readonly property color onSecondaryContainer: textOnAccent
    readonly property color tertiary: s.tertiary
    readonly property color onTertiary: textOnFilled
    readonly property color tertiaryContainer: s.tertiaryContainer
    readonly property color onTertiaryContainer: textOnAccent
    readonly property color error: s.error
    readonly property color onError: textOnFilled
    readonly property color errorContainer: s.errorContainer
    readonly property color onErrorContainer: textOnAccent
    readonly property color background: s.background
    readonly property color onBackground: textPrimary
    readonly property color surface: s.surface
    readonly property color onSurface: textPrimary
    readonly property color surfaceVariant: s.surfaceVariant
    readonly property color onSurfaceVariant: textSecondary
    readonly property color outline: s.outline
    readonly property color outlineVariant: s.outlineVariant
    readonly property color surfaceContainerLowest: s.surfaceContainerLowest
    readonly property color surfaceContainerLow: s.surfaceContainerLow
    readonly property color surfaceContainer: s.surfaceContainer
    readonly property color surfaceContainerHigh: s.surfaceContainerHigh
    readonly property color surfaceContainerHighest: s.surfaceContainerHighest
    readonly property color inverseSurface: s.inverseSurface
    readonly property color inverseOnSurface: s.inverseOnSurface
    readonly property color inversePrimary: s.inversePrimary

    // ── Формы (dp) ───────────────────────────────────────────────────────
    readonly property int radiusXs: 4
    readonly property int radiusSm: 8
    readonly property int radiusMd: 12
    readonly property int radiusLg: 16
    readonly property int radiusXl: 28
    readonly property int radiusFull: 1000

    // ── Движение ─────────────────────────────────────────────────────────
    readonly property var emphasized: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var emphasizedDecelerate: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    readonly property var emphasizedAccelerate: [0.3, 0.0, 0.8, 0.15, 1.0, 1.0]
    readonly property var standard: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]

    readonly property int durShort: 150
    readonly property int durMedium: 300
    readonly property int durLong: 500

    // ── Типографика ──────────────────────────────────────────────────────
    readonly property var fontPreference: [
        "Inter", "Noto Sans", "Roboto", "Cantarell", "Ubuntu",
        "Segoe UI Variable Text", "Segoe UI", "SF Pro Text", "Helvetica Neue",
        "DejaVu Sans", "FreeSans"
    ]
    readonly property string fontFamily: {
        const available = Qt.fontFamilies()
        for (const f of fontPreference)
            if (available.indexOf(f) >= 0)
                return f
        return Qt.application.font.family
    }

    readonly property real hoverOpacity: 0.08
    readonly property real pressOpacity: 0.10
}
