import QtQuick
import Sonora

// Текст с типографической шкалой Material 3.
Text {
    id: root
    property string type: "bodyMedium"

    readonly property var typeScale: ({
        displaySmall:   { size: 36, weight: Font.Normal, spacing: 0 },
        headlineMedium: { size: 28, weight: Font.Medium, spacing: 0 },
        headlineSmall:  { size: 24, weight: Font.Medium, spacing: 0 },
        titleLarge:     { size: 22, weight: Font.Medium, spacing: 0 },
        titleMedium:    { size: 16, weight: Font.DemiBold, spacing: 0.15 },
        titleSmall:     { size: 14, weight: Font.DemiBold, spacing: 0.1 },
        bodyLarge:      { size: 16, weight: Font.Normal, spacing: 0.5 },
        bodyMedium:     { size: 14, weight: Font.Normal, spacing: 0.25 },
        bodySmall:      { size: 12, weight: Font.Normal, spacing: 0.4 },
        labelLarge:     { size: 14, weight: Font.DemiBold, spacing: 0.1 },
        labelMedium:    { size: 12, weight: Font.DemiBold, spacing: 0.5 },
        labelSmall:     { size: 11, weight: Font.DemiBold, spacing: 0.5 }
    })
    readonly property var spec: typeScale[type] ?? typeScale.bodyMedium

    // Белый на тёмном фоне, чёрный на светлом
    color: Theme.textPrimary
    font.family: Theme.fontFamily
    font.pixelSize: spec.size
    font.weight: spec.weight
    font.letterSpacing: spec.spacing
    renderType: Text.NativeRendering
    font.hintingPreference: Font.PreferFullHinting
}
