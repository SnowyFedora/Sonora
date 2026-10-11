import QtQuick
import Sonora

// M3 Search bar: пилюля 56dp, тональная заливка, кнопка очистки.
Item {
    id: root
    property alias text: input.text
    property string placeholder: qsTr("Поиск")

    implicitHeight: 56

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: input.activeFocus ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
        border.width: input.activeFocus ? 2 : 0
        border.color: Theme.primary

        MdIcon {
            id: lead
            x: 18
            anchors.verticalCenter: parent.verticalCenter
            path: Icons.search
            color: Theme.textSecondary
        }

        TextInput {
            id: input
            anchors { left: lead.right; right: clearBtn.left; leftMargin: 14; rightMargin: 8; verticalCenter: parent.verticalCenter }
            color: Theme.textPrimary
            selectionColor: Theme.primaryContainer
            selectedTextColor: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 16
            font.hintingPreference: Font.PreferFullHinting
            renderType: TextInput.NativeRendering
            clip: true
            selectByMouse: true

            MdText {
                visible: input.text.length === 0
                text: root.placeholder
                type: "bodyLarge"
                color: Theme.textSecondary
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MdIconButton {
            id: clearBtn
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            icon: Icons.close
            visible: opacity > 0
            opacity: input.text.length > 0 ? 1 : 0
            scale: input.text.length > 0 ? 1 : 0.6
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.emphasized } }
            onClicked: { input.text = ""; input.forceActiveFocus() }
        }
    }

    function focusInput() { input.forceActiveFocus() }
}
