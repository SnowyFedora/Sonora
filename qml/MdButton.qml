import QtQuick
import Sonora

// Кнопка M3: filled / tonal / outlined / text.
Item {
    id: root
    property string text
    property string icon
    property string variant: "filled" // filled | tonal | outlined | text
    signal clicked()

    implicitHeight: 40
    implicitWidth: row.implicitWidth + 48
    opacity: enabled ? 1 : 0.38

    readonly property color container: variant === "filled" ? Theme.primary
                                     : variant === "tonal" ? Theme.secondaryContainer : "transparent"
    readonly property color content: {
        if (variant === "filled")
            return Theme.textOnFilled
        if (variant === "tonal")
            return Theme.textOnAccent
        return Theme.textPrimary
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: press.pressed ? Theme.radiusMd : height / 2
        color: root.container
        border.width: root.variant === "outlined" ? 1 : 0
        border.color: Theme.outline
        scale: press.pressed ? 0.97 : 1

        Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.content
            opacity: press.pressed ? Theme.pressOpacity : (hover.hovered ? Theme.hoverOpacity : 0)
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8
            MdIcon {
                visible: root.icon !== ""
                path: root.icon
                size: 18
                color: root.content
                anchors.verticalCenter: parent.verticalCenter
            }
            MdText {
                text: root.text
                type: "labelLarge"
                color: root.content
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    MouseArea { id: press; anchors.fill: parent; onClicked: root.clicked() }
}
