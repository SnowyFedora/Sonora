import QtQuick
import Sonora
import Sonora.Core

// Вкладка YouTube Music — список как в Я.Музыке: обложка, название, артист, play.
Item {
    id: page

    Component.onCompleted: {
        if (App.ytm.tracks.length === 0)
            App.ytm.loadHome()
    }

    // Header
    Item {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 28; topMargin: 24 }
        height: 56

        Column {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            MdText { text: qsTr("YouTube Music"); type: "headlineMedium" }
            MdText {
                text: App.ytm.status
                type: "bodySmall"
                color: Theme.textSecondary
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            MdButton {
                text: qsTr("Для тебя")
                variant: "tonal"
                onClicked: App.ytm.loadHome()
            }
        }
    }

    MdSearchBar {
        id: search
        anchors { top: header.bottom; left: parent.left; right: parent.right; topMargin: 12; leftMargin: 28; rightMargin: 28 }
        placeholder: qsTr("Поиск на YouTube Music…")
        Timer {
            id: searchTimer
            interval: 450
            onTriggered: {
                if (search.text.trim().length > 0)
                    App.ytm.search(search.text.trim())
            }
        }
        Connections {
            target: search
            function onTextChanged() { searchTimer.restart() }
        }
    }

    // Track list
    ListView {
        id: list
        anchors {
            top: search.bottom; topMargin: 16
            left: parent.left; right: parent.right
            bottom: nowPlaying.visible ? nowPlaying.top : parent.bottom
            leftMargin: 16; rightMargin: 16; bottomMargin: 8
        }
        clip: true
        spacing: 4
        model: App.ytm.tracks
        delegate: Rectangle {
            required property var modelData
            required property int index
            width: list.width
            height: 64
            radius: Theme.radiusMd
            color: {
                if (modelData.id === App.ytm.currentId)
                    return Theme.secondaryContainer
                return rowHover.hovered ? Theme.surfaceContainerHigh : "transparent"
            }
            Behavior on color { ColorAnimation { duration: 120 } }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 12

                // Cover
                Rectangle {
                    width: 48; height: 48
                    radius: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.surfaceContainerHighest
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: modelData.thumb || ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    MdIcon {
                        anchors.centerIn: parent
                        visible: !modelData.thumb
                        path: Icons.musicNote
                        size: 22
                        color: Theme.textSecondary
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 48 - 48 - 36
                    spacing: 2
                    MdText {
                        width: parent.width
                        text: modelData.title || ""
                        type: "titleSmall"
                        elide: Text.ElideRight
                    }
                    MdText {
                        width: parent.width
                        text: (modelData.artist || "") + (modelData.duration ? " · " + modelData.duration : "")
                        type: "bodySmall"
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                    }
                }

                MdIconButton {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: (modelData.id === App.ytm.currentId && App.ytm.playing) ? Icons.stop : Icons.play
                    iconColor: Theme.textPrimary
                    onClicked: {
                        if (modelData.id === App.ytm.currentId && App.ytm.playing)
                            App.ytm.stop()
                        else
                            App.ytm.playTrack(modelData.id, modelData.title || "", modelData.artist || "")
                    }
                }
            }

            HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 48
                onDoubleClicked: App.ytm.playTrack(modelData.id, modelData.title || "", modelData.artist || "")
            }
        }
    }

    // Empty / loading
    Column {
        anchors.centerIn: parent
        spacing: 12
        visible: App.ytm.tracks.length === 0
        MdText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: App.ytm.busy ? qsTr("Загрузка…") : qsTr("Найди трек или открой «Для тебя»")
            type: "titleMedium"
            color: Theme.textSecondary
        }
        MdText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !App.ytm.available && !App.ytm.busy
            text: qsTr("pip install -r requirements-ytm.txt")
            type: "bodySmall"
            color: Theme.textSecondary
        }
    }

    // Now playing bar (Я.Музыка style)
    Rectangle {
        id: nowPlaying
        visible: App.ytm.currentId !== ""
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 16 }
        height: 72
        radius: Theme.radiusLg
        color: Theme.primaryContainer

        Row {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 14

            Rectangle {
                width: 48; height: 48; radius: 10
                color: Theme.primary
                MdIcon {
                    anchors.centerIn: parent
                    path: Icons.musicNote
                    color: Theme.textOnFilled
                    size: 24
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 48 - 100
                spacing: 2
                MdText {
                    width: parent.width
                    text: App.ytm.currentTitle
                    type: "titleSmall"
                    color: Theme.textOnAccent
                    elide: Text.ElideRight
                }
                MdText {
                    width: parent.width
                    text: App.ytm.currentArtist
                    type: "bodySmall"
                    color: Theme.textOnAccent
                    opacity: 0.8
                    elide: Text.ElideRight
                }
            }

            MdIconButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: App.ytm.playing ? Icons.stop : Icons.play
                iconColor: Theme.textOnAccent
                onClicked: {
                    if (App.ytm.playing)
                        App.ytm.stop()
                    else if (App.ytm.currentId)
                        App.ytm.playTrack(App.ytm.currentId, App.ytm.currentTitle, App.ytm.currentArtist)
                }
            }
        }
    }

    // Busy spinner-ish
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: search.bottom
        anchors.topMargin: 8
        width: 120; height: 3
        radius: 2
        color: Theme.primary
        visible: App.ytm.busy
        opacity: 0.7
    }
}
