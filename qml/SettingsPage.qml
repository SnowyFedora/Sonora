import QtQuick
import Sonora
import Sonora.Core

Item {
    id: page

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: column.height + 48
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: column
            y: 24
            x: Math.max(28, (flick.width - width) / 2)
            width: Math.min(760, flick.width - 56)
            spacing: 16

            MdText { text: qsTr("Настройки"); type: "headlineMedium"; bottomPadding: 8 }

            // ── Оформление ───────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: appearance.height + 48
                radius: Theme.radiusXl
                color: Theme.surfaceContainer

                Column {
                    id: appearance
                    x: 24; y: 24
                    width: parent.width - 48
                    spacing: 16

                    MdText { text: qsTr("Оформление"); type: "titleLarge" }

                    MdText { text: qsTr("Тема"); type: "labelLarge"; color: Theme.textSecondary }
                    MdSegmented {
                        model: [qsTr("Системная"), qsTr("Светлая"), qsTr("Тёмная")]
                        currentIndex: App.theme.mode
                        onActivated: (i) => App.theme.mode = i
                    }

                    MdText { text: qsTr("Цвет акцента (Dynamic Color)"); type: "labelLarge"; color: Theme.textSecondary }
                    Flow {
                        width: parent.width
                        spacing: 12
                        Repeater {
                            model: App.theme.presetSeeds
                            delegate: Item {
                                required property color modelData
                                readonly property bool active: Qt.colorEqual(App.theme.seedColor, modelData)
                                width: 48; height: 48
                                Rectangle {
                                    anchors.fill: parent
                                    radius: active ? 16 : 24
                                    color: modelData
                                    scale: sw.pressed ? 0.9 : 1
                                    Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
                                    Behavior on scale { NumberAnimation { duration: 150 } }
                                    MdIcon {
                                        anchors.centerIn: parent
                                        path: Icons.check
                                        color: "white"
                                        opacity: active ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: 200 } }
                                    }
                                }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                MouseArea { id: sw; anchors.fill: parent; onClicked: App.theme.seedColor = modelData }
                            }
                        }
                    }
                    Row {
                        spacing: 8
                        MdButton { variant: "tonal"; text: qsTr("Акцент системы"); onClicked: App.theme.useSystemAccent() }
                        MdButton { variant: "outlined"; text: qsTr("Из изображения…"); onClicked: App.pickImage() }
                    }
                }
            }

            // ── Звук ─────────────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: audio.height + 48
                radius: Theme.radiusXl
                color: Theme.surfaceContainer

                Column {
                    id: audio
                    x: 24; y: 24
                    width: parent.width - 48
                    spacing: 16

                    MdText { text: qsTr("Звук"); type: "titleLarge" }

                    MdText { text: qsTr("Режим воспроизведения"); type: "labelLarge"; color: Theme.textSecondary }
                    MdSegmented {
                        model: [qsTr("Заменять"), qsTr("Накладывать"), qsTr("Очередь")]
                        currentIndex: App.engine.playMode
                        onActivated: (i) => App.engine.playMode = i
                    }

                    MdText { text: qsTr("Общая громкость"); type: "labelLarge"; color: Theme.textSecondary }
                    MdSlider {
                        width: parent.width
                        value: App.engine.masterVolume
                        onMoved: (v) => App.engine.masterVolume = v
                    }

                    MdText { text: qsTr("Устройство вывода"); type: "labelLarge"; color: Theme.textSecondary }
                    Flow {
                        width: parent.width
                        spacing: 8
                        Repeater {
                            model: App.engine.outputDevices
                            delegate: MdChip {
                                required property int index
                                required property string modelData
                                text: modelData
                                selected: App.engine.outputDeviceIndex === index
                                onClicked: App.engine.outputDeviceIndex = index
                            }
                        }
                    }
                }
            }

            // ── Система ──────────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: system.height + 48
                radius: Theme.radiusXl
                color: Theme.surfaceContainer

                Column {
                    id: system
                    x: 24; y: 24
                    width: parent.width - 48
                    spacing: 16

                    MdText { text: qsTr("Система"); type: "titleLarge" }

                    Item {
                        width: parent.width
                        height: 48
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            MdText { text: qsTr("Окно поверх остальных"); type: "bodyLarge" }
                            MdText { text: qsTr("Удобно, если играете в оконном режиме"); type: "bodySmall"; color: Theme.textSecondary }
                        }
                        MdSwitch {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            checked: App.alwaysOnTop
                            onToggled: (c) => App.alwaysOnTop = c
                        }
                    }

                    Item {
                        width: parent.width
                        height: 48
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            MdText { text: qsTr("Горячая клавиша «Стоп всё»"); type: "bodyLarge" }
                            MdText { text: qsTr("Глобальная: работает поверх игр и других окон"); type: "bodySmall"; color: Theme.textSecondary }
                        }
                        Rectangle {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            width: hk.implicitWidth + 24
                            height: 32
                            radius: 8
                            color: Theme.surfaceContainerHighest
                            MdText { id: hk; anchors.centerIn: parent; text: App.stopAllHotkey; type: "labelLarge" }
                        }
                    }

                    MdText {
                        text: qsTr("Бэкенд хоткеев: %1").arg(App.hotkeys.backendName)
                        type: "bodySmall"
                        color: Theme.textSecondary
                    }
                }
            }
        }
    }
}
