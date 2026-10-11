import QtQuick
import Sonora

// Сегментированная кнопка с «скользящим» индикатором выбора.
Item {
    id: root
    property var model: []
    property int currentIndex: 0
    signal activated(int index)

    implicitHeight: 40
    implicitWidth: row.implicitWidth + 8

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "transparent"
        border.width: 1
        border.color: Theme.outline
    }

    Rectangle {
        readonly property Item target: { repeater.count; return repeater.itemAt(root.currentIndex) }
        x: target ? target.x + row.x : 0
        y: 4
        width: target ? target.width : 0
        height: root.height - 8
        radius: height / 2
        color: Theme.secondaryContainer
        Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
    }

    Row {
        id: row
        x: 4
        height: parent.height
        Repeater {
            id: repeater
            model: root.model
            delegate: Item {
                required property int index
                required property string modelData
                height: row.height
                width: label.implicitWidth + 32

                MdText {
                    id: label
                    anchors.centerIn: parent
                    text: modelData
                    type: "labelLarge"
                    color: Theme.textPrimary
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    anchors.fill: parent
                    onClicked: { root.currentIndex = index; root.activated(index) }
                }
            }
        }
    }
}
