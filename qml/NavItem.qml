import QtQuick
import Sonora

// Пункт навигации M3: индикатор-пилюля растёт из 32 до 56 dp при выборе.
Item {
    id: root
    property string icon
    property string label
    property bool selected: false
    signal clicked()

    width: 80
    height: 68

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        y: 4
        height: 32
        width: root.selected ? 56 : 32
        radius: height / 2
        color: root.selected ? Theme.secondaryContainer : "transparent"
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.textPrimary
            opacity: press.pressed ? Theme.pressOpacity : (hover.hovered ? Theme.hoverOpacity : 0)
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }

        MdIcon {
            anchors.centerIn: parent
            path: root.icon
            size: 24
            color: root.selected ? Theme.textPrimary : Theme.textSecondary
            scale: press.pressed ? 0.88 : 1
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        }
    }

    MdText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: pill.bottom
        anchors.topMargin: 4
        text: root.label
        type: "labelMedium"
        color: root.selected ? Theme.textPrimary : Theme.textSecondary
        font.weight: root.selected ? Font.Bold : Font.DemiBold
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    MouseArea { id: press; anchors.fill: parent; onClicked: root.clicked() }
}
