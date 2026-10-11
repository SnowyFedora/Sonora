import QtQuick
import Sonora
import Sonora.Core

// Карточка звука. При воспроизведении «морфится»: радиус 28→20, цвет → primaryContainer,
// иконка превращается в эквалайзер, снизу бежит прогресс.
Item {
    id: root
    property string soundId
    property string title
    property string folder
    property bool favorite: false
    property string hotkey
    property int appearDelay: 0

    readonly property bool playing: App.engine.playingIds.indexOf(soundId) >= 0
    property real progress: 0

    signal triggered()
    signal favoriteToggled()

    // Появление: fade + подъём со смещением по индексу
    opacity: 0
    Component.onCompleted: appear.start()
    SequentialAnimation {
        id: appear
        PauseAnimation { duration: root.appearDelay }
        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 1; duration: 280 }
            NumberAnimation { target: surface; property: "y"; from: 14; to: 0; duration: 380
                easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasizedDecelerate }
        }
    }

    Timer {
        running: root.playing
        interval: 50
        repeat: true
        triggeredOnStart: true
        onTriggered: root.progress = App.engine.progressOf(root.soundId)
        onRunningChanged: if (!running) root.progress = 0
    }

    Rectangle {
        id: surface
        width: parent.width
        height: parent.height
        radius: 28
        color: Theme.surfaceContainerHigh
        scale: press.pressed ? 0.96 : 1
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }

        states: State {
            name: "playing"
            when: root.playing
            PropertyChanges { target: surface; radius: 20; color: Theme.primaryContainer }
            PropertyChanges { target: badge; color: Theme.primary; radius: 12 }
        }
        transitions: Transition {
            NumberAnimation { properties: "radius"; duration: 380; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
            ColorAnimation { duration: 280 }
        }

        Rectangle { // state layer
            anchors.fill: parent
            radius: parent.radius
            color: root.playing ? Theme.textOnAccent : Theme.textPrimary
            opacity: press.pressed ? Theme.pressOpacity : (hover.hovered ? Theme.hoverOpacity : 0)
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }

        // Значок: play → эквалайзер
        Rectangle {
            id: badge
            x: 16; y: 16
            width: 44; height: 44
            radius: 22
            color: Theme.secondaryContainer

            MdIcon {
                anchors.centerIn: parent
                path: Icons.play
                color: Theme.onSecondaryContainer
                opacity: root.playing ? 0 : 1
                scale: root.playing ? 0.5 : 1
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
            }

            Row {
                anchors.centerIn: parent
                spacing: 3
                opacity: root.playing ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Repeater {
                    model: 3
                    delegate: Rectangle {
                        required property int index
                        width: 4
                        radius: 2
                        color: Theme.onPrimary
                        anchors.bottom: parent.bottom
                        height: 6
                        SequentialAnimation on height {
                            running: root.playing
                            loops: Animation.Infinite
                            PauseAnimation { duration: index * 110 }
                            NumberAnimation { to: 20; duration: 320 + index * 60; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 6; duration: 320 + index * 60; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }
        }

        // Бейдж горячей клавиши
        Rectangle {
            visible: root.hotkey !== ""
            anchors { left: badge.right; leftMargin: 8; verticalCenter: badge.verticalCenter }
            height: 24
            width: hkText.implicitWidth + 16
            radius: 8
            color: root.playing ? Theme.primary : Theme.surfaceContainerHighest
            Behavior on color { ColorAnimation { duration: 250 } }
            MdText {
                id: hkText
                anchors.centerIn: parent
                text: root.hotkey
                type: "labelSmall"
                color: root.playing ? Theme.textOnFilled : Theme.textSecondary
            }
        }

        // Название и папка
        Column {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 16; rightMargin: 16; bottomMargin: 18 }
            spacing: 2
            MdText {
                width: parent.width
                text: root.title
                type: "titleMedium"
                maximumLineCount: 2
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                color: root.playing ? Theme.textOnAccent : Theme.textPrimary
            }
            MdText {
                width: parent.width
                text: root.folder
                type: "bodySmall"
                elide: Text.ElideRight
                color: root.playing ? Theme.textOnAccent : Theme.textSecondary
                opacity: 0.85
            }
        }

        // Прогресс
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 16; rightMargin: 16; bottomMargin: 8 }
            height: 4
            radius: 2
            color: Qt.alpha(Theme.textOnAccent, 0.15)
            opacity: root.playing ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Rectangle {
                width: parent.width * root.progress
                height: parent.height
                radius: 2
                color: Theme.primary
            }
        }

        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        MouseArea {
            id: press
            anchors.fill: parent
            onClicked: root.triggered()
        }

        // Избранное + в плейлист
        Row {
            anchors { top: parent.top; right: parent.right; topMargin: 10; rightMargin: 6 }
            spacing: 0
            MdIconButton {
                size: 36
                iconSize: 18
                icon: Icons.playlist
                iconColor: root.playing ? Theme.textOnAccent : Theme.textSecondary
                onClicked: {
                    const pls = App.library.playlists
                    if (!pls || pls.length === 0) {
                        const id = App.library.createPlaylist(qsTr("Мой плейлист"))
                        App.library.addToPlaylist(id, root.soundId)
                    } else {
                        App.library.addToPlaylist(pls[0].id, root.soundId)
                    }
                }
            }
            MdIconButton {
                size: 36
                iconSize: 20
                icon: Icons.star
                toggle: false
                checked: root.favorite
                iconColor: root.playing ? Theme.textOnAccent : Theme.textSecondary
                checkedContainer: Theme.tertiaryContainer
                checkedIconColor: Theme.onTertiaryContainer
                onClicked: root.favoriteToggled()
            }
        }
    }
}
