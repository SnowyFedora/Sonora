import QtQuick
import Sonora

// Navigation rail M3: FAB «папка» + «файлы», разделы, настройки.
Item {
    id: root
    property int currentIndex: 0
    signal navigated(int index)
    signal addClicked()
    signal addFilesClicked()

    width: 88

    // 0 Звуки, 1 Плейлисты, 2 Избранное, 3 Недавние, 4 Настройки
    readonly property var sections: [
        { icon: Icons.musicNote, label: qsTr("Звуки") },
        { icon: Icons.playlist,  label: qsTr("Плейлисты") },
        { icon: Icons.star,      label: qsTr("Избранное") },
        { icon: Icons.history,   label: qsTr("Недавние") }
    ]

    Column {
        id: fabs
        anchors.horizontalCenter: parent.horizontalCenter
        y: 16
        spacing: 10

        Item {
            width: 56; height: 56
            Rectangle {
                anchors.fill: parent
                radius: fabPress.pressed ? 12 : 16
                color: Theme.primaryContainer
                scale: fabPress.pressed ? 0.94 : 1
                Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Theme.textPrimary
                    opacity: fabPress.pressed ? Theme.pressOpacity : (fabHover.hovered ? Theme.hoverOpacity : 0)
                }
                MdIcon {
                    anchors.centerIn: parent
                    path: Icons.folder
                    color: Theme.textPrimary
                }
            }
            HoverHandler { id: fabHover; cursorShape: Qt.PointingHandCursor }
            MouseArea { id: fabPress; anchors.fill: parent; onClicked: root.addClicked() }
        }

        Item {
            width: 56; height: 56
            Rectangle {
                anchors.fill: parent
                radius: filesPress.pressed ? 12 : 16
                color: Theme.secondaryContainer
                scale: filesPress.pressed ? 0.94 : 1
                Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Theme.textPrimary
                    opacity: filesPress.pressed ? Theme.pressOpacity : (filesHover.hovered ? Theme.hoverOpacity : 0)
                }
                MdIcon {
                    anchors.centerIn: parent
                    path: Icons.musicNote
                    color: Theme.textPrimary
                }
            }
            HoverHandler { id: filesHover; cursorShape: Qt.PointingHandCursor }
            MouseArea { id: filesPress; anchors.fill: parent; onClicked: root.addFilesClicked() }
        }
    }

    Column {
        anchors.top: fabs.bottom
        anchors.topMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8
        Repeater {
            model: root.sections
            delegate: NavItem {
                required property int index
                required property var modelData
                icon: modelData.icon
                label: modelData.label
                selected: root.currentIndex === index
                onClicked: { root.currentIndex = index; root.navigated(index) }
            }
        }
    }

    NavItem {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        icon: Icons.settings
        label: qsTr("Настройки")
        selected: root.currentIndex === 4
        onClicked: { root.currentIndex = 4; root.navigated(4) }
    }
}
