import QtQml 2.3
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11

import iv.viewers.archiveplayer 1.0 as Archive
import iv.singletonLang 1.0
import iv.controls 1.0 as C
import iv.colors 1.0

C.IVButtonControl {
    id: control

    property var rootRef

    implicitWidth: 40
    implicitHeight: 24
    rightPadding: 8
    leftPadding: 8
    spacing: 4
    source: "new_images/record-list.svg"
    text: Archive.ExportManager.activeExportsModel.count.toString()
    size: C.IVButtonControl.Size.Small
    type: C.IVButtonControl.Type.Tertiary
    checkable: true
    checked: artiveExportMenu.opened
    toolTipText: Language.getTranslate("Open exports","Открыть выгрузки")
    toolTipVisible: !artiveExportMenu.opened && toolTipText.length > 0 && hovered
    onClicked: {
        if (artiveExportMenu.opened)
            artiveExportMenu.close()
        else
            artiveExportMenu.open()
    }

    C.IVContextMenuControl {
       id: artiveExportMenu
       bgColor: IVColors.get("Colors/Background new/BgContextMenuThemed")
       horizontalPadding: 0
       visible: Archive.ExportManager.showExportsPanel && Archive.ExportManager.activeExportsModel.count > 0

       readonly property real popupWidth: Math.min(artiveExportMenu.implicitWidth, 444)
       readonly property real controlWidth: popupWidth + artiveExportMenu.leftPadding + artiveExportMenu.rightPadding

       x: {
           artiveExportMenu.opened;
           var cx = (control.width - artiveExportMenu.controlWidth) / 2;
           var p = control.mapToItem(rootRef, 0, 0);
           var right = p.x + cx + artiveExportMenu.controlWidth + artiveExportMenu.leftPadding;
           var diff = Math.min(0, rootRef.width - right);
           return cx + diff;
       }

       component: ColumnLayout {
           spacing: 0

           ColumnLayout {
               Layout.fillWidth: true
               Layout.leftMargin: 12
               Layout.rightMargin: 16
               spacing: 8

               Item {
                   Layout.fillWidth: true
                   Layout.preferredHeight: 32

                   Text {
                       text: Language.getTranslate("Export History", "История выгрузки")
                       anchors.verticalCenter: parent.verticalCenter
                       anchors.left: parent.left
                       color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                       font: IVColors.getFont("Label accent")
                   }
               }
           }

           Repeater {
               model: Archive.ExportManager.activeExportsModel
               Layout.fillWidth: true

               delegate: UploadProgressBar {
                   property int modelIndex: index

                   Layout.fillWidth: true
                   Layout.leftMargin: 16
                   Layout.rightMargin: 16

                   cameraName: model.cameraName
                   timeText: model.timeText
                   selectedPath: model.path
                   exportController: model.controller
                   statusOverride: model.status === UploadProgressBar.Status.Uploading ? undefined : model.status
                   progressOverride: model.status === UploadProgressBar.Status.Uploading ? undefined : model.progress
                   previewOverride: model.preview
                   sizeOverride: model.sizeBytes

                   onRemoveRequested: {
                        if (Archive.ExportManager)
                           Archive.ExportManager.removeExport(modelIndex)
                   }
               }
           }
       }
   }
}
