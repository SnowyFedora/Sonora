import QtQuick
import Sonora

// M3 Switch: 52×32, handle растёт при включении.
Item {
    id: root
    property bool checked: false
    signal toggled(bool checked)

    width: 52
    height: 32

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.primary : Theme.surfaceContainerHighest
        border.width: root.checked ? 0 : 2
        border.color: Theme.outline
        Behavior on color { ColorAnimation { duration: 200 } }

        Rectangle {
            id: handle
            readonly property real d: press.pressed ? 28 : (root.checked ? 24 : 16)
            width: d
            height: d
            radius: d / 2
            anchors.verticalCenter: parent.verticalCenter
            // центр хэндла: 16 слева (выкл) или width-16 справа (вкл)
            x: (root.checked ? parent.width - 16 : 16) - d / 2
            color: root.checked ? Theme.onPrimary : Theme.outline
            Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

            MdIcon {
                anchors.centerIn: parent
                path: Icons.check
                size: 16
                color: Theme.primary
                opacity: root.checked ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
    MouseArea {
        id: press
        anchors.fill: parent
        onClicked: { root.checked = !root.checked; root.toggled(root.checked) }
    }
}
