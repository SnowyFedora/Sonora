import QtQuick
import Sonora

// M3 слайдер: трек + хэндл, не вылезает за bounds родителя
Item {
    id: root
    property real value: 0      // 0..1
    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 28

    readonly property real gap: 4
    readonly property real handleW: drag.pressed ? 3 : 4
    readonly property real trackH: Math.min(12, Math.max(4, height * 0.4))
    // хэндл не выше самого слайдера
    readonly property real handleH: Math.min(height, Math.max(trackH + 8, height * 0.85))
    readonly property real handleX: Math.round(value * Math.max(0, width - handleW))

    clip: true

    Rectangle { // активный трек
        x: 0
        width: Math.max(0, root.handleX - root.gap)
        height: root.trackH
        radius: root.trackH / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.primary
        visible: width > 0
    }
    Rectangle { // неактивный трек
        x: root.handleX + root.handleW + root.gap
        width: Math.max(0, root.width - x)
        height: root.trackH
        radius: root.trackH / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.secondaryContainer
        visible: width > 0
    }
    Rectangle { // хэндл
        x: root.handleX
        width: root.handleW
        height: root.handleH
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.primary
        Behavior on width { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function update(mx) {
            const w = Math.max(1, root.width - root.handleW)
            root.moved(Math.max(0, Math.min(1, mx / root.width)))
        }
        onPressed: (m) => update(m.x)
        onPositionChanged: (m) => { if (pressed) update(m.x) }
    }
}
