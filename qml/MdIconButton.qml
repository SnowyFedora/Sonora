import QtQuick
import Sonora

// Круглая иконка-кнопка. В режиме toggle при checked заливается тональным цветом.
Item {
    id: root
    property string icon
    property real size: 40
    property real iconSize: 24
    property bool toggle: false
    property bool checked: false
    property color iconColor: Theme.textSecondary
    property color checkedContainer: Theme.secondaryContainer
    property color checkedIconColor: Theme.onSecondaryContainer
    property bool filled: false   // tonal-заливка без toggle
    signal clicked()

    width: size
    height: size
    opacity: enabled ? 1 : 0.38

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: press.pressed ? Theme.radiusMd : width / 2
        color: root.checked ? root.checkedContainer
             : root.filled ? Theme.secondaryContainer : "transparent"
        scale: press.pressed ? 0.92 : 1

        Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

        Rectangle { // state layer
            anchors.fill: parent
            radius: parent.radius
            color: root.checked ? root.checkedIconColor : Theme.textPrimary
            opacity: press.pressed ? Theme.pressOpacity : (hover.hovered ? Theme.hoverOpacity : 0)
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }

        MdIcon {
            anchors.centerIn: parent
            path: root.icon
            size: root.iconSize
            color: root.checked ? root.checkedIconColor
                 : root.filled ? Theme.onSecondaryContainer : root.iconColor
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    MouseArea {
        id: press
        anchors.fill: parent
        onClicked: {
            if (root.toggle) root.checked = !root.checked
            root.clicked()
        }
    }
}
