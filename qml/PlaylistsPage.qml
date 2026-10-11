import QtQuick
import Sonora
import Sonora.Core

// Список плейлистов + просмотр выбранного.
Item {
    id: page
    property string openPlaylistId: ""
    property string openPlaylistName: ""

    // ── Список плейлистов ────────────────────────────────────────────────
    Item {
        id: listView
        anchors.fill: parent
        visible: page.openPlaylistId === ""
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Item {
            id: header
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 28; topMargin: 24 }
            height: 48
            MdText { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Плейлисты"); type: "headlineMedium" }
            MdButton {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: qsTr("Создать")
                icon: Icons.add
                onClicked: {
                    const id = App.library.createPlaylist(qsTr("Новый плейлист"))
                    page.openPlaylistId = id
                    page.openPlaylistName = qsTr("Новый плейлист")
                }
            }
        }

        ListView {
            id: plList
            anchors { top: header.bottom; topMargin: 16; left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 20; rightMargin: 20 }
            clip: true
            spacing: 8
            model: App.library.playlists
            delegate: Rectangle {
                required property var modelData
                width: plList.width
                height: 72
                radius: Theme.radiusLg
                color: Theme.surfaceContainerHigh
                scale: rowPress.pressed ? 0.98 : 1
                Behavior on scale { NumberAnimation { duration: 150 } }

                Row {
                    anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                    spacing: 16
                    Rectangle {
                        width: 48; height: 48; radius: 14
                        color: Theme.secondaryContainer
                        MdIcon { anchors.centerIn: parent; path: Icons.playlist; color: Theme.textOnAccent; size: 24 }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        MdText { text: modelData.name; type: "titleMedium" }
                        MdText {
                            text: qsTr("%1 треков").arg(modelData.count)
                            type: "bodySmall"
                            color: Theme.textSecondary
                        }
                    }
                }

                Row {
                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 4
                    MdIconButton {
                        icon: Icons.trash
                        iconColor: Theme.textSecondary
                        onClicked: App.library.deletePlaylist(modelData.id)
                    }
                }

                HoverHandler { cursorShape: Qt.PointingHandCursor }
                MouseArea {
                    id: rowPress
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        page.openPlaylistId = modelData.id
                        page.openPlaylistName = modelData.name
                    }
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 16
            visible: App.library.playlists.length === 0
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 96; height: 96; radius: 32
                color: Theme.primaryContainer
                MdIcon { anchors.centerIn: parent; path: Icons.playlist; size: 48; color: Theme.textOnAccent }
            }
            MdText { anchors.horizontalCenter: parent.horizontalCenter; text: qsTr("Нет плейлистов"); type: "titleLarge" }
            MdText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Создай плейлист и добавь треки из библиотеки")
                type: "bodyMedium"
                color: Theme.textSecondary
            }
            MdButton {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Создать плейлист")
                icon: Icons.add
                onClicked: {
                    const id = App.library.createPlaylist(qsTr("Новый плейлист"))
                    page.openPlaylistId = id
                    page.openPlaylistName = qsTr("Новый плейлист")
                }
            }
        }
    }

    // ── Содержимое плейлиста ─────────────────────────────────────────────
    LibraryPage {
        anchors.fill: parent
        visible: page.openPlaylistId !== ""
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        kind: "playlist"
        title: page.openPlaylistName
        playlistId: page.openPlaylistId
        showBack: true
        onBackRequested: { page.openPlaylistId = ""; page.openPlaylistName = "" }
    }
}
