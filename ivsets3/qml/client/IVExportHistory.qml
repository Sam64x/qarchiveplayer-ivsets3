import QtQuick 2.11
import QtQml 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQml.Models 2.1
import QtQuick.Window 2.3
import iv.sets.sets3 1.0
import iv.colors 1.0
import iv.controls 1.0
import QtGraphicalEffects 1.0

IVContextMenu {
    id: root
    //bgColor: IVColors.get("Colors/Background new/BgContextMenuThemed")
    readonly property real isize: 1
    property var model: null
    radius: 8 * root.isize
    component: Component {
        ColumnLayout {
            width: 317 * root.isize
            height: 400 * root.isize
            spacing: 0
            Rectangle {
                Layout.fillWidth: true
                Layout.bottomMargin: 8 * root.isize
                Layout.leftMargin: 16 * root.isize
                Layout.rightMargin: 16 * root.isize
                color: "transparent"
                height: statusColumn.height
                ColumnLayout {
                    id: statusColumn
                    spacing: 4 * root.isize
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                    }
                    property bool smallSpace: true
                    property bool spaceOver: false
                    property bool isRecording: true
                    Rectangle {
                        id: smallSpaceMsg
                        color: IVColors.get("Colors/Text new/TxCritical")
                        width: 144 * root.isize
                        height: 20 * root.isize
                        radius: 8 * root.isize
                        visible: parent.smallSpace
                        Image {
                            id: triangleImage
                            width: 16 * root.isize
                            height: 16 * root.isize
                            anchors {
                                left: parent.left
                                leftMargin: 6 * root.isize
                                verticalCenter: parent.verticalCenter
                            }
                            source: "file:///"+applicationDirPath + "/images/new_images/alert-triangle.svg"
                            ColorOverlay {
                                anchors.fill: parent
                                source: parent
                                color: IVColors.get("Colors/Text new/TxContrast")
                            }
                        }
                        Text {
                            id: alarmText
                            color: IVColors.get("Colors/Text new/TxContrast")
                            font: IVColors.getFont("Subtext")
                            anchors {
                                left: triangleImage.right
                                leftMargin: 3 * root.isize
                                verticalCenter: parent.verticalCenter
                            }
                            text: parent.visible ? "В системе "+(statusColumn.spaceOver ? "нет" : "мало")+" места" : ""
                        }
                    }
                    Row {
                        id: statusTextRow
                        property bool localRec
                        property bool serverRec
                        visible: parent.spaceOver || !parent.smallSpace
                        onLocalRecChanged: {
                            recordPathText.text = "Записи ведутся "
                            recordPathText.text += (localRec && serverRec ? "в " : "только в ")
                            if (localRec && serverRec) recordPathText.text += "<b>Архив</b> и <b>Файлы</b>"
                            else if (serverRec) recordPathText.text += "<b>Архив</b>"
                            else if (localRec) recordPathText.text += "<b>Файлы</b>"
                            else recordPathText.text = "Записи остановлены"
                        }
                        onServerRecChanged: {
                            recordPathText.text = "Записи ведутся "
                            recordPathText.text += (localRec && serverRec ? "в " : "только в ")
                            if (localRec && serverRec) recordPathText.text += "<b>Архив</b> и <b>Файлы</b>"
                            else if (serverRec) recordPathText.text += "<b>Архив</b>"
                            else if (localRec) recordPathText.text += "<b>Файлы</b>"
                            else recordPathText.text = "Записи остановлены"
                        }
                        Text {
                            id: recordPathText
                            color: IVColors.get("Colors/Text new/TxContrast")
                            font: IVColors.getFont("Label")
                            text: "Записи остановлены"
                        }
                        Component.onCompleted: {
                            localRec = true
                            serverRec = true
                        }
                    }
                    Text {
                        id: spaceText
                        color: IVColors.get("Colors/Text new/TxContrast")
                        property string time: "32ч 15м"
                        property int avaliableMb: 101
                        property string units: " МБ"
                        font: IVColors.getFont("Label")
                        text: "<b>"+avaliableMb+" "+units+"</b> " + (!statusColumn.smallSpace ? "доступно" : ("это примерно " + "<b>"+time+"</b>"))
                        onAvaliableMbChanged: {
                            if (avaliableMb > 1024) units = "ГБ"
                            else units = "МБ"
                        }
                    }
                }
                IVButton {
                    source: "new_images/archive"
                    toolTipText: "Открыть папку экспорта"
                    width: 40 * root.isize
                    height: 40 * root.isize
                    type: IVButton.Type.Helper
                    anchors {
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                    }
                    onClicked: {
                        console.trace()
                    }
                }
            }
            Rectangle{
                Layout.fillWidth: true
                height: 1 * root.isize
                color: IVColors.get("Colors/Background new/BgContextMenuThemed")
            }
            ListView {
                id: exportListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.model
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                section.property: "forDate"
                section.delegate: Rectangle {
                    width: parent.width
                    height: 24 * root.isize
                    color: "transparent"
                    Text {
                        text: new Date(parseInt(section)).getFullYear() === new Date().getFullYear() ?
                                  Qt.formatDate(new Date(parseInt(section)), "dd MMMM") :
                                  Qt.formatDate(new Date(parseInt(section)), "dd MMMM yyyy")

                        color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                        font: IVColors.getFont("Subtext")
                        anchors {
                            left: parent.left
                            bottom: parent.bottom
                            leftMargin: 8 * root.isize
                        }
                    }
                }
                delegate: Rectangle {
                    width: parent.width
                    height: 48 * root.isize
                    color: "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8 * root.isize
                        spacing: 0
                        Rectangle {
                            id: exportPreview
                            width: 44 * root.isize
                            radius: 4 * root.isize
                            Layout.fillHeight: true
                            color: Qt.rgba(Math.random(),Math.random(),Math.random(), 0.9)
                        }
                        ColumnLayout {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: model.key2
                                color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                                font: IVColors.getFont("Label accent")
                            }
                            Text {
                                text: model.duration
                                color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                                font: IVColors.getFont("Subtext")
                            }
                        }
                        IVRecordButton {
                            width: 84 * root.isize
                            height: 32 * root.isize
                            sizeMB: JSON.parse(model.sizeMB)
                            type: switch (model.status){
                                  case "recording": return IVRecordButton.Type.Recording
                                  case "recorded": return IVRecordButton.Type.Download
                                  case "saved": return IVRecordButton.Type.Open
                                  case "error": return IVRecordButton.Type.NoSpace
                                  }
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            Timer {
                                id: exportFictive
                                interval: 1000
                                repeat: true
                                property int count: 0
                                onTriggered: {
                                    var randInt = parseInt((Math.random()*15)%15)
                                    parent.sizeMB += randInt
                                    count++;
                                    if (count == 20){
                                        parent.type = IVRecordButton.Type.Download
                                        stop()
                                    }
                                }
                            }
                            onClicked: {
                                switch (type) {
                                case IVRecordButton.Type.Recording:
                                    console.log("Stop recording");
                                    exportFictive.stop()
                                    type = IVRecordButton.Type.Open;
                                    break
                                case IVRecordButton.Type.Download:
                                    console.log("Download file"); break
                                case IVRecordButton.Type.Open:
                                    console.log("Open file"); break
                                case IVRecordButton.Type.NoSpace:
                                    console.log("Error download, no space"); break
                                }
                            }
                            Component.onCompleted: {
                                if (type === IVRecordButton.Type.Recording) exportFictive.start()
                            }
                        }
                    }
                    Rectangle {
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }
                        height: 1 * root.isize
                        color: IVColors.get("Colors/Background new/BgContextMenuThemed")
                    }
                }
            }

            Rectangle{
                Layout.fillWidth: true
                height: 1 * root.isize
                color: IVColors.get("Colors/Background new/BgContextMenuThemed")
            }
            Rectangle{
                Layout.fillWidth: true
                height: 40 * root.isize
                color: "transparent"
                IVButton {
                    text: "Показать ещё"
                    type: IVButton.Type.Tertiary
                    anchors {
                        fill: parent
                        margins: 8 * root.isize
                    }
                    onClicked: {
                        console.trace()
                    }
                }
            }
        }
    }
}
