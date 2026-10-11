import QtQuick
import Sonora

Item {
    id: root
    property real value: 0
    signal moved(real value)
    implicitWidth: 200
    implicitHeight: 44
    readonly property real gap: 6
    readonly property real handleW: drag.pressed ? 2 : 4
    readonly property real handleX: Math.round(value * (width - 4))
    Rectangle { x: 0; width: Math.max(0, root.handleX - root.gap); height: 16; radius: 8; anchors.verticalCenter: parent.verticalCenter; color: Theme.primary; visible: width > 0 }
    Rectangle { x: root.handleX + 4 + root.gap; width: Math.max(0, root.width - x); height: 16; radius: 8; anchors.verticalCenter: parent.verticalCenter; color: Theme.secondaryContainer; visible: width > 0 }
    Rectangle { x: root.handleX + (4 - root.handleW) / 2; width: root.handleW; height: 44; radius: width / 2; color: Theme.primary }
    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function update(mx) { root.moved(Math.max(0, Math.min(1, mx / root.width))) }
        onPressed: (m) => update(m.x)
        onPositionChanged: (m) => { if (pressed) update(m.x) }
    }
}
