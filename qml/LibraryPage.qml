import QtQuick
import Sonora
import Sonora.Core

// Универсальная страница списка звуков: kind = "all" | "favorites" | "recent" | "playlist".
Item {
    id: page
    property string kind: "all"
    property string title: qsTr("Звуки")
    property string folderFilter: ""
    property string playlistId: ""
    property bool showBack: false
    signal backRequested()
    signal addRequested()
    signal addFilesRequested()

    SoundFilterModel {
        id: proxy
        sourceModel: App.library
        onlyFavorites: page.kind === "favorites"
        recentOnly: page.kind === "recent"
        playlistId: page.kind === "playlist" ? page.playlistId : ""
        searchText: search.text
        folder: page.folderFilter
    }

    // ── Заголовок ────────────────────────────────────────────────────────
    Item {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 28; topMargin: 24 }
        height: Math.max(titleCol.height, backBtn.height)

        MdIconButton {
            id: backBtn
            visible: page.showBack
            anchors { left: parent.left; verticalCenter: titleCol.verticalCenter }
            icon: Icons.back
            iconColor: Theme.textPrimary
            onClicked: page.backRequested()
        }

        Column {
            id: titleCol
            anchors.left: page.showBack ? backBtn.right : parent.left
            anchors.leftMargin: page.showBack ? 8 : 0
            spacing: 2
            MdText { text: page.title; type: "headlineMedium" }
            MdText {
                type: "bodyMedium"
                color: Theme.textSecondary
                text: qsTr("Звуков: %1").arg(proxy.count)
            }
        }

        MdSegmented {
            anchors { right: parent.right; verticalCenter: titleCol.verticalCenter }
            visible: page.width > 760
            model: [qsTr("Заменять"), qsTr("Накладывать"), qsTr("Очередь")]
            currentIndex: App.engine.playMode
            onActivated: (i) => App.engine.playMode = i
        }
    }

    MdSearchBar {
        id: search
        anchors { top: header.bottom; topMargin: 20; left: parent.left; right: parent.right; leftMargin: 28; rightMargin: 28 }
        placeholder: qsTr("Поиск по названию, папке и тегам")
    }

    // ── Папки ────────────────────────────────────────────────────────────
    ListView {
        id: chips
        visible: page.kind === "all" && App.library.folders.length > 0
        anchors { top: search.bottom; topMargin: 14; left: parent.left; right: parent.right; leftMargin: 28; rightMargin: 28 }
        height: visible ? 32 : 0
        orientation: ListView.Horizontal
        spacing: 8
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: [""].concat(App.library.folders)
        delegate: MdChip {
            required property string modelData
            text: modelData === "" ? qsTr("Все") : modelData.replace(/\//g, " / ")
            selected: page.folderFilter === modelData
            onClicked: page.folderFilter = modelData
        }
    }

    // ── Сетка ────────────────────────────────────────────────────────────
    GridView {
        id: grid
        anchors {
            top: chips.visible ? chips.bottom : search.bottom
            topMargin: 14
            left: parent.left; right: parent.right; bottom: parent.bottom
            leftMargin: 22; rightMargin: 22
        }
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: proxy
        readonly property int columns: Math.max(2, Math.floor(width / 210))
        cellWidth: width / columns
        cellHeight: 156

        delegate: Item {
            required property int index
            required property string soundId
            required property string title
            required property string folder
            required property bool favorite
            required property string hotkey
            width: grid.cellWidth
            height: grid.cellHeight

            SoundCard {
                anchors.fill: parent
                anchors.margins: 6
                soundId: parent.soundId
                title: parent.title
                folder: parent.folder
                favorite: parent.favorite
                hotkey: parent.hotkey
                appearDelay: Math.min(parent.index, 12) * 24
                onTriggered: App.play(soundId)
                onFavoriteToggled: App.toggleFavorite(soundId)
            }
        }

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
        }
        displaced: Transition {
            NumberAnimation { properties: "x,y"; duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized }
        }
    }

    // ── Пустое состояние ─────────────────────────────────────────────────
    Column {
        anchors.centerIn: grid
        spacing: 16
        visible: proxy.count === 0
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 96; height: 96
            radius: 32
            color: Theme.primaryContainer
            MdIcon {
                anchors.centerIn: parent
                size: 48
                path: page.kind === "favorites" ? Icons.star
                    : page.kind === "recent" ? Icons.history : Icons.musicNote
                color: Theme.textOnAccent
            }
        }
        MdText {
            anchors.horizontalCenter: parent.horizontalCenter
            type: "titleLarge"
            text: search.text !== "" ? qsTr("Ничего не найдено")
                : page.kind === "favorites" ? qsTr("Пока нет избранного")
                : page.kind === "recent" ? qsTr("Вы ещё ничего не воспроизводили")
                : qsTr("Библиотека пуста")
        }
        MdText {
            anchors.horizontalCenter: parent.horizontalCenter
            type: "bodyMedium"
            color: Theme.textSecondary
            horizontalAlignment: Text.AlignHCenter
            text: page.kind === "all" && search.text === ""
                  ? qsTr("Добавьте папку со звуками или перетащите файлы в окно")
                  : qsTr("Попробуйте изменить запрос или фильтр")
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12
            visible: page.kind === "all" && search.text === ""
            MdButton {
                text: qsTr("Добавить папку")
                icon: Icons.folder
                onClicked: page.addRequested()
            }
            MdButton {
                variant: "tonal"
                text: qsTr("Добавить звук")
                icon: Icons.musicNote
                onClicked: page.addFilesRequested()
            }
        }
    }
}
