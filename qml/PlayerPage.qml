import QtQuick
import Sonora
import Sonora.Core

// Полноэкранный плеер: обложка, название, prev/play/next, прогресс, громкость
Item {
    id: page
    signal closeRequested()

    readonly property bool hasTrack: App.nowPlayingId !== ""
    readonly property bool playing: App.isPlaying
    property bool scrubbing: false
    property real scrubValue: 0
    readonly property real liveProgress: App.engine.progress
    readonly property real displayProgress: scrubbing ? scrubValue : liveProgress

    function fmtMs(ms) {
        if (ms === undefined || ms < 0 || !isFinite(ms))
            return "0:00"
        var s = Math.floor(ms / 1000)
        var m = Math.floor(s / 60)
        s = s % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    // Фон
    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceContainerLow
        radius: Theme.radiusXl
    }

    // Мягкий градиент акцента сверху
    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: parent.height * 0.45
        radius: Theme.radiusXl
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(Theme.primaryContainer, 0.55) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Кнопка свернуть
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

        // Обложка
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(280, parent.width)
            height: width
            radius: Theme.radiusLg
            color: Theme.primaryContainer
            scale: coverPress.pressed ? 0.98 : 1
            Behavior on scale { NumberAnimation { duration: 150 } }

            // Декоративные круги
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.72
                height: width
                radius: width / 2
                color: Qt.alpha(Theme.primary, 0.2)
            }
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.4
                height: width
                radius: width / 2
                color: Qt.alpha(Theme.primary, 0.35)
            }
            MdIcon {
                anchors.centerIn: parent
                path: Icons.musicNote
                size: 72
                color: Theme.textOnAccent
            }

            // Буква из названия
            MdText {
                anchors.centerIn: parent
                visible: page.hasTrack
                text: page.hasTrack && App.nowPlayingTitle.length > 0
                      ? App.nowPlayingTitle.charAt(0).toUpperCase() : ""
                type: "displaySmall"
                color: Theme.textOnAccent
                opacity: 0.15
                z: -1
            }

            HoverHandler { id: coverHover }
            MouseArea { id: coverPress; anchors.fill: parent }
        }

        // Текст
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

        // Прогресс + время + перемотка
        Column {
            width: parent.width
            spacing: 6
            visible: page.hasTrack

            MdSlider {
                width: parent.width
                value: page.displayProgress
                onMoved: (v) => {
                    page.scrubbing = true
                    page.scrubValue = v
                    App.engine.seek(v)
                    scrubEnd.restart()
                }
                // Завершить перемотку после прекращения движения ползунка.
                Timer {
                    id: scrubEnd
                    interval: 400
                    onTriggered: page.scrubbing = false
                }
            }

            Row {
                width: parent.width
                MdText {
                    text: page.fmtMs(page.scrubbing
                        ? page.scrubValue * App.engine.durationMs
                        : App.engine.positionMs)
                    type: "labelMedium"
                    color: Theme.textSecondary
                }
                Item { width: parent.width - 100; height: 1 }
                MdText {
                    text: page.fmtMs(App.engine.durationMs)
                    type: "labelMedium"
                    color: Theme.textSecondary
                }
            }
        }

        // Кнопки управления
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

            MdIconButton {
                size: 56
                iconSize: 28
                icon: Icons.skipPrevious
                iconColor: Theme.textPrimary
                enabled: page.hasTrack
                opacity: enabled ? 1 : 0.35
                onClicked: App.playPrevious()
            }

            Rectangle {
                width: 72; height: 72
                radius: 36
                color: Theme.primary
                scale: mainPress.pressed ? 0.92 : 1
                Behavior on scale { NumberAnimation { duration: 120 } }
                MdIcon {
                    anchors.centerIn: parent
                    path: page.playing ? Icons.stop : Icons.play
                    size: 32
                    color: Theme.textOnFilled
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    id: mainPress
                    anchors.fill: parent
                    onClicked: {
                        if (page.playing)
                            App.stopPlayback()
                        else if (page.hasTrack)
                            App.play(App.nowPlayingId)
                    }
                }
            }

            MdIconButton {
                size: 56
                iconSize: 28
                icon: Icons.skipNext
                iconColor: Theme.textPrimary
                enabled: page.hasTrack
                opacity: enabled ? 1 : 0.35
                onClicked: App.playNext()
            }
        }

        // Громкость
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
                    } else {
                        App.engine.masterVolume = lastVol
                    }
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

}

