import QtQuick
import Sonora
import Sonora.Core

// Нижний плеер: prev / play / next · трек · громкость · стоп
Rectangle {
    id: root
    readonly property int playingCount: App.engine.playingIds.length
    readonly property real volume: App.engine.masterVolume
    readonly property bool hasTrack: App.nowPlayingId !== ""
    readonly property bool playing: App.isPlaying
    signal expandRequested()
    property bool scrubbing: false
    property real scrubValue: 0

    function fmtMs(ms) {
        if (ms === undefined || ms < 0 || !isFinite(ms)) return "0:00"
        var s = Math.floor(ms / 1000)
        var m = Math.floor(s / 60)
        s = s % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    implicitWidth: 640
    implicitHeight: 72
    radius: Theme.radiusXl
    color: Theme.surfaceContainerHighest
    clip: true

    // Полоса прогресса внутри бара (с отступами — не вылезает за скругления)
    Item {
        id: progStrip
        anchors {
            left: parent.left; right: parent.right; top: parent.top
            leftMargin: 16; rightMargin: 16; topMargin: 6
        }
        height: 8
        z: 2
        visible: root.hasTrack
        clip: true

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 3
            radius: 1.5
            color: Theme.surfaceContainerHigh
            Rectangle {
                height: parent.height
                width: Math.max(0, Math.min(parent.width, parent.width * (root.scrubbing ? root.scrubValue : App.engine.progress)))
                radius: 1.5
                color: Theme.primary
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: (m) => {
                root.scrubbing = true
                const v = Math.max(0, Math.min(1, m.x / Math.max(1, width)))
                root.scrubValue = v
                App.engine.seek(v)
            }
            onPositionChanged: (m) => {
                if (!pressed) return
                const v = Math.max(0, Math.min(1, m.x / Math.max(1, width)))
                root.scrubValue = v
                App.engine.seek(v)
            }
            onReleased: root.scrubbing = false
        }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: root.hasTrack ? 10 : 0
        spacing: 8

        // Transport
        MdIconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: Icons.skipPrevious
            iconColor: Theme.textPrimary
            enabled: root.hasTrack
            opacity: enabled ? 1 : 0.35
            onClicked: App.playPrevious()
        }
        Rectangle {
            width: 48; height: 48
            radius: 24
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.primary
            scale: playPress.pressed ? 0.92 : 1
            Behavior on scale { NumberAnimation { duration: 120 } }
            MdIcon {
                anchors.centerIn: parent
                path: root.playing ? Icons.stop : Icons.play
                color: Theme.textOnFilled
                size: 22
            }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            MouseArea {
                id: playPress
                anchors.fill: parent
                onClicked: {
                    if (root.playing)
                        App.stopPlayback()
                    else if (root.hasTrack)
                        App.play(App.nowPlayingId)
                }
            }
        }
        MdIconButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: Icons.skipNext
            iconColor: Theme.textPrimary
            enabled: root.hasTrack
            opacity: enabled ? 1 : 0.35
            onClicked: App.playNext()
        }

        // Title block — клик открывает полный плеер
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(120, root.width - 420)
            height: parent.height
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 40
                spacing: 2
                MdText {
                    width: parent.width
                    text: root.hasTrack ? App.nowPlayingTitle : qsTr("Не играет")
                    type: "titleSmall"
                    elide: Text.ElideRight
                    color: Theme.textPrimary
                }
                MdText {
                    width: parent.width
                    text: {
                        if (!root.hasTrack)
                            return qsTr("Выбери трек в библиотеке")
                        const pos = root.fmtMs(root.scrubbing ? root.scrubValue * App.engine.durationMs : App.engine.positionMs)
                        const dur = root.fmtMs(App.engine.durationMs)
                        const art = App.nowPlayingArtist
                        return art ? (art + " · " + pos + " / " + dur) : (pos + " / " + dur)
                    }
                    type: "bodySmall"
                    elide: Text.ElideRight
                    color: Theme.textSecondary
                }
            }
            MdIconButton {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                icon: Icons.expand
                iconColor: Theme.textSecondary
                onClicked: root.expandRequested()
            }
            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 40
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expandRequested()
            }
        }

        // Volume
        MdIconButton {
            id: muteBtn
            anchors.verticalCenter: parent.verticalCenter
            icon: root.volume <= 0.001 ? Icons.volumeOff : Icons.volume
            iconColor: Theme.textPrimary
            property real lastVolume: 0.8
            onClicked: {
                if (root.volume > 0.001) { lastVolume = root.volume; App.engine.masterVolume = 0 }
                else App.engine.masterVolume = lastVolume
            }
        }
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 100
            height: 28
            clip: true
            MdSlider {
                id: volSlider
                anchors.centerIn: parent
                width: parent.width
                height: 28
                value: root.volume
                onMoved: (v) => App.engine.masterVolume = v
            }
        }
        MdText {
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            text: Math.round(root.volume * 100) + "%"
            type: "labelMedium"
            color: Theme.textSecondary
        }
    }
}
