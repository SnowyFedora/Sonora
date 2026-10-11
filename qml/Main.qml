import QtQuick
import QtQuick.Controls
import Sonora
import Sonora.Core

ApplicationWindow {
    id: win
    width: 1180
    height: 760
    minimumWidth: 760
    minimumHeight: 520
    visible: true
    title: "Sonora"
    color: Theme.background
    flags: Qt.Window | (App.alwaysOnTop ? Qt.WindowStaysOnTopHint : 0)

    property int section: 0
    property bool playerOpen: false

    // Drag & Drop файлов и папок
    DropArea {
        anchors.fill: parent
        keys: ["text/uri-list"]
        onEntered: (d) => dropHint.shown = true
        onExited: dropHint.shown = false
        onDropped: (d) => {
            dropHint.shown = false
            if (d.hasUrls) App.addUrls(d.urls)
        }
    }

    NavRail {
        id: rail
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        currentIndex: win.section
        onNavigated: (i) => {
            if (i === win.section) return
            win.section = i
            stack.replace(win.pageFor(i))
        }
        onAddClicked: App.pickFolder()
        onAddFilesClicked: App.pickFiles()
    }

    // Контентная панель с тональной поверхностью и большим скруглением
    Rectangle {
        id: panel
        anchors { left: rail.right; top: parent.top; right: parent.right; bottom: parent.bottom; topMargin: 12; rightMargin: 12; bottomMargin: 12 }
        radius: Theme.radiusXl
        color: Theme.surfaceContainerLow

        StackView {
            id: stack
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: dock.top }
            initialItem: allPage

            // Fade through: старая страница гаснет за 90 мс, новая появляется с scale 0.92 → 1
            replaceExit: Transition {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 90; easing.type: Easing.Linear }
            }
            replaceEnter: Transition {
                SequentialAnimation {
                    PropertyAction { property: "opacity"; value: 0 }
                    PauseAnimation { duration: 90 }
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 210 }
                        NumberAnimation { property: "scale"; from: 0.92; to: 1; duration: 300
                            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasizedDecelerate }
                    }
                }
            }
        }

        // Нижний «док» с общей громкостью
        Item {
            id: dock
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: win.playerOpen ? 0 : 96
            visible: height > 0
            MasterBar {
                anchors.centerIn: parent
                width: Math.min(720, parent.width - 48)
                onExpandRequested: win.playerOpen = true
            }
        }

        // Полноэкранный плеер поверх контента
        PlayerPage {
            anchors.fill: parent
            visible: win.playerOpen
            opacity: win.playerOpen ? 1 : 0
            z: 20
            Behavior on opacity { NumberAnimation { duration: 220 } }
            onCloseRequested: win.playerOpen = false
        }
    }

    function pageFor(i) {
        if (i === 0) return allPage
        if (i === 1) return playlistsPage
        if (i === 2) return favPage
        if (i === 3) return recentPage
        return settingsPage
    }

    Component { id: allPage;       LibraryPage { kind: "all"; title: qsTr("Звуки"); onAddRequested: App.pickFolder(); onAddFilesRequested: App.pickFiles() } }
    Component { id: playlistsPage; PlaylistsPage {} }
    Component { id: favPage;       LibraryPage { kind: "favorites"; title: qsTr("Избранное") } }
    Component { id: recentPage;    LibraryPage { kind: "recent";    title: qsTr("Недавние") } }
    Component { id: settingsPage;  SettingsPage {} }

    // Подсказка при перетаскивании
    Rectangle {
        id: dropHint
        property bool shown: false
        anchors.fill: panel
        radius: Theme.radiusXl
        color: Qt.alpha(Theme.primaryContainer, 0.92)
        opacity: shown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Column {
            anchors.centerIn: parent
            spacing: 12
            MdIcon { anchors.horizontalCenter: parent.horizontalCenter; path: Icons.add; size: 48; color: Theme.textOnAccent }
            MdText { text: qsTr("Отпустите, чтобы добавить звуки"); type: "titleLarge"; color: Theme.textOnAccent }
        }
    }

    // Snackbar (M3): всплывает снизу
    Rectangle {
        id: toast
        property string message
        anchors.horizontalCenter: panel.horizontalCenter
        width: toastText.implicitWidth + 48
        height: 48
        radius: 12
        color: Theme.inverseSurface
        y: win.height - (shown ? 108 : 0)
        property bool shown: false
        opacity: shown ? 1 : 0
        visible: opacity > 0
        Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MdText { id: toastText; anchors.centerIn: parent; text: toast.message; type: "bodyMedium"; color: Theme.inverseOnSurface }
        Timer { id: toastTimer; interval: 3500; onTriggered: toast.shown = false }
    }
    Connections {
        target: App
        function onToast(message) {
            toast.message = message
            toast.shown = true
            toastTimer.restart()
        }
    }
}
