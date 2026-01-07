import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

import iv.colors 1.0
import iv.singletonLang 1.0
import iv.controls 1.0 as C

ListView {
    id: root

    property var cameraModel: [
        {"cameraName": "Camera name P1346", "eventName": "3 события"},
        {"cameraName": "Camera name 262", "eventName": "5 событий"},
        {"cameraName": "Camera name 3", "eventName": "Нет событий"}
    ]

    implicitHeight: contentHeight
    clip: true
    model: cameraModel
    boundsBehavior: ListView.StopAtBounds

    delegate: Item {
        height: 48
        width: parent.width

        RowLayout {
            width: parent.width
            height: parent.height
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 32
                color: IVColors.get("Colors/Background new/BgFormAccent")
                radius: 8
            }

            ColumnLayout {
                spacing: 0
                Text {
                    text: modelData.cameraName
                    font: IVColors.getFont("Label accent")
                    color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                }

                Text {
                    text: modelData.eventName
                    font: IVColors.getFont("subtext")
                    color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                }
            }

            Item {
                Layout.fillWidth: true
            }

            C.IVButtonControl {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: 8
                source: "new_images/x-close"
                contentColor: IVColors.get("Colors/Text new/TxTertiaryThemed")
                type: C.IVButtonControl.Type.Flat
                size: C.IVButtonControl.Size.Big

            }
        }

        Rectangle {
            visible: index !== root.count - 1
            anchors.bottom: parent.bottom
            height: 1
            width: parent.width
            color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
        }
    }
}
