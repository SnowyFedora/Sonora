import QtQuick
import Sonora

Item {
    id: root
    property real value: 0
    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 28

    readonly property real gap: 4
    readonly property real handleW: drag.pressed ? 3 : 4
    readonly property real trackH: Math.min(12, Math.max(4, height * 0.4))
    readonly property real handleH: Math.min(height, Math.max(trackH + 8, height * 0.85))
    property real visual: drag.pressed ? dragPos : Math.max(0, Math.min(1, root.value))
    property real dragPos: 0
    readonly property real handleX: Math.round(visual * Math.max(0, width - handleW))

    clip: true

    Rectangle {
        x: 0
        width: Math.max(0, root.handleX - root.gap)
        height: root.trackH
        radius: root.trackH / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.primary
        visible: width > 0
    }
    Rectangle {
        x: root.handleX + root.handleW + root.gap
        width: Math.max(0, root.width - x)
        height: root.trackH
        radius: root.trackH / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.secondaryContainer
        visible: width > 0
    }
    Rectangle {
        x: root.handleX
        width: root.handleW
        height: root.handleH
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.primary
        Behavior on width { NumberAnimation { duration: 100 } }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function setFromX(mx) {
            const v = Math.max(0, Math.min(1, mx / Math.max(1, root.width)))
            root.dragPos = v
            root.moved(v)
        }
        onPressed: (m) => setFromX(m.x)
        onPositionChanged: (m) => { if (pressed) setFromX(m.x) }
    }
}
