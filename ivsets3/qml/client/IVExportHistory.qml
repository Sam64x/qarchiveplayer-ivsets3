import QtQml 2.3
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.0

import ArchiveComponents 1.0
import iv.singletonLang 1.0
import iv.controls 1.0 as Controls
import iv.colors 1.0
import iv.viewers.archiveplayer 1.0 as ArchivePlayerModule

Popup {
    id: root

    rightPadding: 0
    leftPadding: 0
    topPadding: 0
    bottomPadding: 0

    closePolicy: Popup.CloseOnPressOutsideParent | Popup.CloseOnReleaseOutsideParent

    background: Item {
        Rectangle {
            id: rect
            anchors.fill: parent
            color: IVColors.get("Colors/Background new/BgContextMenuThemed")
            radius: 4
        }

        DropShadow {
            anchors.fill: rect
            source: rect
            verticalOffset: 10
            radius: 24
            spread: 0.3
            color: "#4D020720"
            samples: 32
        }
    }

    contentItem: Item {
        implicitWidth: 444
        implicitHeight: contentLayout.implicitHeight

        ColumnLayout {
            id: contentLayout

            anchors.fill: parent
            spacing: 0

            Label {
                Layout.topMargin: visible ? 16 : 0
                Layout.bottomMargin: visible ? 16 : 0
                Layout.alignment: Qt.AlignHCenter

                visible: !ExportManager.activeExportsModel.count
                text: "Нет активных/завершенных выгрузок для отображения"
                color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                font: IVColors.getFont("Label accent")
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 56

                visible: ExportManager.activeExportsModel.count
                color: IVColors.get("Colors/Background new/BgListPrimaryThemed")
                radius: 4

                RowLayout {
                    anchors {
                        fill: parent
                        topMargin: 8
                        leftMargin: 16
                        rightMargin: 16
                        bottomMargin: 8
                    }

                    spacing: 0

                    Text {
                        text: Language.getTranslate("Export History", "История выгрузки")
                        color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                        font: IVColors.getFont("Label accent")
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Controls.IVButtonControl {
                        id: openFolderButton

                        property string folderUrl: ""

                        implicitWidth: 40
                        implicitHeight: 40

                        enabled: folderUrl
                        source: "new_images/archive"

                        onClicked: {
                            Qt.openUrlExternally(folderUrl);
                        }
                    }
                }
            }

            ListView {
                id: activeExportListView
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight + bottomMargin, 400)
                Layout.leftMargin: 16
                Layout.rightMargin: 4
                rightMargin: 12
                bottomMargin: 4

                model: ExportManager.activeExportsModel
                visible: count
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    width: 8
                    policy: ScrollBar.AlwaysOn
                    visible: parent.contentHeight > parent.height
                    contentItem: Rectangle {
                        implicitWidth: parent.width
                        implicitHeight: parent.height / activeExportListView.contentHeight
                        radius: width / 2
                        color: parent.pressed ? IVColors.get("Colors/Text new/TxPrimaryThemed") :
                                                 IVColors.get("Colors/Background new/BgFormSecondaryThemed")
                    }
                }

                section.property: "exportDate"
                section.delegate: Column {
                    spacing: 0

                    Item {
                        implicitWidth: 1
                        implicitHeight: 8
                    }

                    Text {
                        text: privates.formatDateLabel(section)
                        color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                        font: IVColors.getFont("Label accent")
                    }
                }

                delegate: ArchivePlayerModule.UploadProgressBar {
                    property int modelIndex: index

                    width: ListView.view.width - ListView.view.rightMargin

                    cameraName: model.cameraName
                    timeText: model.timeText
                    selectedPath: model.path
                    exportController: model.controller
                    statusOverride: model.status === ArchivePlayerModule.UploadProgressBar.Status.Uploading
                                    ? undefined : model.status
                    progressOverride: model.status === ArchivePlayerModule.UploadProgressBar.Status.Uploading
                                      ? undefined : model.progress
                    previewOverride: model.preview
                    sizeOverride: model.sizeBytes

                    onRemoveRequested: {
                         if (ExportManager)
                            ExportManager.removeExport(modelIndex)
                    }
                    onRestartRequested: {
                        if (ExportManager)
                            ExportManager.restartExport(modelIndex)
                    }

                    onSelectedPathChanged: {
                        updateFolderUrl();
                    }
                    onStatusChanged: {
                        updateFolderUrl();
                    }
                    function updateFolderUrl() {
                        if (status === ArchivePlayerModule.UploadProgressBar.Status.Done && selectedPath) {
                            openFolderButton.folderUrl = localFileUrl(selectedPath);
                        }
                    }

                    Rectangle {
                        height: 1
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }

                        color: IVColors.get("Colors/Stroke new/StSeparatorThemed")
                    }
                }
            }
        }
    }

    QtObject {
        id: privates

        function formatDateLabel(dateStr) {
            // Парсим строку вида "dd.MM.yyyy"
            const parts = dateStr.split(".");
            if (parts.length !== 3) return dateStr;

            const day = parseInt(parts[0], 10);
            const month = parseInt(parts[1], 10) - 1; // месяцы в JS: 0–11
            const year = parseInt(parts[2], 10);

            const date = new Date(year, month, day);

            // Проверяем корректность
            if (isNaN(date.getTime())) return dateStr;

            // Получаем начало "сегодня" и "вчера" (без времени)
            const now = new Date();
            const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
            const yesterday = new Date(today.getTime() - 24 * 60 * 60 * 1000);

            const targetDay = new Date(date.getFullYear(), date.getMonth(), date.getDate());

            if (targetDay.getTime() === today.getTime()) {
                return "Сегодня";
            } else if (targetDay.getTime() === yesterday.getTime()) {
                return "Вчера";
            } else {
                const months = [
                    "января", "февраля", "марта", "апреля", "мая", "июня",
                    "июля", "августа", "сентября", "октября", "ноября", "декабря"
                ];
                return day + " " + months[date.getMonth()] + " " + year;
            }
        }
    }
}
