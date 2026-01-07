import QtQml 2.1
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.11
import QtGraphicalEffects 1.0
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2

import iv.colors 1.0
import iv.singletonLang 1.0
import iv.controls 1.0 as C

Item {
    id: root

    implicitHeight: 48
    implicitWidth: progressBarLayout.implicitWidth
    visible: status > 0

    property var exportController
    property var progressOverride: undefined
    property var statusOverride: undefined
    property var previewOverride: undefined
    property var sizeOverride: undefined
    property int progress: progressOverride !== undefined ? progressOverride : Number(exportController && exportController.exportProgress)
    property int status: statusOverride !== undefined ? statusOverride : Number(exportController && exportController.status)
    property real exportedSizeBytes: sizeOverride !== undefined ? sizeOverride : Number(exportController && exportController.exportedSizeBytes)
    property string previewSource: previewOverride !== undefined ? previewOverride : exportController ? exportController.firstFramePreview : ""
    property string selectedPath: ""
    property string cameraName: ""
    property string timeText: ""

    property real smoothProgress: 0

    signal removeRequested()

    function formatFileSize(bytes) {
        if (!bytes || bytes <= 0)
            return ""

        var kb = bytes / 1024
        var mb = kb / 1024
        var gb = mb / 1024

        if (mb >= 1 && mb <= 999)
            return Math.round(mb).toString() + " MB"
        if (mb > 999)
            return gb.toFixed(1) + " Gb"
        return Math.max(1, Math.round(kb)).toString() + " Kb"
    }

    Behavior on smoothProgress {
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    RowLayout {
        id: progressBarLayout

        width: parent.width
        spacing: 8

        Rectangle {
            id: previewFrame
            Layout.preferredWidth: 44
            Layout.preferredHeight: 32
            radius: 8
            color: "black"
            clip: true

            Image {
                id: previewImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: root.previewSource
                asynchronous: true
                visible: previewImage.status === Image.Ready
            }
        }

        ColumnLayout {
            spacing: 2

            Text {
                text: root.cameraName
                color: IVColors.get("Colors/Text new/TxPrimaryThemed")
                font: IVColors.getFont("Label accent")
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
                Layout.fillWidth: true
            }

            Text {
                text: root.timeText
                color: IVColors.get("Colors/Text new/TxSecondaryThemed")
                font: IVColors.getFont("Subtext")
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
                Layout.fillWidth: true
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Rectangle {
            id: progressBadge

            Layout.preferredWidth: progressWidth()
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
            radius: 8
            color: IVColors.get("Colors/Background new/BgBtnSecondaryThemed")

            function progressWidth() {
                switch (root.status) {
                    case UploadProgressBar.Status.Done:
                        var contentWidth = 0
                        if (doneIcon.visible)
                            contentWidth += doneIcon.Layout.preferredWidth
                        if (sizeText.visible) {
                            if (contentWidth > 0)
                                contentWidth += badgeContent.spacing
                            contentWidth += sizeText.implicitWidth
                        }
                        return Math.max(84, contentWidth + 16)
                    case UploadProgressBar.Status.Error:
                        return 32
                    default:
                        return 67
                }
            }

            RowLayout {
                id: badgeContent
                anchors.centerIn: parent
                spacing: 4

                Item {
                    id: spinnerHolder
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 2
                    visible: root.status === UploadProgressBar.Status.Uploading && root.smoothProgress !== 100

                    Canvas {
                        id: progressCircle
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        antialiasing: true

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            ctx.clearRect(0, 0, width, height)

                            var centerX = width / 2
                            var centerY = height / 2
                            var radius = Math.min(width, height) / 2 - 2

                            var startAngle = -Math.PI / 2
                            var endAngle = startAngle + (2 * Math.PI * smoothProgress / 100)

                            ctx.beginPath()
                            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI, false)
                            ctx.strokeStyle = IVColors.get("Colors/Text new/TxContrast")
                            ctx.lineWidth = 2
                            ctx.stroke()

                            if (smoothProgress > 0 && smoothProgress < 100) {
                                ctx.beginPath()
                                ctx.moveTo(centerX, centerY)
                                ctx.arc(centerX, centerY, radius - 2, startAngle, endAngle, false)
                                ctx.lineTo(centerX, centerY)
                                ctx.closePath()
                                ctx.fillStyle = IVColors.get("Colors/Text new/TxContrast")
                                ctx.fill()
                            }
                        }
                    }
                }

                Text {
                    id: percentText
                    visible: root.status === UploadProgressBar.Status.Uploading
                    text: Math.min(100, Math.max(0, smoothProgress)).toFixed(0) + "%"
                    color: IVColors.get("Colors/Text new/TxContrast")
                    font: IVColors.getFont("Label accent")
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                C.IVImage {
                    id: doneIcon
                    name: "new_images/archive"
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    visible: root.status === UploadProgressBar.Status.Done
                    color: IVColors.get("Colors/Text new/TxAccentThemed")
                }

                Text {
                    id: sizeText
                    visible: root.status === UploadProgressBar.Status.Done &&
                             root.formatFileSize(root.exportedSizeBytes).length > 0
                    text: root.formatFileSize(root.exportedSizeBytes)
                    color: IVColors.get("Colors/Text new/TxContrast")
                    font: IVColors.getFont("Label accent")
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                C.IVImage {
                    name: "new_images/alert-triangle"
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    visible: root.status === UploadProgressBar.Status.Error
                    color: IVColors.get("Colors/Text new/TxAccentThemed")
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.status === UploadProgressBar.Status.Done && root.selectedPath
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (!enabled)
                        return
                    var url = "file:///" + root.selectedPath
                    Qt.openUrlExternally(url)
                }
            }
        }

        C.IVButtonControl {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: 8
            source: "new_images/x-close"
            visible: root.status !== UploadProgressBar.Status.Done && root.selectedPath
            type: C.IVButtonControl.Type.Tertiary
            size: C.IVButtonControl.Size.Small
            onClicked: root.removeRequested()
        }

        Item {
            Layout.preferredHeight: 32
            Layout.preferredWidth: 32
            visible: root.status === UploadProgressBar.Status.Done

            C.IVImage {
                anchors.centerIn: parent
                width: 20
                height: 20
                name: "new_images/trash-01"
                color: trashArea.containsMouse ? IVColors.get("Colors/Text new/TxAccentThemed") : IVColors.get("Colors/Text new/TxSecondaryThemed")

                MouseArea {
                    id: trashArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.removeRequested()
                    }

                }
            }
        }
    }

    onProgressChanged: smoothProgress = progress
    onSmoothProgressChanged: progressCircle.requestPaint()
    onStatusChanged: progressCircle.requestPaint()

    enum Status { Idle, Uploading, Done, Error }
}
