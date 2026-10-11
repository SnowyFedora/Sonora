import QtQuick
import Sonora

// Filter chip M3: при выборе — secondaryContainer + галочка.
Item {
    id: root
    property string text
    property bool selected: false
    signal clicked()

    implicitHeight: 32
    implicitWidth: content.implicitWidth + 24

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.radiusSm
        color: root.selected ? Theme.secondaryContainer : "transparent"
        border.width: root.selected ? 0 : 1
        border.color: Theme.outlineVariant
        scale: press.pressed ? 0.96 : 1
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.textPrimary
            opacity: press.pressed ? Theme.pressOpacity : (hover.hovered ? Theme.hoverOpacity : 0)
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }

        Row {
            id: content
            anchors.centerIn: parent
            spacing: root.selected ? 6 : 0
            Behavior on spacing { NumberAnimation { duration: 200 } }

            Item {
                width: root.selected ? 18 : 0
                height: 18
                clip: true
                anchors.verticalCenter: parent.verticalCenter
                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                MdIcon {
                    path: Icons.check
                    size: 18
                    color: Theme.textOnAccent
                }
            }
            MdText {
                text: root.text
                type: "labelLarge"
                color: root.selected ? Theme.textOnAccent : Theme.textSecondary
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    MouseArea { id: press; anchors.fill: parent; onClicked: root.clicked() }
}
