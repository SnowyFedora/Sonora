import QtQuick
import Sonora

Item {
    id: root
    property string text
    property string icon
    property string variant: "filled"
    signal clicked()
    implicitHeight: 40
    implicitWidth: row.implicitWidth + 48
    opacity: enabled ? 1 : 0.38
    readonly property color container: variant === "filled" ? Theme.primary : variant === "tonal" ? Theme.secondaryContainer : "transparent"
    readonly property color content: variant === "filled" ? Theme.textOnFilled : variant === "tonal" ? Theme.textOnAccent : Theme.textPrimary
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: press.pressed ? Theme.radiusMd : height / 2
        color: root.container
        border.width: root.variant === "outlined" ? 1 : 0
        border.color: Theme.outline
        scale: press.pressed ? 0.97 : 1
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8
            MdIcon { visible: root.icon !== ""; path: root.icon; size: 18; color: root.content; anchors.verticalCenter: parent.verticalCenter }
            MdText { text: root.text; type: "labelLarge"; color: root.content; anchors.verticalCenter: parent.verticalCenter }
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    MouseArea { id: press; anchors.fill: parent; onClicked: root.clicked() }
}
