import QtQuick
import Sonora
import Sonora.Core

Item {
    id: page
    signal closeRequested()

    readonly property bool hasTrack: App.nowPlayingId !== ""
    readonly property bool playing: App.isPlaying
    property real progress: 0

    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceContainerLow
        radius: Theme.radiusXl
    }

    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: parent.height * 0.45
        radius: Theme.radiusXl
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(Theme.primaryContainer, 0.55) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    MdIconButton {
        anchors { top: parent.top; right: parent.right; topMargin: 16; rightMargin: 16 }
        icon: Icons.collapse
        iconColor: Theme.textPrimary
        z: 2
        onClicked: page.closeRequested()
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(420, parent.width - 64)
        spacing: 28

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(280, parent.width)
            height: width
            radius: Theme.radiusLg
            color: Theme.primaryContainer
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.72; height: width; radius: width / 2
                color: Qt.alpha(Theme.primary, 0.2)
            }
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.4; height: width; radius: width / 2
                color: Qt.alpha(Theme.primary, 0.35)
            }
            MdIcon {
                anchors.centerIn: parent
                path: Icons.musicNote
                size: 72
                color: Theme.textOnAccent
            }
        }

        Column {
            width: parent.width
            spacing: 6
            MdText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: page.hasTrack ? App.nowPlayingTitle : qsTr("Ничего не играет")
                type: "headlineSmall"
                elide: Text.ElideRight
            }
            MdText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: page.hasTrack ? App.nowPlayingArtist : qsTr("Выбери трек в библиотеке")
                type: "bodyLarge"
                color: Theme.textSecondary
                elide: Text.ElideRight
            }
        }

        Item {
            width: parent.width
            height: 28
            visible: page.hasTrack
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: 6; radius: 3
                color: Theme.surfaceContainerHighest
                Rectangle {
                    height: parent.height
                    width: parent.width * Math.max(0, Math.min(1, page.progress))
                    radius: 3
                    color: Theme.primary
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20
            MdIconButton {
                size: 56; iconSize: 28
                icon: Icons.skipPrevious
                iconColor: Theme.textPrimary
                enabled: page.hasTrack
                opacity: enabled ? 1 : 0.35
                onClicked: App.playPrevious()
            }
            Rectangle {
                width: 72; height: 72; radius: 36
                color: Theme.primary
                scale: mainPress.pressed ? 0.92 : 1
                MdIcon {
                    anchors.centerIn: parent
                    path: page.playing ? Icons.stop : Icons.play
                    size: 32
                    color: Theme.textOnFilled
                }
                MouseArea {
                    id: mainPress
                    anchors.fill: parent
                    onClicked: {
                        if (page.playing) App.stopPlayback()
                        else if (page.hasTrack) App.play(App.nowPlayingId)
                    }
                }
            }
            MdIconButton {
                size: 56; iconSize: 28
                icon: Icons.skipNext
                iconColor: Theme.textPrimary
                enabled: page.hasTrack
                opacity: enabled ? 1 : 0.35
                onClicked: App.playNext()
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12
            MdIconButton {
                icon: App.engine.masterVolume <= 0.001 ? Icons.volumeOff : Icons.volume
                iconColor: Theme.textSecondary
                property real lastVol: 0.8
                onClicked: {
                    if (App.engine.masterVolume > 0.001) {
                        lastVol = App.engine.masterVolume
                        App.engine.masterVolume = 0
                    } else App.engine.masterVolume = lastVol
                }
            }
            MdSlider {
                anchors.verticalCenter: parent.verticalCenter
                width: 180
                value: App.engine.masterVolume
                onMoved: (v) => App.engine.masterVolume = v
            }
        }
    }

    Timer {
        interval: 250
        running: page.visible && page.hasTrack
        repeat: true
        onTriggered: page.progress = page.hasTrack ? App.engine.progressOf(App.nowPlayingId) : 0
    }
}
